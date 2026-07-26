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
parpool; clear; FAST = true; main_twoasset_ownership_kv
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

## RUN 3 — convenience-yield calibration (~15 min)

```matlab
parpool; clear; FAST = true; calibrate_convenience_kvj
```

Output: `output/tables/convenience_kvj.txt`. This was fixed to shift REAL
tree supply (nominal debt is neutral by Theorem 2), so it should now give a
non-degenerate elasticity. Look for a `zeta*` matching the KVJ headline of
about -0.75pp per log point.

---

## RUN 4 — the two remaining scaffolds

Both reuse the Step 0 economy and need `output/twoasset_step0.mat`.

```matlab
parpool; clear; FAST = true; main_twoasset_nonsep
clear; FAST = true; main_twoasset_transition
```

Outputs: `output/tables/twoasset_nonsep.txt`,
`output/tables/twoasset_transition.txt`. These are first-run scaffolds — if
either dies, send the console text verbatim rather than debugging it.

---

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
| Step 0 (frictionless two-asset) | done, integrated |
| Variant (b) KV | done, integrated |
| Incidence audit | done, integrated |
| Ownership frictionless (R2) | done — `S_b`=0.30, omega=0.09, WHtM=0 |
| Ownership + friction | benchmark computed (restores one-asset disinflation); .mat regen = **Run 1** |
| Welfare by decile (R1) | **Run 2** — rerun under the regenerated benchmark |
| Convenience yield (R3) | **Run 3** |
| Non-separable, transition | **Run 4** |

### Open items on my side (not yours to run)

- Total wealth `W`=1.81 x income vs KMV ~3.2: we hit `S_b` by shrinking
  wealth rather than by fixing the split (`omega`=0.166 vs ~0.09). The fix is
  a 2D beta x chi calibration, deferred until WHtM resolves since dividend
  retention moves `omega` anyway.
- `chi` is set at the frictionless value rather than re-disciplined to the
  KVJ elasticity. Run 3 supplies that number.
- Paper integration of the two-asset ownership results (sign contrast
  survives at bbar=0 and bbar=0.03) once Run 5 refreshes the macros.
