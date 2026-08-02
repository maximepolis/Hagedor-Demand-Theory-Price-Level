# Two-asset numerical acceptance protocol, round 10

**Binding.** No two-asset quantity enters a paper table, figure, abstract,
introduction or conclusion until every gate below passes. Until then two-asset
output is confined to a quarantined validation appendix and labelled
uncertified.

**Tolerances are fixed here, before any rerun.** They are not to be revised
after seeing a result. If a gate proves unattainable, the correct response is
to report that the model as specified cannot support a quantitative claim at
this resolution — not to move the threshold. Any change to a number in this
file must be committed separately, before the run it governs, with its reason.

---

## 0. Why absolute residuals are not the test

The decision-relevant object is not the level of a price but a **contrast**
between financing regimes:

```
ΔP = P^levy − P^lump         (and likewise Δν_reval, Δwelfare)
```

A residual that is small relative to `P` can be large relative to `ΔP`. The
diagnostic runs in this session show exactly that pathology: a pure grid change
(bmax 12 → 96, nothing else) moved the tree price by **7.7%**, while the spread
of the tree price *across financing intensities* is **0.6%** of the same
variable. Under those conditions the sign of the contrast is not measurable,
however small the absolute residual looks.

Gate 11 is therefore the binding one and the others are necessary conditions
for it.

---

## 1. The acceptance matrix

Normalizations: `Y` = mean effective endowment `(1−D)`; `S_b` = aggregate
liquid demand; `K̄ = 1` = aggregate tree supply; `T_rev` = total tax revenue;
`DS` = real debt service `r·b`.

| # | Gate | Metric | Normalization | Threshold | Status on the FAST debug grid |
|---|---|---|---|---|---|
| 1 | Bond-market residual | `\|S_b − ιB/P\|` | `/ S_b` | **< 1e-6** | ~3e-4 to 1.6e-3 → **FAIL** |
| 2 | Tree-market residual | `\|S_k − K̄\|` | `/ K̄` | **< 1e-6** | ~1.8e-3 to 1.1e-2 → **FAIL** |
| 3 | Residuals against fiscal scale | both of the above | `/ T_rev` and `/ DS` | **< 1e-5** | not yet measured |
| 4 | Household convergence | VFI sup-norm `dV` | absolute | **< 1e-8** | ~1e-6 → **FAIL** |
| 5 | Distribution convergence | stationary sup-norm | absolute | **< 1e-11**, no `DIST_LOOSE` at any reported point | 1e-11 at most nodes; loose/failed at a few → **MARGINAL** |
| 6 | Policy stability | fraction of states changing the adjuster candidate between the last two outer iterations | share | **= 0** | not yet measured |
| 7 | Boundary mass, liquid | top-two-node mass at the root | share | **< 1e-4** | 4.56e-4 at bfac=8 → **FAIL** |
| 8 | Boundary mass, illiquid | top-two-node mass at the root | share | **< 1e-4** | ~1e-7 → **PASS** |
| 9 | Occupied support | highest occupied node / grid top, both grids | share | **< 0.90** | b = 1.00 → **FAIL**; k = 0.77 → pass |
| 10 | Mass conservation | `\|1 − Σ dist\|` | absolute | **< 1e-12** | ~1e-15 → **PASS** |
| 11 | **Grid-induced uncertainty in the contrast** | `max spread of ΔP over the refinement matrix` | `/ \|ΔP\|` | **< 0.10 required, < 0.05 preferred** | not yet measured; the single grid change observed implies it is currently far above 1 → **FAIL** |
| 12 | Same, for each reported contrast | `Δν_reval`, `Δwelfare` by group | `/ \|contrast\|` | **< 0.10** | not yet measured |
| 13 | Liquid-grid convergence | 3 resolutions | — | monotone, and gate 11 satisfied | not yet run |
| 14 | Illiquid-grid convergence | 3 resolutions | — | monotone, and gate 11 satisfied | not yet run |
| 15 | **Joint** refinement | full 3×3, not one-at-a-time | — | gate 11 on the full matrix | not yet run |
| 16 | Curvature invariance | grids rebuilt at exponent `γ`, `0.8γ`, `1.25γ`, endpoints fixed | `/ \|ΔP\|` | **< 0.10** | not yet run |
| 17 | Boundary invariance | `kmax × {1, 2}`, `bmax × {1, 2}`, node counts fixed | `/ \|ΔP\|` | **< 0.10** | not yet run |
| 18 | Dispersed starts | 5 seeds spanning ±20% of `q*` and ±20% of `P*` | relative dispersion of the root | **< 1e-5** | not yet run |
| 19 | Independent method | primary solver vs an independent aggregation/solution path | `/ \|ΔP\|` | **< 0.05** | one-asset has a second solver; the two-asset stationary map does not yet |
| 20 | Economic admissibility | consumption positive on the support; no policy NaN | — | at every reported point | currently enforced by the status codes |

**Reading the "status" column.** Every entry is from the FAST debug grid
(nb=30, nk=17), which is a debug artefact and not the benchmark. Its purpose
here is to show which gates are already known to fail, not to prejudge the
benchmark grid. Gates marked "not yet run" require the refinement matrix below.

---

## 2. The refinement matrix

Run as a **joint** 3×3, not two one-dimensional sweeps. One-at-a-time
refinement cannot detect the interaction that the diagnostic runs already
exhibit: widening the illiquid grid feeds the liquid tail through the dividend
flow, so the two dimensions are not separable.

| | `nk` = 34 | `nk` = 44 | `nk` = 56 |
|---|---|---|---|
| **`nb` = 60** | baseline | | |
| **`nb` = 78** | | | |
| **`nb` = 100** | | | |

At every cell, and for each financing intensity `α ∈ {0, 1}`, record: all of
gates 1–10, the solved `(P, q, S_b, S_k)`, the contrast `ΔP`, and the
welfare-by-group vector. Gate 11 is then computed over the nine cells.

Curvature (gate 16) and boundary (gate 17) invariance run as separate 3-point
and 2×2 sweeps at the baseline node count, so their effect is not confounded
with resolution.

---

## 3. Quarantine rules while the gate is open

Permitted:

- preparing and committing the code for X1, X3, X9 in two-asset form;
- running them and storing output under `output/quarantine/`;
- reporting two-asset results in a clearly-labelled validation appendix with
  the failing gates named;
- running every experiment in the **one-asset** economy and labelling it so.

Not permitted:

- any two-asset number in a body table, figure, abstract, introduction or
  conclusion;
- the phrase "preferred calibration" for the two-asset economy;
- externally overlaid sign maps on two-asset output;
- any claim that realistic ownership and illiquidity quantitatively restore
  the one-asset sign;
- adjusting a calibration, a grid or a tolerance in a way that changes a
  reported sign, unless the change is committed with its justification
  *before* the run that uses it.

---

## 4. Exit conditions

The two-asset economy is certified when gates 1–20 pass on the benchmark grid
and gate 11 passes on the full joint refinement matrix, with the tolerances as
written above.

If gate 11 cannot be met, the honest outcome is a paper whose quantitative
claims rest on the one-asset economy with its portfolio-structure
qualification, and whose two-asset analysis is a theoretical extension plus a
documented numerical limitation. That is a publishable paper. A paper that
quotes an uncertified sign is not.
