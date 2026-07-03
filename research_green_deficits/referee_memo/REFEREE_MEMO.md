# Referee-response memo (pre-emptive)

*Ten anticipated top-journal objections, each with (a) the honest current
state, (b) the response available now, and (c) the response after the
roadmap upgrade. Statuses reference MODEL_STATUS.md.*

**R1. "This is only steady state."**
(a) True: every quantitative result to date is a stationary-equilibrium
result, labeled as such throughout.
(b) Steady-state analysis is where the DTPL disciplines the price level
without stability selection; the two steady states of the multiplicity
theorem are the boundary conditions any transition analysis needs.
(c) Roadmap Q10: RANK-NK transition skeleton (`dynare/green_rank_nk.mod`,
PARTIALLY IMPLEMENTED) → HANK sequence-space transitions (NOT YET
IMPLEMENTED) with paths for debt, P, inflation, Kg, emissions, damages,
consumption, taxes, welfare.

**R2. "The climate calibration is arbitrary."**
(a) PARTIALLY CLOSED by the executed calibrated pass: beta is now calibrated
to debt/GDP = 1.10 (beta* = 0.9296), the program to 2% of income, and the
damage level takes three externally disciplined values (DICE 0.02 /
DJO-BHM 0.06 / Bilal-Känzig 0.20). The headline is stated as a conditional
across those columns (nu = 0.15 / 0.56 / 2.01), never at a single point.
(b) Still illustrative and reported as sweeps: theta_g (awaiting the
IEA abatement-cost mapping), phi_D, psi, and the (i, mu) anchors.
(c) Remaining plan: theta_g from marginal-abatement-cost curves; psi from
Känzig's incidence estimates; (rho, sig_eps) to wealth moments.

**R3. "Lump-sum taxes make the fiscal result mechanical."**
(a) Correct concern; lump-sum is the transparent benchmark and is labeled a
benchmark, not a result.
(b) Two findings already survive it: the revaluation-sign reversal operates
through asset demand, not the tax instrument; and the feasibility bound
(fiscal-space collapse) would only tighten with distortionary taxes.
(c) Roadmap: distortionary labor tax + carbon tax financing regimes
(NOT YET IMPLEMENTED); Barrage (2020) is the template.

**R4. "Multiplicity is not quantitatively credible."**
(a) Agreed — and the benchmark honestly does NOT generate it (psi=0,
theta_g ≤ 2.5: unique everywhere; measured min eps_S ≈ −0.4). The first
extended run additionally shows that at mu=0.02 strong incidence destroys
existence rather than producing two equilibria.
(b) Multiplicity is stated as a sufficient-condition theorem with the
measured elasticity diagnostic, and is NOT the central quantitative claim;
the central quantitative claims are the decomposition and the sign reversal.
(c) The (psi, Gg) frontier at the accommodative stance maps where (if
anywhere) eps_S < −1; if the calibrated region is empty, the paper demotes
multiplicity to a theoretical extension explicitly.

**R5. "This is just Hagedorn plus climate."**
(a/b) The climate block *changes the mechanism*, not the decoration: (i) the
denomination of a spending line becomes a determinacy instrument (his
nominal-rule uniqueness can fail; indexation repairs it); (ii) the
revaluation channel's sign flips through climate-driven asset demand; (iii)
equilibrium existence itself depends on the incidence of damages
(fiscal-space collapse). None of these statements can be made in his model.

**R6. "This is just Angeletos–Lian–Wolf plus green spending."**
(a/b) Their channel is nominal-rigidity booms plus inflationary erosion of
debt; our benchmark delivers the OPPOSITE sign of the nominal channel
(disinflation, bondholder windfall) through a mechanism absent from their
economy: precautionary demand for safe nominal assets responding to avoided
damages and taxes. The two mechanisms are empirically distinguishable (E3:
bond-price response to green-program announcements).

**R7. "Green spending is not carbon policy."**
(a) PARTIALLY CLOSED: `main_project_regimes.m` (U4) compares deficit,
carbon-levy, rebate, and mixed financing of the same real program at the
calibrated medium column, with identical aggregate budgets so differences
are pure incidence + price level.
(b) Honest scope stated in the paper: in the endowment economy the levy has
no Pigouvian abatement margin (abatement is public); the emissions-price
margin belongs to the production extension (U8), and the paper says so
rather than overclaiming.
(c) Remaining: distortionary labor tax with an hours margin (Barrage
template) and the two-sector Pigouvian comparison (U8).

**R8. "No empirical discipline."**
(a) Current: E1 implemented (34-country anchor regression, HC1, Wald test of
slope 1); E2 specified with schema, data absent (never fabricated); E3
designed.
(c) Roadmap: sovereign-yield validation (BIS-style), Känzig-shock incidence
validation, green-investment-to-emissions discipline.

**R9. "The model overstates inflation's ability to finance climate
investment."**
(a/b) The benchmark finds the opposite: the revaluation term is NEGATIVE
(−0.24), i.e. the price level moves against the fisc; and the optimal
accommodation exercise reports the limits (welfare falls beyond mu=0.045; no
equilibrium exists at mu=0.015). Single-period nominal debt currently
maximizes the revaluation channel, so adding maturity/indexed debt (roadmap)
can only weaken a channel we already find weak-to-negative — reinforcing,
not undermining, the headline.

**R10. "The welfare result is distributionally opaque."**
(a) Current: aggregate utilitarian W, asset/income Ginis, bondholder levy.
(c) Roadmap: consumption-equivalent welfare by wealth/income quintile
(distribution and value function already stored; small addition), energy- and
sector-exposure groups after the corresponding blocks exist.
