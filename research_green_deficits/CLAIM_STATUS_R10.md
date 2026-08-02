# Claim-status register, round 10

**Binding rule.** Every sentence in the abstract, introduction and conclusion
must map to exactly one row of this register. A sentence that cannot be mapped
is either unsupported or the register is incomplete; both are defects.

**On "provisional".** The eight codes below are the only permitted *statuses*.
"Provisional" is a narrative qualifier attached to a claim's wording, not a
ninth code: a provisional claim still carries QV, WP or CS per leg.

**Classification vocabulary** (the only permitted values):

| Code | Meaning |
|---|---|
| **PP** | proved from primitives |
| **NI** | numerical identity or decomposition (exact, verified by reconstruction) |
| **QV** | quantitatively validated (passes the numerical acceptance protocol) |
| **RO** | robust ordering (sign of a contrast, stable across structures) |
| **CS** | calibration-dependent sign (level sign, conditional on joint assumptions) |
| **IE** | illustrative extension (no external discipline, or a diagnostic) |
| **CU** | currently unsupported |
| **WP** | withdrawn pending validation |

**Status of the evidence behind this register.** No number was recomputed for
it. Numerical statuses are read off the diagnostic runs recorded in this
session, all of which were executed on the **FAST debug grid** (nb=30, nk=17),
not the benchmark grid (nb=60, nk=34). No two-asset quantity has yet been
measured under the round-10 acceptance protocol. Nothing here may be cited as
certified.

---

## Register

Rows 17–19 of the first draft were superseded by 16a–16d; the numbering is not
reused, so that a citation of "row 18" cannot silently resolve to a different
claim.

| # | Claim | Status | Basis, and what would change it |
|---|---|---|---|
| 1 | Existence of a stationary equilibrium with a demand-determined price level | **PP** | Analytical. Existence failure at low `μ` is reported by the solver rather than smoothed, which is the correct behaviour. |
| 2 | Determinacy condition / uniqueness of the nominal anchor | **PP** | Analytical, with the elasticity margin in the denominator of the incidence formula. |
| 3 | Nominal neutrality; `μ`-neutrality; demand-determined debt | **PP** | Supporting theorems. Not headline. |
| 4 | Sufficient-statistic incidence formula (financing in the numerator, determinacy margin in the denominator) | **PP** | The paper's principal contribution. The rewrite restoring endogenous debt service was necessary and is correct. |
| 5 | Two-market Schur-complement extension | **PP** | Theory only. **May not be cited as a validated derivative:** its numerical validation gate (G3) is not passing. |
| 6 | Exact two-way / Shapley decomposition of the asset-demand response | **NI** | Reconstruction closes to machine precision. This is an identity, not a measurement, and its *interpretation* inherits the calibration's status. |
| 7 | The response is ~9/10 distributional, ~1/10 direct | **NI** for the split; **CU** for the external discipline of the dominant term | The split is exact. The distributional term has no external anchor. Do not present the magnitude as an estimated elasticity. |
| 8 | Levy more inflationary than lump-sum at the same **nominal appropriation** (Experiment N) | **RO** | Holds in one-asset, both uniform-ownership two-asset variants, both ends of the convenience-yield curvature, and the two-asset calibration. Two-asset leg is uncertified; the one-asset leg stands. |
| 9 | Levy more inflationary than lump-sum at the same **real program** (Experiment R) | **RO** | `subsec:regimesreal` / `tab:regimesreal`. Rankings survive; revaluation shares differ from Experiment N only in the third decimal. One-asset. |
| 10 | The two instruments lie on **opposite sides of zero** (straddling-zero) | **WP** | Two-asset only, and the two-asset solver does not currently meet the acceptance protocol. Distinct from row 8/9 and must never be stated as if implied by them. |
| 11 | One-asset magnitudes (`P*`, `ν`, `ν_reval`, welfare by group) | **QV** *conditional on* the existing portfolio-structure qualification | The one-asset solver is sound. The qualification (one asset overstates the link between total precautionary saving and nominal-debt demand) must travel with every number. |
| 12 | Two-asset magnitudes (any) | **WP** | Blocked by the acceptance protocol. Includes prices, quantities, welfare and financing differences. |
| 13 | "Empirically realistic ownership and illiquidity restore the one-asset sign" | **WP** | This is row 10 in narrative form. Same block. |
| 14 | The term "preferred calibration" applied to the two-asset economy | **WP** | Do not use until row 12 clears. Use "two-asset calibration (uncertified)". |
| 15 | Welfare progressivity / incidence reversal across regimes | **QV** one-asset; **WP** two-asset | Row 11 / row 12 split applies. |
| 16a | Front-loading **direction**: a large share of the eventual price-level adjustment occurs at announcement rather than during green-capital accumulation | **QV** one-asset; **WP** two-asset | **Corrected round 10: this is NOT a robust ordering.** It is a *provisional portfolio-robust timing pattern, conditional on certified solutions*. Two of the three structures supporting it are uncertified, so "robust across portfolio structures" cannot be asserted until the two-asset gate passes. |
| 16b | Front-loading **fraction** | **QV** one-asset at 77% (`F^j_P`); **WP** two-asset at 89% (`F^j_P`); the 107% figure is **`F^{L−LS}_P`, cross-instrument overshooting**, not a front-loading fraction of either regime | Three estimands with three denominators. The 107% must never be quoted as "the front-loading fraction". See `R10_EXECUTION_PLAN.md` §5 for the definition set. |
| 16c | **Sign** of the announcement response | **CS** | Conditional on portfolio structure. Never bundled with 16a. |
| 16d | **Welfare incidence** of the announcement revaluation | **CS** one-asset; **WP** two-asset | Depends on the pre-announcement ownership distribution, which is row 7's unanchored object. |
| 20 | Tax-timing threshold (`ρ_d* ≈ 0.61`, half-life ≈ 1.4 yr) | **IE** as a joint result; **WP** as a tax-timing object | Confounds delayed taxation with a permanent terminal-debt ratchet. **Round-10 edits applied**: the caveat now precedes the number, the exercise is labelled an illustrative joint result, and the macros carry a `Ratchet` suffix so no call site can quote them as pure tax timing. The underlying exercise and code are retained. |
| 21 | "The paper's central prediction is conditional on an observable — the announced financing schedule" | **CU**, and **removed from the text round 10** | Overclaim: the observable would have to be the schedule *and* the terminal-debt rule, which row 20 has not separated. The sentence no longer appears in the introduction. |
| 22 | Deficit finance is a transitional tax-timing problem; no genuine stationary deficit exists | **PP** | Correct, but currently sits alongside row 20, which is generated by a permanent stock increase. The two statements must be reconciled in the text. |
| 23 | Multiplicity / sunspot region | **IE** | The calibrated frontier never activates it. |
| 24 | Anchor insulation via indexed mandate | **IE** | Off-equilibrium design insurance; the paper already says so. |
| 25 | Optimal accommodation (`μ* = 0.045`) | **IE** | An optimal-real-rate statement, not an inflation prescription. Already scoped correctly in the text. |
| 26 | Aggregate-risk extension | **IE** | Orthogonal to the title question. |
| 27 | DTPL vs NK opposite announcement-inflation signs | **CU** | The comparison changes rigidity, household structure, financing, persistence, scale and closure simultaneously. Either build the nested ladder or remove the contrast from the body. |
| 28 | Self-financing magnitudes (`ν`, frontiers in `θ_g`) | **IE** | Correctly presented as internal technology frontiers, not point claims. |
| 29 | Wealth-mobility validation, Layer 1 (four definition-robust facts) | **QV** | Passes. Layer 2 is blocked on data access and is not claimed. |
| 30 | Resource BCR vs fiscal self-financing vs household-burden offset are three different objects | **PP** | Keep in the body. This is what stops the paper making a misleading self-financing claim. |

---

## Rows whose status changes as of round 10

| # | Was | Now | Reason |
|---|---|---|---|
| 5 | cited as validated | **PP** theory only | G3 not passing |
| 10, 12, 13, 14 | preferred-calibration results | **WP** | Two-asset acceptance protocol not met |
| 17 | one number | three estimands, split status | Different denominators conflated |
| 20 | reported threshold | **WP** | Timing and terminal debt confounded |
| 21 | stated in the introduction | **CU** | Overclaim on the observable |
| 16 | **RO** (as first proposed round 10) | split into **16a–16d**; 16a is **QV** one-asset / **WP** two-asset | *Withdrawn: my round-10 upgrade to "robust ordering" was wrong.* Two of the three supporting structures are uncertified, so the cross-structure claim is not available. The permitted narrative label is "provisional portfolio-robust timing pattern, conditional on certified solutions". |


---

## Addendum, round 10

**No one-asset publication fallback is approved.** If the two-asset gate
fails, `TWO_ASSET_FAILURE_FALLBACK_MEMO.md` must compare three architectural
options — repair or replace the solver; rebuild the portfolio block with a
better-disciplined adjustment technology; reframe as an analytical one-asset
mechanism paper without a preferred quantitative calibration — and no fallback
rewrite proceeds without explicit approval. Failure of the two-asset economy
is an architectural problem, not a presentational one, because the manuscript
currently rests its principal quantitative claims on it.
