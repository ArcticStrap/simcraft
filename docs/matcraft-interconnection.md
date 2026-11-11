# The MatCraft Interconnection

SimCraft and [MatCraft](https://github.com/storytold/matcraft) are designed to operate as a tightly integrated pair — mirroring the seamless relationship between Simulink and MATLAB in scientific and industrial computing.

One linked MatCraft session acts as the model's compute and variable context.

```text
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│            SimCraft             │           │            MatCraft             │
│                                 │           │                                 │
│  ┌───────────────────────────┐  │  Traces   │  ┌───────────────────────────┐  │
│  │ Block Diagram Simulation  │──┼──────────►│  │ Global Workspace (out, var)│  │
│  │ (simcore, ODE solvers)    │  │           │  │ Linear algebra & plots    │  │
│  └───────────────────────────┘  │           │  └───────────────────────────┘  │
│               ▲                 │           │               │                 │
│               │ Commands        │           │ Parameter     │                 │
│               │ (sim.run, set)  │           │ Sweeps & sim()│                 │
│  ┌────────────┴──────────────┐  │           │               ▼                 │
│  │ Command Engine / RPC      │◄─┼───────────┼── sim('model.simcraft')         │
│  │ (simcraft_engine)         │  │           │   set_param('k', 'gain', 2.0)   │
│  └───────────────────────────┘  │           │                                 │
└─────────────────────────────────┘           └─────────────────────────────────┘
```

---

## Workspace Data Publishing Contract

When a simulation completes (`sim.run`), SimCraft exports simulation traces directly into the linked MatCraft session:

### 1. The Global Output Object (`out`)
Every simulation populates a structured variable named `out` in the MatCraft workspace:
- **`out.t`**: $N \times 1$ column vector of sampled simulation timestamps.
- **`out.y`**: $N \times W$ matrix representing the primary output trace from the first logged sink.
- **`out.<name>`**: Field for each logged Scope and To Workspace block, where `<name>` is normalized to a valid identifier (e.g. `out.theta`, `out.speed`).

### 2. To Workspace Variables
Each `to_workspace` block also publishes a dedicated top-level struct bound to its configured variable name (`var`):
- `var.t`: $N \times 1$ time vector.
- `var.y`: $N \times W$ matrix of logged signal values across time.

```matlab
% In MatCraft or the Studio embedded console:
>> out = sim('pendulum.simcraft');
>> plot(out.t, out.theta);
>> xlabel('Time (s)');
>> ylabel('Angle (rad)');
>> grid on;
```

---

## Automation via M-Scripting

SimCraft models can be automated, parameterized, and analyzed directly from M-code in MatCraft:

### Running Simulations: `sim()`
```matlab
% Run with file defaults
out = sim('relay_feedback.simcraft');

% Run with solver overrides
out = sim('relay_feedback.simcraft', 'StopTime', '5.0', 'Solver', 'rk45');
```

### Parameter Inspection and Tuning: `get_param` & `set_param`
```matlab
% Query current gain
k = get_param('pendulum/gl', 'gain');

% Update parameter before re-running
set_param('pendulum/gl', 'gain', 19.62);
out_high_g = sim('pendulum.simcraft');
```

### Parameter Sweeps
A classic workflow is running parameter variations in a loop to evaluate system dynamics:

```matlab
figure;
hold on;
for k = [0.5, 1.0, 2.0, 5.0]
    set_param('closed_loop/controller', 'gain', k);
    out = sim('closed_loop.simcraft');
    plot(out.t, out.y, 'DisplayName', sprintf('k = %.1f', k));
end
xlabel('Time (s)');
ylabel('Response');
legend('show');
grid on;
```

---

## Engine Command Interface (`simcraft_engine`)

The interconnection is built upon the unified `Session` command architecture in `crates/engine`:

| Command ID | Description | Parameters |
| --- | --- | --- |
| `model.load` | Load a `.simcraft` JSON file or text string | `{"path": "..."}` or `{"text": "..."}` |
| `model.check` | Compile model and validate port/wiring consistency | `{}` |
| `model.list` | List all instantiated blocks, types, and parameters | `{}` |
| `block.get` | Retrieve parameter values for a block | `{"path": "gain1"}` |
| `block.set` | Update parameter values on an existing block | `{"path": "gain1", "params": {"gain": 2.5}}` |
| `sim.run` | Execute simulation from $t=0$ to $t_{\text{stop}}$ | `{"solver": "rk45", "tstop": 10.0}` |
| `sim.step` | Execute interactive step-by-step simulation | `{"steps": 1}` |
| `session.link` | Attach a MatCraft workspace for trace publishing | `{}` |
| `session.unlink`| Detach the active MatCraft workspace | `{}` |

---

## Embedded MatCraft Console in SimCraft Studio

SimCraft Studio features an integrated MatCraft execution console at the bottom dock:
- Shares the live diagram session memory.
- Allows immediate inspection of workspace variables (`who`, `whos`).
- Enables immediate mathematical analysis, plotting (`matplot`), and script evaluation against active simulation results.
