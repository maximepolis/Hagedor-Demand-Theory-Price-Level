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

### Stage A — Two-regime steady-state DTPL  *(the core new result; ~1 week)*
- **Extend** `setup_params_green.m`: add `Pi_agg` (2×2), `D0_states = [D0_C, D0_S]`,
  and a switch `pg.agg_risk`.
- **New** `src_project/solve_household_vfi_agg.m`: the recursion above over
  $(a,e,s)$. Reuses the existing choice-on-grid Bellman operator; the only
  change is the continuation $\mathbb{E}[V(a',e',s')]=\sum_{s'}\Pi^{\mathrm{agg}}_{ss'}
  (\Pi V(a',\cdot,s'))$ and the state-contingent return/tax in the budget.
- **New** `src_project/S_green_agg.m`: given the price vector $\{P\}$, returns
  $(\Sfun_C,\Sfun_S)$ and the joint invariant distribution (exact, no
  simulation — extend `compute_stationary_distribution` to carry the aggregate
  state as an outer block-Markov layer).
- **New** `src_project/solve_dtpl_aggrisk.m`: 2-D root find (or damped fixed
  point, reusing the Anderson helper from `solve_hank_dtpl_transition`) over
  $(P_C,P_S)$ so that $\Phi_C=\Phi_S=0$. Report the premium.
- **New** `main_project_aggrisk.m` + `PFig19`: the two-regime price levels, the
  safe-asset premium, and its comparative statics in $K_g$ and $D^0_S$.
- **Label:** STOCHASTIC AGGREGATE RISK (the reserved scope tag).

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
