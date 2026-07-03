# Dynare block — transition dynamics

**Status: PARTIALLY IMPLEMENTED (tier 1 of roadmap step U6).**

`green_rank_nk.mod` is a representative-agent New Keynesian skeleton
(Rotemberg pricing, inertial Taylor rule, real debt with a debt-stabilizing
tax rule, green public capital, carbon stock, TFP damages). Running

```
dynare green_rank_nk
```

produces perfect-foresight **transition paths** for a permanent
deficit-financed green-investment program (output, inflation, debt, green
capital, carbon stock, damages, taxes) — the tier-1 answer to referee risk
R1 ("only steady state").

**Honest scope limits:**

- This block does **not** contain the paper's price-level mechanism. The
  DTPL requires incomplete markets; in RANK, inflation dynamics come from
  the Taylor rule + Phillips curve, and the price *level* is not pinned by
  asset demand. Use it only for transition shapes of the real/nominal block.
- The HANK transition (sequence-space Jacobians around the steady states
  computed by the MATLAB package; belief-switch experiment between the
  green-boom and brown-stagnation equilibria where they exist) is
  **NOT YET IMPLEMENTED** — roadmap step U7.
- The calibration is quarterly and illustrative; the steady-state block may
  need `initval` tuning depending on your Dynare version. Treat failures of
  `steady` as calibration issues in this skeleton, not as statements about
  the paper's model.

**Planned monetary-regime comparison in this block (roadmap U6):**
nominal-rate peg (`rho_i=1, phi_pi=0` variant), standard Taylor (committed
calibration), aggressive inflation targeting (`phi_pi=3`), and a temporary
green-accommodation rule (`i` responds to `gg` for the program's first
years) — the four regimes required by the research-program specification.
