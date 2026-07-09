# Aggregate climate risk: an implementable extension plan

**Goal.** Add *aggregate* climate uncertainty to the DTPL economy so that the
nominal government bond is a genuinely *safe* asset held against a systematic
risk — closing the standard objection ("no aggregate uncertainty anywhere")
and deepening the paper's central object (climate-state-dependent demand for
the *safe* nominal asset). This is the single highest-payoff extension the
Dynare heterogeneity framework and our existing MATLAB machinery both
support well; it does **not** require the endogenous liquid/illiquid spread
that the workshop's own financial-intermediary example shows to be
numerically degenerate (see `dynare/FRAMEWORK_COMPLIANCE.md`).

**Why it fits the paper.** Today every quantitative result is a *deterministic*
steady-state or a *perfect-foresight* transition. The safe-asset language
("precautionary demand for nominal safe assets") is therefore metaphorical:
with no aggregate risk, the bond is riskless in real terms too. Aggregate
climate risk makes the nominal bond's *real* payoff state-contingent
($B/P_{s'}$ depends on next period's climate state) while its *nominal* payoff
is fixed — i.e. it is nominally safe, really risky, exactly the asset the DTPL
is about. Green investment that lowers the severity or likelihood of the bad
climate state then reduces a *systematic* risk, which is a new channel on top
of the level (damage-dividend) and tax channels.

---

## The object

Two recurrent aggregate climate states $s\in\{C,S\}$ (Calm / Severe), Markov
matrix $\Pi^{\mathrm{agg}}$ with a small entry probability into $S$ (climate
tipping / disaster, calibrated to the tail of the damage distribution). In
state $s$ the no-abatement damage level is $D^0_s$ (with $D^0_S \gg D^0_C$);
the green program maps to a state-dependent damage $D_s(K_g)$ through the
existing climate block. Markets are incomplete: households hold only the
one-period nominal bond, whose real value next period is $B/P_{s'}$.

**Household problem** (adds the aggregate state to the existing
`solve_household_vfi` recursion):
$$
V(a,e,s)=\max_{a'\ge -\bar a}\ u(c)+\beta\,\mathbb{E}\big[V(a',e',s')\mid e,s\big],
\qquad
c+a'=(1+r_{s})\,a+y(e;D_s)-\tau_s,
$$
where the realized real return entering state $s$ from state $s_-$ is
$1+r_{s_-\to s}=(1+i)\,P_{s_-}/P_s$ (state-contingent inflation), and the
expectation runs over both the idiosyncratic chain $\Pi$ and the aggregate
chain $\Pi^{\mathrm{agg}}$.

**Equilibrium** (the DTPL, now a vector fixed point): a price in each state
$(P_C,P_S)$ such that the asset market clears state by state,
$$
\Phi_s(P_C,P_S)\equiv \Sfun_s\big(\{P\};\,\tau_s,D_s\big)-\frac{B}{P_s}=0,
\qquad s\in\{C,S\},
$$
with $\Sfun_s$ the stationary asset demand of households *currently in state
$s$*, computed on the joint invariant distribution over $(a,e,s)$. Two
equations, two unknown prices.

**New reported objects.**
1. The **safe-asset premium**: the wedge between the nominal bond's
   state-contingent real return and the (shadow) return on a hypothetical
   state-contingent claim — the compensation households require to hold a
   nominally-safe / really-risky asset against climate risk.
2. **Green investment as aggregate-risk reduction**: $\partial(\text{premium})/
   \partial K_g<0$ — a channel absent from the deterministic model.
3. The self-financing decomposition gains a term:
   $\nu=\nu_{\mathrm{reval}}+\nu_{\mathrm{dam}}+\nu_{\mathrm{aggrisk}}$, the
   last being the fiscal value of the compressed risk premium.

---

## Stages (each self-contained, each a commit)

### Stage A — Two-regime steady-state DTPL  *(the core new result)*  **IMPLEMENTED 2026-07-09; run pending on the user machine**
- **Done** `setup_params_green.m`: `pg.Pi_agg` (2×2), `pg.agg.D_states`
  `=[D0_C,D0_S]`, `pg.agg.green_cut`.
- **Done** `src_project/solve_household_vfi_agg.m`: the recursion over
  $(a,e,s)$ with the state-contingent nominal-bond return
  $1+r(s,s')=(1+\bar r)P_s/P_{s'}$; the continuation is evaluated at the
  return-scaled savings $(1+r(s,s'))a'$ and LINEARLY INTERPOLATED (the
  state-contingent return is intrinsic to a nominal asset — it cannot be
  removed by a change of variables, so the deterministic on-grid trick does
  not apply here).
- **Done** `src_project/stat_dist_agg.m`: exact joint invariant distribution
  over $(a,e,s)$ via a return-scaled lottery (no simulation).
- **Done** `src_project/solve_dtpl_aggrisk.m`: the damped fixed point over
  $(P_C,P_S)$ so $S_s=B/P_s$ in every state; reports the price dispersion,
  the disaster real return, the ergodic expected real return, and the
  climate-risk premium.
- **Done** `main_project_aggrisk.m` + `PFig19` + `aggrisk_summary.txt`: the
  two-regime price levels and the green comparative static (the same climate
  block used elsewhere: a green program builds $K_g=g_g/\delta_g$ and lowers
  $D_s=D^0_s e^{-\theta_g K_g}$ in both states, more in the high-damage Severe
  state, compressing the gap).
- **Label:** STOCHASTIC AGGREGATE RISK.
- **Verified (Python prototype, before shipping the MATLAB):** the two-price
  fixed point converges; at the calibrated rate the baseline bond earns
  $+2.0\%$ in Calm but loses $\approx 24.5\%$ in the Severe state (price
  dispersion $35\%$), and a $\sim\!2\%$-of-income green program cuts the
  dispersion to $\approx 18\%$ and the disaster loss to $\approx 14\%$ —
  green investment compresses the systematic climate risk the safe asset
  carries. The MATLAB run will confirm these on the project calibration.

### Stage B — Decomposition + welfare under aggregate risk  *(~3 days)*
- Add $\nu_{\mathrm{aggrisk}}$ to `decompose_safe_asset_channel.m` (a fourth GE
  counterfactual: risk-premium held fixed vs. endogenous).
- Extend `welfare_groups_extended.m` to price the reduction in aggregate
  climate risk (CE gains now include an insurance component); report who
  values the safe asset most (the constrained / high-MPC / bottom-wealth
  groups, as intuition predicts).

### Stage C — Stochastic transition  *(revision-round; weeks)*
- The full path where $s_t$ evolves stochastically. Two feasible routes:
  (i) a global solve on a coarse $(a,e,s)$ grid with the existing exact
  distribution; (ii) sequence-space-with-aggregate-risk (Auclert et al.
  2021 second-moment machinery — the `extensions.pdf` lecture shows the
  aggregate-only Jacobian and second moments read straight off `dr.G`).
  Route (i) is the surer first pass. This stage is explicitly flagged as the
  hard, later piece; Stages A–B already deliver a reportable new result.

---

## Calibration discipline (no fabrication)
- $\Pi^{\mathrm{agg}}$: entry probability into $S$ from the tail frequency of
  the Bilal–Känzig high-damage estimates already cited (the paper's "high"
  column, $D_0=0.20$, becomes $D^0_S$); persistence from climate-tipping
  duration estimates — cited, or reported as a sweep, never invented.
- Everything else inherits the calibrated pass ($\beta^*$, program scale,
  $\mu$, $i^{ss}$). $D^0_C$ = the medium column ($0.06$).

## What Stage A buys the paper, concretely
A new headline: *green public investment lowers a systematic climate risk, and
the nominal safe asset prices that reduction* — with the self-financing share
gaining an aggregate-risk term and the "safe asset" language finally literal.
It answers the most predictable top-5 referee objection ("no aggregate
uncertainty") with a computed result rather than a promise, and it is the
natural companion to the deterministic decomposition (Section on the
safe-asset channel) and the nonlinear transition (the dynamic centerpiece).
