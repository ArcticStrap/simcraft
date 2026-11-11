# SimCraft Documentation

SimCraft is an open-source, clean-room, Rust-native block-diagram modeling and simulation environment — the Simulink-class member of the ArtCraft family, interconnected with MatCraft.

## Documentation Index

| Document | Description |
| --- | --- |
| [`architecture.md`](architecture.md) | System architecture, crate layering (L1–L7), execution pipeline, algebraic loop detection, and safety guarantees. |
| [`blocks.md`](blocks.md) | Standard block library catalog: parameters, input/output port specifications, and mathematical definitions. |
| [`solvers.md`](solvers.md) | ODE solvers (Euler, RK4, adaptive Dormand–Prince RK45), continuous extension, zero-crossing detection, and event localization. |
| [`file-format.md`](file-format.md) | `.simcraft` JSON format specification, block/wire topology schema, and diagram layout metadata. |
| [`matcraft-interconnection.md`](matcraft-interconnection.md) | MatCraft integration, M-code simulation automation (`sim`, `set_param`, `get_param`), and workspace data exchange. |
| [`studio.md`](studio.md) | SimCraft Studio graphical editor guide: canvas gestures, wiring, parameter inspection, and live scopes. |

## Quick Reference

- **Run CLI simulation**: `cargo run -p simcraft-cli -- run examples/pendulum.simcraft`
- **Launch Studio editor**: `cargo run --bin simcraft-studio -- examples/relay_feedback.simcraft`
- **Capture documentation screenshots**: `./packaging/screenshots.sh`
- **Run quality gates**: `cargo fmt --check && cargo clippy --workspace -- -D warnings && cargo test --workspace`
