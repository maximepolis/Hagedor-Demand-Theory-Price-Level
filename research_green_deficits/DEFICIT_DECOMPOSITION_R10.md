# The tax-timing × terminal-debt 2×2: formal specification

**Fixed before any code is written or any result inspected.** Changing a
number in this file after a run requires a separate commit, made before the
run that uses it, stating the reason.

---

## 1. Environment held constant across all four cases

| Object | Symbol | Constant across C1–C4 |
|---|---|---|
| Real green-investment path | `g_{g,t}` | identical sequence, all `t` |
| Implementation efficiency | `q_g` | identical |
| Initial nominal debt stock | `B_0` | identical |
| Announcement date and information structure | `t = 1`, unanticipated, perfect foresight thereafter | identical |
| Monetary policy | nominal growth `μ`, nominal rate `i^{ss}` | identical |
| Household parameters | `β, σ, ζ_b, χ_b, b̲, λ, ι_H, Π, e` | identical |
| Climate parameters | `δ_g, θ_g, D(·)` | identical |
| Horizon and terminal real economy | `T`, terminal steady state | identical |

Only the **tax path** and the **terminal nominal stock** differ.

---

## 2. The financing rule

Write the detrended nominal stock `B̂_t`, its real value `b_t = B̂_t / P̂_t`,
and the real program `g ≡ g_g`. The service-plus-program tax rule is

```
τ_t = r̄ · b_t + φ_t · g ,            φ_t ∈ [0,1]
```

where `φ_t` is the share of the program covered by current taxation at date
`t`. `φ_t = 1` is contemporaneous finance. The geometric phase-in used in the
manuscript is

```
φ_t = 1 − ρ_d^{\,t} ,                 ρ_d ∈ [0,1)
```

with tax half-life

```
h(ρ_d) = ln 2 / ( − ln ρ_d )   years,      h(0.61) = 1.40 ,  h(0.90) = 6.58 .
```

Terminal dilution is `κ_∞ ≡ B̂_∞ / B̂_0`.

---

## 3. The four cases

Let `ρ̄` denote the phase-in speed used in the delayed cases (baseline
`ρ̄ = 0.90`, the manuscript's deficit run) and `κ̄ > 1` the ratchet target.

### C1 — contemporaneous taxation, unchanged terminal debt

```
φ_t^{C1} = 1               for all t
κ_∞^{C1} = 1               (an output, verified, not imposed)
```

This is the balanced service-rule path already computed.

### C2 — delayed taxation, temporary debt increase, pre-specified consolidation

```
φ_t^{C2} = 1 − ρ̄^{\,t}                                    for t < T_c
φ_t^{C2} = 1 − ρ̄^{\,t} + s_t                              for t ≥ T_c
s_t      = s_0 · ς^{\,(t − T_c)} ,   ς = 2^{−1/H_c}
```

`s_0` is solved so that `κ_∞^{C2} = 1` to the tolerance in §5. **This is the
pure tax-timing case and it does not currently exist.**

Consolidation parameters, fixed now:

| Parameter | Symbol | Baseline | Meaning |
|---|---|---|---|
| Consolidation **start date** | `T_c` | **10 years** | first date the surcharge is levied |
| Surcharge **decay factor** | `ς` | `2^{−1/H_c}` | per-period persistence |
| Surcharge **half-life** | `H_c` | **10 years** | distinct symbol from `T_c` |
| **Scaling condition** | — | `κ_∞^{C2} = 1` | `s_0` solved to satisfy it |
| Terminal debt **tolerance** | `ε_κ` | **1e-8** | `\|κ_∞^{C2} − 1\| < ε_κ` |

`T_c` and `H_c` are separate symbols and separate numbers. That they share the
baseline value 10 is a coincidence of the baseline, not an identity; the
robustness grid below breaks it.

Robustness alternatives, **prepared but not run** until the baseline
accounting checks of §5 pass: `(T_c, H_c) ∈ {(5,5), (10,10), (20,20)}`, and
the off-diagonal `(10,5)` and `(10,20)` if the diagonal shows sensitivity.

### C3 — contemporaneous taxation, permanently higher terminal debt

```
φ_t^{C3} = 1 − Δ_t                       Δ_t ≥ 0, unfunded issuance
κ_∞^{C3} = κ̄                             imposed
```

`Δ_t` is a one-off issuance at `t = 1`, sized to deliver `κ̄`, with `φ_t = 1`
at every `t ≥ 2`. The tax is contemporaneous from date 2 onward, so no timing
effect is present: this isolates the ratchet.

### C4 — delayed taxation with the same ratchet as C3

```
φ_t^{C4} = 1 − ρ̄^{\,t}                   no consolidation
κ_∞^{C4} = κ̄                             matched to C3 by construction
```

This is the manuscript's current experiment, now correctly labelled.

**`κ̄` is set to the `κ_∞` that C4 produces endogenously at `ρ̄`,** then
imposed on C3. Sequencing: solve C4 first, read `κ_∞^{C4}`, set
`κ̄ := κ_∞^{C4}`, then solve C3. This makes the 2×2 balanced; the alternative
(choosing `κ̄` independently) leaves C3 − C1 measuring a different ratchet
from the one C4 contains.

---

## 4. Estimands

```
timing                          =  C2 − C1
ratchet                         =  C3 − C1
interaction                     =  C4 − C2 − C3 + C1
timing | ratchet present        =  C4 − C3
```

The fourth is reported alongside the first three: it is the timing effect
*conditional on* the permanent ratchet, and it is the object the manuscript's
current experiment is closest to.

Each is reported for: the impact log price response `d ln P̂_1`; the terminal
response `d ln P̂_∞`; the front-loading statistic `F^j_P` (per the definition
set in `R10_EXECUTION_PLAN.md` §5); the revaluation share `ν_reval`; and
welfare by wealth group.

Within each case the impact response is further decomposed into deferred-tax
relief, temporary nominal issuance, permanent nominal dilution, the
distributional precautionary response, the climate-capital response, and the
interaction. That decomposition must reconstruct the impact response to the
same tolerance as the existing exact stationary decomposition.

---

## 5. Government-budget validation identities

Every case must satisfy all of the following before any economic result is
read. These are **gates**, not diagnostics.

**(V1) Common initial stock.**
```
B_0^{Cj} = B_0        for j = 1,2,3,4        (exactly, by construction)
```

**(V2) Terminal-stock matching, within pair.**
```
| B̂_T^{C2} / B̂_T^{C1} − 1 | < ε_κ = 1e-8
| B̂_T^{C4} / B̂_T^{C3} − 1 | < ε_κ = 1e-8
```

**(V3) Terminal-stock separation, across pairs.**
```
B̂_T^{C3} / B̂_T^{C1} = κ̄ > 1     and     κ̄ is reported, not assumed
```

**(V4) Period-by-period government identity.** At every date `t` and in every
case, with `R̄ = 1 + r̄`:
```
B̂_{t+1} / P̂_t  =  R̄ · ( B̂_t / P̂_t )  +  g_{g,t}  −  τ_t
```
Residual normalized by `g_{g,t}`, required `< 1e-9` at every date.

**(V5) Present-value identity.** With the stationary discount factor along the
path,
```
b_0  =  Σ_t  m_{0,t} · ( τ_t − g_{g,t} )  +  lim_t m_{0,t} b_t
```
Residual normalized by `b_0`, required `< 1e-7`.

**(V6) Consolidation present value (C2 only).** Report, do not gate:
```
PV(surcharge) / PV(program)      and      PV(surcharge) / b_0
```
so that the size of the consolidation required to undo the ratchet is visible
rather than buried in the rule.

**(V7) Real-program identity.** `g_{g,t}` identical across cases to machine
precision; this catches an accidental nominal-vs-real slip in a rule change.

---

## 6. Order of execution

1. C1 (exists; re-verify V1, V4, V5).
2. C4 at `ρ̄ = 0.90` (exists; read `κ_∞^{C4}`, set `κ̄`).
3. C3 with `κ̄` imposed (new).
4. C2 with `s_0` solved for `κ_∞ = 1` (new; the pure-timing case).
5. Validation identities V1–V7 across all four.
6. Estimands of §4, only if V1–V7 pass.
7. Consolidation robustness grid, only if 5 and 6 pass.

**One-asset first.** The two-asset versions are blocked by the certification
gate and go to `output/quarantine/`.
