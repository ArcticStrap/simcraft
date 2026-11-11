# SimCraft Numerical Solvers & Event Handling

SimCraft provides both fixed-step and adaptive numerical Ordinary Differential Equation (ODE) integrators, coupled with continuous extension dense output and zero-crossing event localization.

---

## 1. Solver Overview

| Solver | Kind | Order | Description | Best Suited For |
| --- | --- | --- | --- | --- |
| `euler` | Fixed-step | 1st | Forward Euler integration with constant step `dt`. | Simple discrete testing, education. |
| `rk4` | Fixed-step | 4th | Classical Runge–Kutta 4-stage method. | Real-time simulation with deterministic execution budget. |
| `rk45` | Variable-step | 5(4) | Dormand–Prince adaptive integrator with error control and dense output. | General continuous and hybrid simulation, non-stiff systems. |

Solver settings are configured in the model's `solver` object or overridden via `sim.run`:
```json
{
  "solver": "rk45",
  "dt": 0.01,
  "tstop": 25.0,
  "rtol": 1e-6,
  "atol": 1e-8,
  "min_step": 0.0,
  "max_step": 0.0
}
```

---

## 2. Fixed-Step Solvers

### Forward Euler (`euler`)
Advances continuous states along the derivative at the beginning of the step:
$$x(t + h) = x(t) + h \cdot f(t, x(t), u(t))$$

### Classical Runge–Kutta 4 (`rk4`)
Computes four derivative evaluations per step:
$$\begin{aligned}
k_1 &= f(t, x_0) \\
k_2 &= f(t + \tfrac{1}{2}h, x_0 + \tfrac{1}{2}h k_1) \\
k_3 &= f(t + \tfrac{1}{2}h, x_0 + \tfrac{1}{2}h k_2) \\
k_4 &= f(t + h, x_0 + h k_3) \\
x(t + h) &= x_0 + \frac{h}{6} (k_1 + 2k_2 + 2k_3 + k_4)
\end{aligned}$$

---

## 3. Adaptive Dormand–Prince 5(4) (`rk45`)

SimCraft implements the classic Dormand–Prince 5(4) pair (Dormand & Prince 1980; Hairer, Nørsett & Wanner, *Solving Ordinary Differential Equations I*, §II.4).

### Butcher Tableau & FSAL
The integrator computes 7 stages $k_1, \dots, k_7$. It is First Same As Last (FSAL): the 7th stage $k_7 = f(t+h, x_5)$ evaluates the derivative at the end of the accepted step, which becomes $k_1$ of the subsequent step, saving one stage evaluation per step.

### Local Error Estimation
The local truncation error is estimated by comparing the 5th-order solution $x_5$ with the embedded 4th-order solution $x_4$:
$$e_i = x_{5,i} - x_{4,i}$$
The scaled error metric is computed as the root-mean-square norm:
$$\text{err} = \sqrt{\frac{1}{n} \sum_{i=1}^n \left( \frac{x_{5,i} - x_{4,i}}{\text{atol} + \text{rtol} \cdot \max(|x_{0,i}|, |x_{5,i}|)} \right)^2}$$

### Step Size Controller
A trial step is accepted when $\text{err} \le 1.0$. The step size controller adjusts subsequent step proposals:
$$h_{\text{new}} = h \cdot \operatorname{clamp}\left(0.9 \cdot \text{err}^{-1/5}, \, 0.2, \, 10.0\right)$$
If a trial step is rejected ($\text{err} > 1.0$), $h$ is reduced and the step is retried. If $h$ shrinks below `min_step` ($h_{\text{min}} = \max(\text{min\_step}, 16 \epsilon_{\text{mach}} t)$), simulation errors rather than hanging.

### Boundary Clamping
Trial step sizes $h$ are clamped so the solver lands precisely on:
1. Pending discrete sample hits $k T_s$.
2. Simulation stop time $t_{\text{stop}}$.

---

## 4. Continuous Extension (Dense Output)

During variable-step integration, events and zero crossings frequently occur between the discrete mesh points $[t, t + h]$. Evaluating roots requires evaluating states at arbitrary $\tau \in [t, t + h]$ without running additional solver stages.

SimCraft builds a $C^1$ cubic Hermite continuous extension polynomial $x(\tau)$ using the boundary positions and derivatives from the FSAL stages:
- At $s = 0$ ($\tau = t$): $x = x_0$, $x' = k_1$
- At $s = 1$ ($\tau = t + h$): $x = x_{\text{new}}$, $x' = k_7$

For normalized $s = \frac{\tau - t}{h} \in [0, 1]$:
$$\begin{aligned}
h_1(s) &= 1 - 3s^2 + 2s^3 \\
h_2(s) &= 3s^2 - 2s^3 \\
h_3(s) &= h (s - 2s^2 + s3) \\
h_4(s) &= h (s^3 - s^2) \\
x(\tau) &= h_1(s) x_0 + h_2(s) x_{\text{new}} + h_3(s) k_1 + h_4(s) k_7
\end{aligned}$$

---

## 5. Zero-Crossing Detection & Event Localization

Nonsmooth blocks declare indicator signals $z(t, x, u)$ and trigger directions:
- `ZcDirection::Rising`: Triggers when $z_{\text{prev}} < 0$ and $z_{\text{curr}} \ge 0$.
- `ZcDirection::Falling`: Triggers when $z_{\text{prev}} > 0$ and $z_{\text{curr}} \le 0$.
- `ZcDirection::Either`: Triggers on any sign crossing.

### Localization Algorithm
When an accepted RK45 step detects sign change on one or more indicators:
1. **Bracket Initialization:** For each active crossing signal, $[t_{\text{lo}}, t_{\text{hi}}] = [t, t + h]$ with values $z_{\text{lo}}, z_{\text{hi}}$.
2. **Safeguarded Secant Bisection (Pegasus method):** Interpolate root instant $\tau^* = t_{\text{lo}} - z_{\text{lo}} \frac{t_{\text{hi}} - t_{\text{lo}}}{z_{\text{hi}} - z_{\text{lo}}}$. If $\tau^*$ lies too close to the bracket bounds ($< 10\%$ of span) or fails to be finite, bisection $\tau^* = \frac{1}{2}(t_{\text{lo}} + t_{\text{hi}})$ is used.
3. **State Evaluation:** Compute $x(\tau^*)$ via cubic Hermite continuous extension.
4. **Indicator Evaluation:** Re-evaluate outputs and indicator signals at $(\tau^*, x(\tau^*))$. Update the bracket.
5. **Convergence:** Iteration terminates when $|t_{\text{hi}} - t_{\text{lo}}| \le 10^{-8} \max(1, |t|)$ or $|z| < 10^{-12}$.
6. **Multi-Event Ordering:** If multiple zero crossings occur in the same step, the earliest event instant $t^* = \min(t_i^*)$ wins.

### Mode Switching & Chattering Prevention
Once the earliest root $t^*$ is localized:
1. The solver snaps state and time to $t^*$: $t \leftarrow t^*$, $x \leftarrow x(t^*)$.
2. Dispatches `Block::on_zc(t^*, x, u, zc_idx)` to the owning block.
3. The block flips internal discrete mode flags (e.g. `Relay::is_on`) and updates indicator directions (e.g. from `Rising` to `Falling`).
4. Re-evaluates outputs at $t^*$ so downstream blocks immediately observe the post-event state.
5. `self.zc_prev` is refreshed with the new post-mode-switch indicator values, preventing phantom re-triggers on the immediate subsequent step.
6. A minimum forward progress bound $\Delta t_{\text{min}} = \max(\text{time\_tol}, 10^{-12})$ prevents infinite Zeno chattering at a single instant.
