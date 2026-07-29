# Run sheet — current session

Run everything from `research_green_deficits/`.

---

## STEP 0 — Pull first, then VERIFY (do not skip)

Three runs have been lost to a stale checkout. Pull, then confirm the header
before letting anything run long.

```bash
git pull origin claude/hagedorn-dtpl-matlab-9abghk
git log --oneline -1        # must show the "restores the one-asset sign" commit or later
```

```matlab
clear functions; rehash
which main_twoasset_ownership_kv    % confirm it points at THIS repo copy
```

**parpool note:** open the pool ONCE per MATLAB session:

```matlab
if isempty(gcp('nocreate')), parpool; end
```

Calling `parpool` again while a pool exists errors (this killed a run).
None of the commands below include `parpool` — run the guard line once at
the start instead.

**Verification gate.** When Run 1 starts it must print these two lines:

```
liquidity: zeta_b=2.00, Stone-Geary shift bbar=0.030 (0 => Inada at b=0 => HtM==0)
dividend payout phi=1.00 (1 => full d*k paid LIQUID => wealthy never run down => WHtM==0)
```

If the `dividend payout phi=` line is **missing** or shows `0.25`, the code
is stale — stop, re-pull, restart MATLAB. Everything below assumes the gate
passed.

---

## RUN 1 — regenerate the BENCHMARK ownership-KV economy (~9 min)

The phi=0.25 experiment overwrote `output/twoasset_ownership_kv.mat` with an
economy we rejected (top1 = 0.75, contrast lost). The driver's benchmark is
now phi=1 + bbar=0.03 (the run that restored the one-asset disinflation:
dlnP lump-sum = -0.0098, levy = +0.0273, top1 = 0.33). Regenerate it:

```matlab
clear; FAST = true; main_twoasset_ownership_kv
```

Header must show `dividend payout phi=1.00`. Expected result: essentially a
repeat of the beta=0.87421 run (S_b=0.30, q=1.51, contrast survives=1).
This rewrites the benchmark .mat that Run 2 consumes.

## RUN 1-FULL — full-grid headline (~40 min) — REFEREE-CRITICAL

The restoration number dlnP = -0.010 is currently FAST-grid only, and it is
the paper's headline; referee point M1 (REFEREE_REPORT_INTERNAL_R5.md) says
the claim lives or dies on this. After the FAST regen looks right:

```matlab
clear; main_twoasset_ownership_kv
```

Compare the financing pair against the FAST run. If the lump-sum dlnP stays
negative and within ~30% of -0.010, the headline stands and I write the
full-grid numbers in. If it moves materially, send both tables.

OPTIONAL but cheap immunization (one line each, ~9 min each): the lambda
sweep. Edit `p.lambda_adj` to 0.10, rerun FAST, then 0.25, rerun FAST, and
send the three financing pairs. This answers "is the contrast knife-edge in
the friction parameter?" before a referee asks.

## RUN 1b — the KMV (friction-only) variant (~10 min)

The WHtM question is now settled analytically: convenience utility places a
liquid floor b >= sqrt(chi)*c - bbar under every household, so ONLY
households consuming below ~1.06 x mean income can be hand-to-mouth, and
wealthy-HtM is zero by construction. The one place WHtM can live is the
chi_b -> 0 friction-only limit (KMV). The driver now runs it off a flag,
writing to SEPARATE files (`twoasset_ownership_kmv.*`), so the benchmark is
never clobbered:

```matlab
clear; FAST = true; KMV = true; main_twoasset_ownership_kv
```

Read in `output/tables/twoasset_ownership_kmv.txt`:
- `WEALTHY` HtM — the bound vanishes here, so this run decides whether the
  friction-only end quantitatively delivers WHtM (the paper's remark
  currently claims only that it is the sole place the mass can live).
- The financing pair — with chi_b=0 the convenience-yield discipline is
  gone, so whatever the contrast does here is reported as the OTHER end of
  the chi_b trade-off, not as the benchmark.

## RUN 2 — welfare incidence under the new calibration (~minutes)

Only after Run 1 converges (it reads `twoasset_ownership_kv.mat`).

```matlab
clear; main_twoasset_welfare
```

Output: `output/tables/twoasset_welfare.txt` — CE incidence by wealth decile,
lump-sum and levy, in both two-asset economies. This is the paper's title
question answered in the disciplined model.

---

## RUN 3 — convenience-yield calibration: DONE, interpreted

Your run produced sign-correct but hugely inflated ratios (-16 to -59).
Diagnosis: the GE ratio divides by dlnS_b, but bond holdings are
demand-determined and barely move when the instrument shifts the TREE
supply — the ratio is not the KVJ coefficient. The structural object is
closed-form: dln(spread)/dln(b) ~ -zeta, and KVJ's point estimate
(-0.75pp on a 0.73pp mean spread) is a log-elasticity of ~ -1.0 with
range ~[-2.05, -0.55]. So: **zeta is disciplined to ~1 (point), with the
benchmark zeta=2 inside the range at its steep edge.** The driver now
prints this mapping. No rerun needed unless you want the updated table
text:

```matlab
clear; FAST = true; calibrate_convenience_kvj
```

## RUN 3b — headline at the KVJ point-disciplined curvature (~9 min) — REFEREE-CRITICAL (M5)

Does the restoration survive zeta = 1? Writes to suffixed files
(`twoasset_ownership_kv_z10.*`), benchmark untouched:

```matlab
clear; FAST = true; ZETA = 1.0; main_twoasset_ownership_kv
```

Read the financing pair. If dlnP(lump-sum) stays negative, the headline is
disciplined at the KVJ point estimate and I write it in as such; if it
flips, the paper reports the restoration as holding on the steep half of
the KVJ range — either way the claim gets sharper.

---

## RUN 4 — two-asset transition (sequence-space Newton) — OPEN A POOL FIRST

The Jacobian is now built with `parfor`, and it is ~95% of the runtime, so a
pool matters more here than anywhere else in the project:

```matlab
if isempty(gcp('nocreate')), parpool; end
clear; FAST = true; main_twoasset_transition
```

The first three lines tell you the numerical health before any solving:
- endpoint refinement, `||r||` about 1e-15 for each boundary steady state;
- `steady-state consistency check`, expect about 6e-08;
- `finite-difference step set to h`, auto-derived, expect about 2e-04.

Then the Newton trace should fall monotonically in `||r||2`. Target is
`1.0e-04`. Budget is 40 minutes under FAST.

Two lines at the end are worth reading carefully:
- `max tree-market residual over IMPOSED dates` is the real accuracy figure.
- `terminal-date tree gap` is a HORIZON diagnostic, not a solver residual:
  t=T carries no clearing condition. If it exceeds 1e-2 the distribution has
  not settled by T and the driver says so; the fix is a longer horizon
  (drop FAST, which raises T from 40 to 80), not more solver work.

## RUN 4c — matched-parameter ladder (~35 min) — REFEREE-CRITICAL (M2) — RUN THIS FIRST

The paper's 2x2 table compares economies that are each separately
recalibrated, so a referee can fairly ask whether the restored sign comes
from the INGREDIENTS or from the discount factor that came with them. This
holds beta, chi and the grids at the benchmark and switches one ingredient
off at a time, so consecutive rows differ by exactly one thing:

```matlab
if isempty(gcp('nocreate')), parpool; end
clear; FAST = true; LADDER = true; main_twoasset_ownership_kv
```

Writes `output/tables/twoasset_ownership_kv_ladder.txt`; the benchmark
outputs are untouched. The table reports dlnP under each instrument, whether
the sign contrast survives, and top-1% wealth for each cell. What I expect,
and what would settle M2: the contrast should hold in the benchmark row and
break in the rows that remove the wedge or the friction, at unchanged
preferences.

## RUN 4d — transition at T = 120 (~25 min) — LAST transition change

```matlab
if isempty(gcp('nocreate')), parpool; end
clear; TT = 120; main_twoasset_transition
```

Where this stands. The horizon problem is solved: the terminal-date tree gap
fell from 0.33 (T=40) to 1.4e-04 (T=120), so the front-loading share is now
an interpretable number rather than an artefact of a horizon that was too
short. Conditioning is solved too: sigma_min went from 5.9e-05 to 4.4e-03.
What remained was `||r||inf = 6.6e-03` against a 1.0e-04 target, sitting at
t = 1 and t = 2 in every continuation step. That is a basis problem, not a
solver problem: with seven exponentials the system was 238 equations in 14
unknowns, and a sum of smooth decaying functions cannot represent the
announcement-date jump. The basis now leaves the first eight dates
individually free and keeps the exponentials only for the tail.

What to read off the run, in order:
- `projecting paths onto 15 basis functions per price (unknowns 238 -> 30)`
  confirms the new basis is live. If it still says 7 / 14, the checkout is
  stale.
- `||r||inf` at the end of continuation step 4/4. Target 1.0e-04. The
  `bond ... (t=)` and `tree ... (t=)` tags say WHERE the misfit sits; if it
  has moved off t = 1, 2 and onto t = 9, 10, the free window needs widening
  and I will do that in one line.
- `terminal-date tree gap` should stay near 1e-04.
- `front-loading share`, which is the number the paper actually reports.

This is one appendix number. If it converges, good; if it stalls again at
some level below 1e-2, I will report the path with its accuracy stated and
move on rather than spend more runs on it.

## RUN 4b — non-separable liquidity (unchanged, only if not already current)

```matlab
clear; FAST = true; main_twoasset_nonsep
```

## RUN 5 — refresh the paper macros (always last)

```matlab
clear; export_paper_numbers
```

Writes `paper/numbers_auto.tex`.

---

## Do NOT rerun

`main_twoasset_kv` and `main_twoasset_step0` are **unaffected** by the recent
changes — `bbar` and `phi` both default to the previous behaviour and that
path was verified bit-identical. Rerunning them costs hours and changes
nothing.

---

## What to push back to GitHub

Push **only**:

- `output/` (the `.txt` tables and the `.mat` files)
- `paper/numbers_auto.tex`

**Do not upload your local `paper/green_deficits_price_level.tex`.** It is
behind the branch and re-uploading it reverts the revision — this has
happened three times.

Also paste into the chat:

1. The full console output of Run 1, including the `[  Ns] pre-scan/secant`
   lines — the calibration path is as informative as the final numbers.
2. Any red MATLAB error text, verbatim.

---

## Status

| Item | State |
|---|---|
| Step 0, variant (b), audit, frictionless ownership | done, integrated |
| **Ownership + friction, FULL grid** | **DONE — sign contrast survives: dlnP -0.023 (ls) vs +0.014 (levy)** |
| Welfare by decile (R1) | done, integrated |
| Convenience yield (R3) | done — zeta disciplined to ~1; benchmark zeta=2 at range edge |
| Non-separable (R3 fork) | done — both xi give positive dlnP(ls), integrated |
| KMV friction-only | done — HtM 54% but WHtM still 0 (top10 = 98%); written up as a model-class bound |
| zeta=1 rerun (z10) | INVALID — experiment q halved vs baseline (branch jump); rerun after the bracket fix (RUN 3b) |
| Matched-parameter ladder (M2) | **DONE — settled**: every ingredient individually necessary at fixed beta, chi, grids |
| Two-asset transition | **DONE — CONVERGED** at T=120: \|\|r\|\|inf 6.6e-05, terminal gap 2.0e-08, resource identity 4e-14, 640s. Front-loading 89% vs 77% one-asset; impact dlnP +0.0075 vs +0.0084 long run; impact dlnq +1.24%. Written into the paper. |

### Open items on my side

- M3 2D (beta x chi) calibration: code to scaffold, then ~3 runs.
- M6 restructure (promote two-asset to the body) once zeta=1 is re-checked.
- Regenerate figures under the new palette (`replot_paper_figures`).
