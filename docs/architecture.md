# SimCraft Architecture

SimCraft is organized into clean, unidirectional layers. No low-level crate depends on higher-level crates, and nothing below Layer 6 depends on windowing or GUI libraries (`egui`, `winit`).

## Workspace Layering

| Layer | Crate / App | Responsibility | Dependencies |
| --- | --- | --- | --- |
| **L1** | `simcore` | Model graph kernel, flat state vectors, algebraic loop detection, fixed-step and adaptive RK45 solvers, continuous extension, zero-crossing engine. | `matcore` |
| **L2** | `simblocks` | Built-in block catalog (~25+ blocks across 8 categories), port typing, parameters validation, zero-crossing indicator functions. | `simcore`, `matplot` (for Scope traces) |
| **L2** | `simmodel` | `.simcraft` diff-friendly JSON format parser, schema validator, document builder. | `simcore`, `serde`, `serde_json` |
| **L5** | `simcraft_engine` | Command registry (`model.*`, `block.*`, `wire.*`, `sim.run`, `sim.step`), execution session, MatCraft session bridge. | `simcore`, `simblocks`, `simmodel`, `matlang` |
| **L7** | `simcraft-cli` | Headless command-line runner, syntax checker, model exporter, parameter override driver. | `simcraft_engine` |
| **L7** | `simcraft-studio` | Desktop graphical editor: block palette, bezier wiring canvas, inspector, parameter dialogs, live scope plotting dock. | `simcraft_engine`, `eframe`, `egui` |

---

## Clean-Room & Safety Guarantees

SimCraft is built under strict clean-room engineering constraints:
1. **Never use or reverse-engineer MathWorks software:** No MathWorks binaries, block libraries, icon files, help texts, or sample models are inspected or copied. Solver behavior and block semantics are implemented strictly from public textbook and peer-reviewed solver literature (Dormand & Prince 1980; Hairer, Nørsett & Wanner; Åström & Hägglund 1984).
2. **Panic-free non-test code:** Model files, control messages, and IPC requests are untrusted. Fallible operations return `Result<T, SimError>`. Non-test code forbids `panic!`, `unwrap()`, and `expect()`, enforced by workspace clippy lints (`clippy::unwrap_used = "deny"`, `clippy::expect_used = "deny"`).
3. **Capped resource allocations:** State vectors, signal dimensions, and step counts are validated against explicit limits (`MAX_STATES`, `MAX_SIGNAL_WIDTH`, `MAX_STEPS`, `MAX_ZC`).
4. **Rust native:** No hand-written JS/TS; portable across Linux, macOS, Windows, and WebAssembly.

---

## Simulation Execution Pipeline

Within each solver step at simulation time $t$:

```text
       ┌────────────────────────────────────────────────────────┐
       │ 1. Evaluate outputs in feedthrough topological order  │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │ 2. Advance discrete states for blocks with hit at t   │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │ 3. Re-evaluate outputs (held signals propagate)       │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │ 4. Log sink blocks (Scope, To Workspace)               │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │ 5. Evaluate derivatives & advance continuous states    │
       │    (Euler, RK4, or adaptive RK45 trial step)          │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │ 6. Zero-Crossing Check & Continuous Extension          │
       │    - If event detected in (t, t + h]:                  │
       │      Locate earliest t* via Hermite secant/bisection   │
       │      Clamp step to t*, trigger on_zc, re-eval outputs  │
       └────────────────────────────────────────────────────────┘
```

### Direct Feedthrough & Topological Order
A block has *direct feedthrough* if its output values at instant $t$ depend directly on its input values at instant $t$. Feedthrough blocks drive execution order:
- `simcore::Model::compile` constructs a dependency DAG over feedthrough blocks and computes a valid topological execution sequence.
- If a cycle of pure direct-feedthrough blocks exists without an intervening continuous state (such as an integrator) or discrete delay, `simcore` detects an algebraic loop and reports the cycle participants.

### Flat Continuous State Vector
Continuous states are decoupled from block instances:
- The solver owns a flat vector `x: Vec<f64>` and its derivative vector `dx: Vec<f64>`.
- Each block declares its continuous state count (`n_states`).
- When advancing stages, `simcore` passes appropriate disjoint slices of `x` and `dx` to individual blocks via `get_x`/`set_x` and `derivatives`.

---

## Zero-Crossing Detection Architecture

Hybrid systems containing nonsmooth elements (relays, saturations, switches, contact friction) generate indicator signals $z_i(t, x, u)$ with defined directions (`Rising`, `Falling`, `Either`).

1. **Indicator Evaluation:** Blocks evaluate indicator signals $z(t)$ during trial steps.
2. **Event Detection:** A sign change matching the indicator's direction `dir.crossed(z_prev, z_curr)` brackets an event within $(t, t + h]$.
3. **Continuous Extension:** The Dormand–Prince 5(4) pair is a First Same As Last (FSAL) integrator. Stage boundary values $(x_0, k_1)$ and $(x_5, k_7)$ form an exact $C^1$ cubic Hermite polynomial $x(\tau)$ across $\tau \in [t, t + h]$ without extra derivative evaluations.
4. **Root Localization:** Safeguarded Pegasus secant-bisection iteratively narrows $[t_{\text{lo}}, t_{\text{hi}}]$ until convergence ($|t_{\text{hi}} - t_{\text{lo}}| \le 10^{-8} \cdot \max(1, |t|)$).
5. **Mode Landing:** The solver steps directly to $t^*$, invokes `on_zc` on the triggering block, updates discrete modes, and re-evaluates outputs to start the subsequent interval cleanly.

---

## "Everything is a Command" Pattern

All functional interactions pass through string command IDs handled by `simcraft_engine::Session`:
- `model.load`: Load a model file into the session.
- `model.check`: Validate ports, wiring, and algebraic loops.
- `model.list`: List blocks and wires.
- `block.get` / `block.set`: Inspect and modify block parameters dynamically.
- `sim.run`: Execute full simulation run with solver options.
- `sim.step`: Single-step the solver for interactive debugging.
- `session.link` / `session.unlink`: Connect or disconnect a MatCraft evaluation context.

This pattern allows identical capabilities across the graphical Studio, the headless CLI, TCP control channels, and agent MCP servers.
