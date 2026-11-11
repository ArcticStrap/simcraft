# SimCraft assets

Every non-code file in this repo is original work, OSI open source, public
domain or CC0, and is listed here. No MathWorks icons, images, artwork, fonts,
templates or sample models — ever.

| Path | Author | Source | License | Notes |
| --- | --- | --- | --- | --- |
| `assets/app-icon/simcraft.svg`, `simcraft-small.svg`, `simcraft-*.png`, `simcraft.ico`, `hicolor/` | ArtCraft contributors | generated vector artwork (closed-loop block diagram with continuous integrator 1/s, summing junction, gain block K, 2nd-order dynamic step response wave, and adaptive Dormand–Prince RK45 solver nodes on blueprint coordinate grid, matching CADCraft / ArtCraft suite) | MIT OR Apache-2.0 | Original art; regenerate with `packaging/icons.sh`, never copied. |
| `examples/pendulum.simcraft` | SimCraft contributors | original linearized pendulum model with continuous integrator state blocks | MIT OR Apache-2.0 | Canonical demonstration and test model. |
| `examples/relay_feedback.simcraft` | SimCraft contributors | original Åström–Hägglund relay feedback model on plant G(s) = 1/(s+1)^3 demonstrating limit-cycle oscillation with zero-crossing detection | MIT OR Apache-2.0 | Canonical nonlinear auto-tuning demonstration model. |
| `assets/screenshots/studio_relay_feedback.png`, `assets/screenshots/studio_pendulum.png` | SimCraft contributors | native application screenshots captured directly from SimCraft Studio | MIT OR Apache-2.0 | Documentation screenshots; regenerate with `packaging/screenshots.sh`. |
