# SimCraft Block Library

The `simblocks` crate provides standard dynamic system building blocks. Every block implements the `simcore::Block` trait.

---

## 1. Sources

### `constant`
Generates a constant real value or vector.
- **Inputs**: None | **Outputs**: 1
- **Parameters**:
  - `value`: Number or array (default: `1.0`)
- **Direct Feedthrough**: No

### `step`
Generates a step function transition at a specified time.
- **Inputs**: None | **Outputs**: 1
- **Parameters**:
  - `time`: Step transition instant $t_s$ (default: `1.0`)
  - `before`: Value for $t < t_s$ (default: `0.0`)
  - `after`: Value for $t \ge t_s$ (default: `1.0`)
- **Direct Feedthrough**: No

### `sine`
Evaluates a sinusoidal wave $y(t) = A \sin(\omega t + \phi) + b$.
- **Inputs**: None | **Outputs**: 1
- **Parameters**:
  - `amplitude`: Amplitude $A$ (default: `1.0`)
  - `frequency`: Angular frequency $\omega$ in rad/s (default: `1.0`)
  - `phase`: Phase offset $\phi$ in rad (default: `0.0`)
  - `bias`: DC bias $b$ (default: `0.0`)
- **Direct Feedthrough**: No

### `ramp`
Generates a linearly increasing signal $y(t) = \text{slope} \cdot (t - t_{\text{start}}) + y_0$ for $t \ge t_{\text{start}}$.
- **Inputs**: None | **Outputs**: 1
- **Parameters**:
  - `slope`: Rate of change (default: `1.0`)
  - `start_time`: Activation instant $t_{\text{start}}$ (default: `0.0`)
  - `initial`: Offset value $y_0$ (default: `0.0`)
- **Direct Feedthrough**: No

### `clock`
Outputs current simulation time $y(t) = t$.
- **Inputs**: None | **Outputs**: 1
- **Parameters**: None
- **Direct Feedthrough**: No

---

## 2. Sinks

### `scope`
Records streaming signal traces during simulation for visualization in Studio or MatCraft figures.
- **Inputs**: 1 | **Outputs**: None
- **Direct Feedthrough**: No (records in `Block::log` hook)

### `to_workspace`
Publishes logged signals into the linked MatCraft session as a structured variable.
- **Inputs**: 1 | **Outputs**: None
- **Parameters**:
  - `var`: Name of the variable in the workspace (default: `"simout"`)
- **Direct Feedthrough**: No

---

## 3. Math & Discontinuities

### `gain`
Multiplies input by scalar or elementwise vector gain $y = K \cdot u$.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `gain`: Scalar or numeric vector $K$ (default: `1.0`)
- **Direct Feedthrough**: Yes

### `sum`
Sums and subtracts inputs according to a string of signs (e.g. `"+-"`, `"++-"`).
- **Inputs**: Variable (matching length of `signs`) | **Outputs**: 1
- **Parameters**:
  - `signs`: String of `+` and `-` characters (default: `"++"`)
- **Direct Feedthrough**: Yes

### `product`
Multiplies or divides inputs elementwise according to an operations string (e.g. `"*"` or `"*/"`).
- **Inputs**: Variable (matching length of `ops`) | **Outputs**: 1
- **Parameters**:
  - `ops`: String of `*` and `/` characters (default: `"**"`)
- **Direct Feedthrough**: Yes

### `abs`
Outputs elementwise absolute value $y = |u|$.
- **Inputs**: 1 | **Outputs**: 1
- **Direct Feedthrough**: Yes

### `saturation`
Clamps input between lower and upper bounds: $y = \operatorname{clamp}(u, \text{lower}, \text{upper})$.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `lower`: Lower saturation bound (default: `-0.5`)
  - `upper`: Upper saturation bound (default: `0.5`)
- **Direct Feedthrough**: Yes

### `dead_zone`
Provides zero output within $[\text{lower}, \text{upper}]$; outside, outputs distance from boundary.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `lower`: Lower dead band boundary (default: `-0.5`)
  - `upper`: Upper dead band boundary (default: `0.5`)
- **Direct Feedthrough**: Yes

### `relay`
Hysteresis switch with directional zero-crossing detection.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `on_switch` (or `on_switch_value`): Threshold to switch ON (default: `1.0`)
  - `off_switch` (or `off_switch_value`): Threshold to switch OFF (default: `-1.0`, must be $\le \text{on\_switch}$)
  - `on_output` (or `on_output_value`): Output value when ON (default: `1.0`)
  - `off_output` (or `off_output_value`): Output value when OFF (default: `0.0`)
  - `initial_output`: Initial state determination when $u(0)$ lies in the hysteresis band (default: `off_output`)
- **Direct Feedthrough**: Yes
- **Zero Crossings**: 1 per signal channel. Direction dynamically tracks state (`Rising` when OFF, `Falling` when ON).

### `switch`
Selects between input 1 and input 3 based on whether control input 2 meets criteria against `threshold`.
- **Inputs**: 3 (`u1`: data 1, `u2`: control, `u3`: data 2) | **Outputs**: 1
- **Parameters**:
  - `threshold`: Threshold value (default: `0.0`)
  - `criteria`: One of `"u2>=threshold"`, `"u2>threshold"`, `"u2~=0"` (default: `"u2>=threshold"`)
- **Direct Feedthrough**: Yes

---

## 4. Logic & Relational

### `relational`
Performs elementwise comparison: $y = u_1 \operatorname{op} u_2$.
- **Inputs**: 2 | **Outputs**: 1 (Bool)
- **Parameters**:
  - `op`: One of `"=="`, `"~="`, `"<"`, `"<="`, `">"`, `">="` (default: `"<="`)
- **Direct Feedthrough**: Yes

### `logical_operator`
Applies boolean logic operations elementwise across inputs.
- **Inputs**: Variable (controlled by `inputs` param) | **Outputs**: 1 (Bool)
- **Parameters**:
  - `op`: One of `"and"`, `"or"`, `"xor"`, `"nand"`, `"nor"`, `"not"` (default: `"and"`)
  - `inputs`: Number of input ports (default: `2.0`; forced to `1.0` for `"not"`)
- **Direct Feedthrough**: Yes

---

## 5. Continuous Systems

### `integrator`
Calculates continuous time integral $x(t) = x_0 + \int_0^t u(\tau) \, d\tau$.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `x0`: Initial state value (scalar or vector matching input width, default: `0.0`)
- **States**: Continuous ($n = \text{width}$)
- **Direct Feedthrough**: No ($y(t) = x(t)$ depends on current state, not feedthrough input)

### `derivative`
Approximates continuous time derivative $\frac{du}{dt}$ via backward difference: $\frac{u(t) - u(t_{\text{prev}})}{\Delta t}$.
- **Inputs**: 1 | **Outputs**: 1
- **Direct Feedthrough**: Yes

### `transfer_fcn`
Single-Input Single-Output (SISO) transfer function in controllable canonical state-space form:
$$G(s) = \frac{\text{num}(s)}{\text{den}(s)} = \frac{b_0 s^m + b_1 s^{m-1} + \dots + b_m}{a_0 s^n + a_1 s^{n-1} + \dots + a_n}$$
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `num`: Numerator polynomial coefficients in descending powers of $s$ (default: `[1.0]`)
  - `den`: Denominator polynomial coefficients in descending powers of $s$ (required, leading coeff $a_0 \ne 0$)
- **States**: Continuous ($n = \operatorname{deg}(\text{den})$)
- **Direct Feedthrough**: Yes if $\operatorname{deg}(\text{num}) = \operatorname{deg}(\text{den})$; No if strictly proper ($\operatorname{deg}(\text{num}) < \operatorname{deg}(\text{den})$)

### `pid`
Parallel PID controller with derivative low-pass filter:
$$u(t) = K_p e(t) + K_i \int_0^t e(\tau) \, d\tau + K_d \frac{N}{1 + N \frac{1}{s}} e(t)$$
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `kp`: Proportional gain $K_p$ (default: `1.0`)
  - `ki`: Integral gain $K_i$ (default: `0.0`)
  - `kd`: Derivative gain $K_d$ (default: `0.0`)
  - `filter_coefficient`: Filter divisor $N$ (default: `100.0`)
- **States**: Continuous (up to 2: integrator state and derivative filter state)
- **Direct Feedthrough**: Yes

### `transport_delay`
Delays continuous signal by fixed time $T_d$: $y(t) = u(t - T_d)$.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `delay`: Time delay $T_d > 0$ (default: `1.0`)
  - `initial`: Output value for $t < T_d$ (default: `0.0`)
- **Direct Feedthrough**: No

---

## 6. Discrete Systems

### `unit_delay`
Delays discrete signal by one sample period $T_s$: $y[k] = u[k-1]$.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `sample_time`: Sample period $T_s > 0$ (default: `1.0`)
  - `x0`: Initial state value (default: `0.0`)
- **Sample Time**: Discrete($T_s$)
- **Direct Feedthrough**: No

### `zero_order_hold`
Samples and holds continuous input at fixed rate $T_s$: $y(t) = u(k T_s)$ for $t \in [k T_s, (k+1) T_s)$.
- **Inputs**: 1 | **Outputs**: 1
- **Parameters**:
  - `sample_time`: Sample period $T_s > 0$ (default: `1.0`)
- **Sample Time**: Discrete($T_s$)
- **Direct Feedthrough**: No

---

## 7. Routing

### `mux`
Combines multiple scalar or vector inputs into a single composite vector signal.
- **Inputs**: Variable (controlled by `inputs` parameter, default: `2`)
- **Outputs**: 1 (vector width = $\sum w_i$)
- **Direct Feedthrough**: Yes

### `demux`
Splits a composite vector signal into multiple outputs.
- **Inputs**: 1 | **Outputs**: Variable (controlled by `outputs` parameter, default: `2`)
- **Direct Feedthrough**: Yes
