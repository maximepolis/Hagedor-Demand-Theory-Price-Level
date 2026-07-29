# Internal referee report R5 — the two-asset restoration state

Simulated top-5 referee, written against the current draft (the version with
the "Ownership plus illiquidity restores the one-asset sign" paragraph, the
WHtM impossibility remark, and the 2×2 experiment table). Each point:
criticism → concrete fix → owner/status.

**Overall assessment.** The paper now has a genuinely strong computational
arc: naive two-asset extension overturns the headline sign; calibrating
ownership and illiquidity jointly restores it; and the wealthy-hand-to-mouth
limitation is converted from an apology into a two-line structural bound.
That arc is publishable at a top general-interest journal *if* the headline
number survives scrutiny of its numerical error budget and its
one-calibration-point provenance. The two fatal-risk items are M1 and M2.
Everything else is hardening.

---

## Major

### M1. The headline number is smaller than the unexamined error budget (FATAL RISK)

The restoration rests on dlnP(lump-sum) = −0.010, produced on the FAST grid
(nb=40, nk=22, nx=100), with a soft-accepted VFI (relative plateau tolerance
3e-3), a distribution accepted at 1e-8 per state, and a tree-market bisection
stopped at |Sk−K| < 2e-3 or a q-interval of 1e-3·q_ref. A referee's first
question: **is |−0.010| distinguishable from zero given those tolerances?**
P = ι_H·B/S_b, so d ln P inherits the error in S_b at two equilibria; the
sign claim needs S_b accurate to well under 1% at both points.

Fixes, in order of power:
1. **Full-grid rerun** (nb=60, nk=34, nx=150) of the benchmark — RUN 1-FULL
   in the run sheet. If −0.010 moves materially, the paper's claim moves.
2. **Policy-stability diagnostic** now in the solver (`diag.pol_stable`):
   discrete policies lock exactly before values plateau; "policies unchanged
   for N sweeps" is the sharp statement for the soft-accepted fixed point.
   Report it in the accuracy appendix.
3. Tighten the bisection for the headline economies only (|f| < 5e-4, 30
   iterations) and report the achieved residuals next to the dlnP pair.
4. Grid-doubling row for the benchmark cell (part of the R4 accuracy pack).

Status: (2) done in code; (1), (3), (4) need runs. Until (1) lands, the
paper's Status block honestly labels the numbers "validation grid".

### M2. One calibration point; the 2×2 cells are not matched-parameter — **SETTLED 2026-07-28**

The ladder ran (`twoasset_ownership_kv_ladder.txt`, coarse grid, β = 0.874
and χ_b = 0.00223 held throughout):

| economy | dlnP(ls) | dlnP(levy) | contrast | top1 |
|---|---|---|---|---|
| benchmark | −0.0108 | +0.0116 | yes | 0.33 |
| no intermediation wedge | +0.0028 | +0.0079 | no | 0.34 |
| no superstar state | +0.0344 | +0.0613 | no | 0.06 |
| no adjustment friction | −0.0607 | −0.0330 | no | 0.71 |

Every removal destroys the contrast at fixed preferences, each through a
legible channel (wedge: lump-sum sign flips with concentration unchanged;
superstar: concentration collapses; friction: both signs go negative while
concentration overshoots). The paper now reports this table in place of the
"left for future work" footnote. Objection converted to strength, as hoped.
The λ-sweep immunization remains optional. Original item kept below for the
record.

### M2 (original). One calibration point; the 2×2 cells are not matched-parameter (FATAL RISK)

The 2×2 table locates the restoration, but each cell is calibrated to its
own targets — the uniform cells set χ_b to the debt target, the benchmark
recalibrates β to the direct-holding target (β = 0.874 vs ~0.93 elsewhere).
A referee will ask whether the sign flip is the *ingredients* or the
*recalibration* (in particular the much lower β / poorer economy). The table
now carries an honest footnote, but the footnote promises a
"matched-parameter decomposition" that must actually exist.

Fix (cheap, ~9 min/run at FAST): a 4-run ladder holding parameters fixed at
the benchmark values (β=0.874, χ fixed, λ=0.15) and switching ingredients
one at a time: (i) benchmark; (ii) ι_H=1 (kill wedge); (iii) no superstar;
(iv) λ→1 (kill friction). Reported as a decomposition column, this converts
M2 from objection to strength. Needs a small driver flag (I can scaffold on
request; the KMV flag shows the pattern).

Additional cheap immunization: a λ ∈ {0.10, 0.15, 0.25} sweep showing the
contrast is not knife-edge in the one free friction parameter.

### M3. Total wealth is half the data (W = 1.8× income vs ≈3–5 in the data; β = 0.874)

The benchmark hits S_b = 0.30 by shrinking *total* wealth rather than the
liquid *share* (ω = 0.166 vs ≈0.09 target). A referee: "your disciplined
economy is half as wealthy as the US; the restored disinflation might be a
poor-economy artifact" — and M2's ladder cannot fully answer this because no
cell is wealth-matched. Fix: 2D calibration, β targeting W (or q·K̄) and χ_b
targeting S_b jointly. Two nested secants, each solve ~2–4 min — feasible.
This is the single biggest remaining *calibration* gap and I recommend it
before promoting the result to the body.

### M4. WHtM measurement conventions

The remark's bound is stated for the cutoff b < 0.02 (2% of mean income).
KVW define hand-to-mouth relative to the paycheck (b ≤ y/2 per pay period)
and report ~1/3 of households, ~2/3 of them wealthy. The paper should (i)
state the cutoff explicitly next to the remark, (ii) report the measure at
the KVW paycheck cutoff too — the bound's threshold c ≈ 1.06 scales with
the cutoff as c* = ((b̄+cut)/√χ_b), so the structural point survives any
sensible cutoff, and showing that kills the "arbitrary cutoff" objection.
Fix: one paragraph + one line of driver code (report H at b < y_i/2).

### M5. The KVJ discipline is claimed but not yet computed at this spec

The remark leans on the convenience-yield term as "what the KVJ evidence
measures", and the wording is now conditioned — but Run 3
(calibrate_convenience_kvj) has not yet produced the elasticity at the
current specification. If ζ = 2 delivers an elasticity far from −0.75pp/log
point, the benchmark χ_b/ζ pair needs re-discipline and the headline should
be re-run at the disciplined ζ. This is the run with the largest potential
to *move* the benchmark, so it should come right after RUN 1-FULL.

### M6. Structure: the strongest result lives in an appendix

The restoration + impossibility remark are currently in the demoted
two-asset appendix section, while the body's two-asset paragraph still
reflects the older "sign is specification-dependent" reading. For
submission, either promote the two-asset block to the body (the R6
restructure, prune to ~55–60pp) or, at minimum, rewrite the body paragraph
to state the restoration and point to the appendix. The current state —
headline-grade result invisible from the body — is the worst of both.
Recommend doing this after M1/M3 lock the number.

---

## Minor

- m1. The superstar header prints `p_in=0.000` (3 d.p.): either the wealth
  fit chose p_in < 5e-4 — worth a sentence, since a near-degenerate
  superstar state does heavy lifting for top-1% = 33 — or the printout needs
  `%.4f`. One-character fix; check which.
- m2. The welfare-decile numbers (TwoA/TwoBWel*) predate the ownership
  benchmark; Run 2 refreshes them under the regenerated .mat, and the text
  should say which economy each column is.
- m3. The KMV variant (Run 1b) result should be added to the remark once
  computed — currently the remark is worded to be correct either way, which
  is right, but the number is better.
- m4. `ksat` (k-grid top mass) is now reported — carry it into the Status
  block ("<1% at the benchmark") once the regen run confirms.
- m5. The identical q = 3.9058 in both φ=0.25 experiments was suspicious;
  that economy is discarded, but the coincidence pattern (bisection landing
  on the same endpoint) is worth one glance at the full-grid run's
  experiment section to rule out a shared-bracket artifact in the pipeline.

## Priority order

1. RUN 1 (benchmark regen) + RUN 1-FULL (M1) — the number must hold.
2. RUN 3 / KVJ (M5) — the run most able to move the benchmark.
3. M3 2D calibration + M2 matched ladder — code from my side, then ~6 runs.
4. RUN 1b (KMV), RUN 2 (welfare), M4 cutoff robustness.
5. M6 restructure once the number is locked; then RUN 4 scaffolds, RUN 5.

---

## Round 6 (external referee report, 2026-07-29) — disposition

Four technical items, ALL CONFIRMED as proof errors and FIXED in the text:

1. **Prop 1, low-P edge under strong accommodation**: uniform boundedness of
   S was asserted, not proved. Fixed with a better argument than the report
   asked for: the aggregated stationary budget identity gives
   Phi = (E[y] - g - C(P))/|r^ss| at ANY price, and C -> infinity with the
   transfer (buffer-stock MPC bound), so Phi -> -infinity is now proved.
2. **A.6 local argument**: d tau = dg - r^ss b dlnP; the feedback term was
   dropped. Fixed: disinflationary candidate is self-consistent (feedback
   reinforces); the inflationary case is disciplined by the finite condition
   tau1 >= tau0, confirmed at the calibration.
3. **A.4 mandate high-P (R2)**: condition corrected to
   g < min y - r^ss*abar; reduces to the stated one at abar=0 (benchmark);
   maintained by Assumption 1 for r^ss>0.
4. **A.7 statewise improvement**: with phi_D>0 lower damages COMPRESS the
   unit-mean process (high states fall), and psi>0 shifts the incidence
   weights; claim recast as process-level improvement, ranking numerical.

Four major comments, integrated textually; the computational asks are the
next-round run list:

- **MC1 (sign-contrast scope)**: DONE textually. Abstract, contributions,
  and conclusion now lead with the ordering as the robust result; the
  benchmark sign contrast is explicitly scoped ("straddles zero in the
  benchmark"; restoration conditional on ownership + illiquidity).
- **MC2 (tax-demand validation)**: reconciliation of the Prop-7 covariance
  (-0.07, marginal, linearized) and the finite-change split (+0.34/+3.44,
  program-size) written under a common per-revenue normalization; the
  unvalidated status of the dominant distributional term is now stated in
  the text and in the conclusion's open items.
  RUNS NEEDED: (i) wealth-mobility / liquid-asset transition moments vs
  model; (ii) finite-horizon financing comparison (at what horizon does the
  levy-vs-lump-sum ordering become operative along the path?).
- **MC3 (transition-inclusive welfare as principal object)**: the welfare
  section now names the two incidence objects and declares the
  transition-inclusive one (computed for one asset) the object answering
  the title. RUN NEEDED: transition-inclusive incidence on initial nominal
  portfolios in the ownership+illiquidity economy (blocked on the KV
  two-asset transition, which carries a second endogenous state).
- **MC4 (announcement 2x2)**: conclusion no longer claims "a Phillips-curve
  economy predicts inflation" unconditionally (RANK active-rule variants
  price it negative); the deficit-path caveat is stated where the service
  rule is imposed (no deficit-financed DTPL path is computed).
  RUNS NEEDED: the full 2x2 {price determination} x {lump-sum, levy} with
  matched incidence, plus a deficit-financed DTPL announcement path.
