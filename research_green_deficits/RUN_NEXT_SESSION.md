# Run sheet — current session

Run everything from `research_green_deficits/`.

---

## STEP 0 — Pull first, then VERIFY (do not skip)

Three runs have been lost to a stale checkout. Pull, then confirm the header
before letting anything run long.

```bash
git pull origin claude/hagedorn-dtpl-matlab-9abghk
git log --oneline -1        # must show f25451d or later
```

```matlab
clear functions; rehash
which main_twoasset_ownership_kv    % confirm it points at THIS repo copy
```

**Verification gate.** When Run 1 starts it must print these two lines:

```
liquidity: zeta_b=2.00, Stone-Geary shift bbar=0.030 (0 => Inada at b=0 => HtM==0)
dividend payout phi=0.25 (1 => full d*k paid LIQUID => wealthy never run down => WHtM==0)
```

If the `dividend payout phi=` line is **missing**, the code is stale — stop,
re-pull, restart MATLAB. Everything below assumes those lines appeared.

---

## RUN 1 — ownership + infrequent adjustment (~8 min) — THE PRIORITY

```matlab
parpool; clear; FAST = true; main_twoasset_ownership_kv
```

Output: `output/tables/twoasset_ownership_kv.txt`

Three things to read, in order:

1. **`HtM ... | WEALTHY (qk>0.50): ___`** — the point of the whole variant.
   Positive is the goal (US target ~20%).
2. **`sign contrast survives: ___`** — must stay `1`. This is the paper's
   headline; it held at bbar=0 and at bbar=0.03, and must survive phi=0.25.
3. **`wealth:` line** — total wealth x income, and the tree yield `d/q`.

### If WHtM is still 0.000

Change one line in `main_twoasset_ownership_kv.m` and rerun (8 min):

```matlab
p.div_payout = 0.10;     % was 0.25 — retain even more inside the illiquid account
```

If that still gives 0, stop and send the table. Do not keep sweeping — at
that point the obstacle is structural and I write it up as a limitation
rather than burning your compute.

---

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
| Ownership + friction | **Run 1** — `S_b`=0.30 hit, sign contrast survives, WHtM pending |
| Welfare by decile (R1) | **Run 2** — rerun under the new calibration |
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
