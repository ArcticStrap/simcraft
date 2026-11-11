# SimCraft app icon

**Motif:** A clean-room technical dynamic systems reference design matching the engineering and CADCraft members of the ArtCraft ecosystem. A closed-loop control and simulation block diagram consisting of an error-detecting Summing Junction `⊕` with negative feedback, an illuminated Continuous Integrator / State Block `[ 1/s ]` with technical port terminals, and a feedback Gain Block `[ K ]`, overlaid with a sweeping analytical 2nd-order dynamic step-response waveform and Runge–Kutta (Dormand–Prince RK45) adaptive solver evaluation nodes, set against a Cartesian coordinate drafting grid.

## Palette

| Colour | Hex | Used for |
|---|---|---|
| Ink | `#17191C` | Precision linework, block outlines, wires, and mathematical symbols |
| Paper | `#F4ECD8` | Summing junction, integrator block face, gain block, and solver stage nodes |
| Control Indigo (app colour) | `#152846` | Full-bleed engineering blueprint tile behind the diagram |
| Simulation Orange (accent) | `#F07A3A` | Dynamic step response waveform, block header, and solver evaluation markers |
| Blue Port (signal input) | `#0072BD` | Input port terminal pin, matching SimCraft Studio's input coding |
| Undercut Depth / Shadow | `#0A182B` | 3D bevel and undercut depth facets for the blocks and summing junction |
| Coordinate Grid | `#FFFFFF` (18% opacity) | Cartesian simulation drafting grid lines |
| Target Equilibrium | `#FFFFFF` (32% opacity) | Dashed steady-state convergence setpoint line |

## Geometry and style

- A 512-unit viewBox tile, rounded squircle `rx=112`, with the app colour full bleed (matching CADCraft, MatCraft, and the ArtCraft suite).
- Technical precision styling: bold, confident geometric polygons with 7 px round-joined ink borders, directional signal routing arrowheads, and closed-loop feedback topology.
- Functional iconography: representing dynamic system state simulation ($\dot{x} \to x$, $1/s$), closed-loop stability, and adaptive numerical integration ($t_k$).
- macOS renders (`simcraft-macos-512.png`) place the tile in Apple's grid (824 of 1024 px with transparent margin). Windows, Linux, and the web use the full-bleed tile.

## Files

| File | What |
|---|---|
| `simcraft.svg` | Canonical vector artwork (512x512 tile, rx=112) |
| `simcraft-small.svg` | Compact vector SVG for scalable icon themes |
| `simcraft-1024.png` | 1024 px high-resolution master render |
| `simcraft-macos-512.png` | macOS Dock/switcher icon with Apple squircle margin |
| `simcraft-256.png` | 256 px render (referenced in README.md) |
| `simcraft-64.png` | 64 px render |
| `simcraft-32.png` | 32 px render |
| `simcraft-16.png` | 16 px render |
| `simcraft.ico` | Windows resource icon (16, 20, 24, 32, 40, 48, 64, 128, 256 px) |
| `hicolor/<size>/apps/simcraft.png`, `hicolor/scalable/apps/simcraft.svg` | Linux icon theme tree |

## Regenerate

Run `packaging/icons.sh` (requires `resvg` and Python 3).
