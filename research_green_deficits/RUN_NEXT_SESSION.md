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

## RUN 4 — two-asset transition, now a sequence-space Newton solve (~10-25 min)

The damped map could not solve this system and has been replaced by a Newton
solve on the joint path {P_t, q_t}, following the same sequence-space
approach as the one-asset `verify_transition_ssj` cross-check. The damped map
remains underneath purely as a fallback.

```matlab
clear; FAST = true; main_twoasset_transition
```

Watch the console:
- `newton  0: ||r||inf = ...` then `newton  1, 2, ...`. The norm should fall
  by orders of magnitude, not drift. Jacobian builds announce themselves
  (`building Jacobian (78 residual solves)`) and are the slow part.
- Success prints `solver: sequence-space Newton, converged in N iterations`
  plus a `sigma_min` / `cond` line, which is the determinacy diagnostic:
  a near-singular Jacobian would flag the dynamic analogue of the flat
  asset-demand crossing.
- If it prints `did NOT converge` it falls back to the damped map and labels
  the numbers provisional, exactly as before. Send the console output either
  way.

Read in `output/tables/twoasset_transition.txt`: the `impact d ln P`, the
`front-loading share`, and the residual line. The front-loading share is the
number the paper wants, to compare against the one-asset value.

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
| zeta=1 rerun (z10) | INVALID — experiment q halved vs baseline (branch jump); rerun after the bracket fix |
| Two-asset transition | crashed on a diverging outer loop; solver rebuilt, **rerun** |

### Open items on my side

- M2 matched-parameter ladder and M3 2D (beta x chi) calibration: code to
  scaffold, then ~6 runs.
- M6 restructure (promote two-asset to the body) once zeta=1 is re-checked.
