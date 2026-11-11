# SimCraft File Format (`.simcraft`)

A `.simcraft` model file is human-readable, diff-friendly JSON designed for clean version control, branch merging, and deterministic serialization.

## Format Overview

```json
{
  "format": "simcraft",
  "version": 1,
  "comment": "Free-text description or model documentation",
  "solver": {
    "solver": "rk45",
    "dt": 0.01,
    "tstop": 10.0,
    "rtol": 0.001,
    "atol": 1e-06,
    "min_step": 0.0,
    "max_step": 0.0
  },
  "blocks": [
    {
      "path": "sine",
      "type": "sine",
      "params": {
        "frequency": 2.0,
        "amplitude": 1.0,
        "phase": 0.0,
        "bias": 0.0
      }
    },
    {
      "path": "scope",
      "type": "scope"
    }
  ],
  "wires": [
    {
      "from": "sine/1",
      "to": "scope/1"
    }
  ],
  "layout": {
    "sine": [120.0, 180.0],
    "scope": [380.0, 180.0]
  }
}
```

---

## Top-Level Schema

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `format` | string | **Yes** | Must equal `"simcraft"`. Identifies the document type. |
| `version` | integer | **Yes** | Document schema version (currently `1`). |
| `comment` | string | No | Optional free-text model description. Preserved across edits. |
| `solver` | object | No | Simulation and ODE solver configuration (defaults applied if omitted). |
| `blocks` | array | **Yes** | List of block instances in the diagram. |
| `wires` | array | **Yes** | Directed signal connections between block ports. |
| `layout` | object | No | 2D canvas coordinates for blocks in SimCraft Studio. Ignored by headless solvers. |

> [!NOTE]
> Unknown top-level keys are ignored by `simmodel::Document::parse`. This guarantees forward compatibility so newer files degrade gracefully when opened in older tool versions.

---

## Solver Configuration (`solver`)

The `solver` object defines the numerical integration method and simulation parameters:

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `solver` | string | `"rk45"` | Integration solver: `"euler"`, `"rk4"`, or `"rk45"`. |
| `dt` | number | `0.01` | Fixed step size (for Euler/RK4) or initial step estimate (for RK45). |
| `tstop` | number | `10.0` | Simulation stop time in seconds ($t_{\text{stop}} \ge 0$). |
| `rtol` | number | `1e-3` | Relative error tolerance for adaptive RK45 step adjustment. |
| `atol` | number | `1e-6` | Absolute error tolerance for adaptive RK45 step adjustment. |
| `min_step` | number | `0.0` | Minimum allowed step size ($0$ = solver chooses $10^{-12}$). |
| `max_step` | number | `0.0` | Maximum allowed step size ($0$ = solver defaults to $t_{\text{stop}}/10$). |

---

## Blocks (`blocks`)

Each entry in the `blocks` array represents an instantiated block:

```json
{
  "path": "integrator1",
  "type": "integrator",
  "params": {
    "x0": 1.0,
    "limit": false
  }
}
```

### Fields
- **`path`** *(string, required)*: Unique identifier within the model diagram. Valid paths are alphanumeric strings (e.g. `"theta"`, `"sum_err"`, `"scope1"`).
- **`type`** *(string, required)*: Registered block type in the block catalog (e.g. `"gain"`, `"integrator"`, `"relay"`, `"transfer_fcn"`).
- **`params`** *(object, optional)*: Key-value map of block parameters.

### Parameter Value Types
SimCraft parameters support four JSON primitives:
1. **Number**: Float or integer values (e.g. `"gain": 2.5`, `"time": 0.5`).
2. **String**: Symbolic configurations (e.g. `"signs": "+-"`, `"op": "<="`).
3. **Boolean**: Feature toggles (e.g. `"limit": true`).
4. **Vector / Array of Numbers**: Polynomial coefficients or matrix terms (e.g. `"num": [1.0]`, `"den": [1.0, 2.0, 1.0]`).

---

## Wires (`wires`)

Wires define the directed signal routing between output ports and input ports:

```json
{
  "from": "src_block/1",
  "to": "dst_block/2"
}
```

### Endpoint Syntax: `"path/port"`
- Wire endpoints use the format `<block_path>/<port_number>`.
- **1-based Port Indexing**: Port numbers in `.simcraft` files are 1-based (`1`, `2`, ...), matching standard modeling conventions. The internal engine maps them to 0-based indices at parse time.
- Input ports accept at most one incoming wire. Connecting a new wire to an occupied destination port replaces the previous connection.
- Output ports may branch to multiple downstream destination inputs (fan-out).

---

## Layout (`layout`)

The `layout` object maps block paths to their `[x, y]` pixel coordinates in SimCraft Studio:

```json
"layout": {
  "sine": [100.0, 150.0],
  "gain": [260.0, 150.0],
  "scope": [420.0, 150.0]
}
```

- Coordinates represent the **center point** of the block on the editor canvas.
- When a model file lacks `layout` entries (e.g. created programmatically or from CLI), SimCraft Studio automatically applies layered topological auto-layout (`auto_layout_missing`) based on signal propagation depth.
- Studio preserves layout positions deterministically when saving.
