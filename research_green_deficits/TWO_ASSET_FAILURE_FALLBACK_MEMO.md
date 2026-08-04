# If the two-asset specification does not certify: three architectural options

Owed since round 10, when the one-asset fallback was **not approved** pending a
memo comparing architectural options. Referee report R12 makes it decision-
critical rather than contingency planning: the report recommends rejection and
a narrower field-journal paper, and the narrowing it proposes is close to
Option A below.

**No option is recommended for adoption here.** The purpose is to set out what
each costs and what each still supports, so the choice is made deliberately
rather than by whichever run finishes first.

---

## 1. What would trigger this

Gate 11: grid-induced uncertainty in $\Delta P = P^{LEV}-P^{LS}$, normalised by
$|\Delta P|$ rather than by $P$, must fall below 0.10. The current evidence is
not encouraging and it is worth stating precisely rather than softly:

| observation | value |
|---|---|
| root movement from a **pure `bmax` change** (12 → 96) | **7.7%** |
| spread of $q^*$ **across the whole financing experiment** $\alpha\in[0,1]$ | **0.6%** |
| implied signal-to-grid-noise | **≈ 0.08** |
| b-boundary top-two-node mass vs target | 4.6e-4 vs 1e-4 |
| tree-market residual at the root | 1e-2 – 1e-3 |

One axis of discretization moves the answer an order of magnitude more than the
economics does. Gate 11 was designed to make that disqualifying rather than
discussable.

**This is separate from what the referee says.** R12 infers fragility from the
*calibration* — several ingredients jointly necessary, the payout convention
decisive. The numerical statement is stronger and independent: on the current
discretization the two-asset level sign is **not measurable at all**, whatever
the calibration. Both can be true; only the second is settled by a gate.

**Not triggered by:** the ordering. Nothing above bears on whether the levy is
more inflationary than the lump-sum tax; the ordering is a comparison of two
solves on the *same* grid, where the common discretization error differences
out. That asymmetry is what makes Option A viable.

---

## 2. Option A — narrow to the certified one-asset economy

**The paper becomes:** financing incidence in a one-asset DTPL economy, with
the two-asset specification demoted to a robustness section that reports the
ordering and explicitly declines to report the level sign.

**Retains:** Propositions 3, 5, 6 (theory is unaffected by a numerical gate);
the accounting decomposition; the one-asset transition and welfare incidence;
the financing ordering; the deficit decomposition (C1/C2/C4).

**Loses:** the restored level sign; the claim that realistic ownership
validates the mechanism; Table 4's two-asset welfare incidence; the
announcement front-loading figures conditioned on portfolio structure.

**Cost:** the title question is answered only in an economy whose portfolio
concentration is unrealistic by construction — precisely R12's Major 7. The
referee would call this the field-journal paper, and would be right.

**Effort:** weeks. Mostly deletion and rescoping.

**Honest appraisal:** this is the *safe* option and the *weakest* one. It
concedes the objection that motivated the two-asset extension in the first
place: total precautionary wealth is not demand for government debt.

---

## 3. Option B — re-engineer the two-asset numerics and re-certify

**The change:** attack the discretization rather than the economics. The
diagnosed causes, in order of expected payoff:

1. **The φ = 1 payout convention couples the grids.** Full dividend paid
   liquid means the k-grid ceiling feeds the b-grid distribution, so widening
   one moves the other — which is why the joint 3×3 matrix exists and why the
   b-boundary will not clear while k moves. A partial payout (φ < 1) decouples
   them. **But φ is also economically decisive** (R12 Major 2 names the payout
   convention as the ingredient that is quantitatively decisive and externally
   unidentified), so this is not a purely numerical change and must not be
   presented as one.
2. **The adjuster's choice is an argmax over a discrete candidate set**, which
   is what makes $S_k(q)$ a step function and puts a floor under the residual.
   A continuous adjustment-cost formulation replaces the step with a smooth
   first-order condition. R12 Major 2 item 6 asks for exactly this
   independently, as a robustness check.
3. **Non-product grids** — the mass concentrates in a thin region of
   $(b,k)$ space and a tensor grid spends most of its nodes where nothing
   lives.

**Retains:** everything, if it works.

**Cost and risk:** the honest risk is that (1) and (2) are not numerical
refinements but different economies. Changing φ changes wealthy-hand-to-mouth
behaviour, which is one of the ingredients the sign depends on; changing the
adjustment technology changes the illiquidity that the sign depends on. **If
the sign survives only under the old discretization, that is itself a finding
and it is a negative one.**

**Effort:** months, and re-calibration throughout, because every one of these
moves the targeted moments.

**Precondition:** Option B is only worth starting if the *ordering* certifies
first. If even the ordering is inside the grid noise, there is nothing to
re-engineer toward.

---

## 4. Option C — replace the second asset with a reduced-form wedge

**The change:** drop the explicitly solved Lucas tree. Model the illiquid
margin as a reduced-form wedge on the bond demand schedule — a
liquidity-preference shifter calibrated to the same ownership and adjustment
moments, entering $\Sfun$ directly.

**Retains:** the economic content the two-asset model was introduced for —
that only the *liquid slice* of saving clears the nominal market — while
returning to a one-dimensional state space where the existing certification
machinery already works.

**Loses:** Proposition 6 becomes decorative. The Schur complement exists
precisely because there are two market-clearing conditions; with a wedge there
is one, and the paper's most technically substantive result loses its object.
It also cannot answer R12 Major 2's request for the decomposition, since there
would be nothing to decompose.

**Cost:** the wedge is not identified by anything the tree was identified by.
It would be a calibrated reduced form standing where a solved general
equilibrium used to be, and a referee would reasonably ask why the
one-asset economy with a taste shifter is not simply the one-asset economy.

**Effort:** weeks to implement, but the identification burden is the same one
R12 Major 1 already levels at the one-asset model, now with an extra free
parameter.

---

## 5. Comparison

| | A: narrow | B: re-engineer | C: wedge |
|---|---|---|---|
| answers the title question | no | yes, if it certifies | partially |
| Proposition 6 retained with content | no | yes | **no** |
| level sign reportable | no | unknown | unlikely |
| ordering reportable | yes | yes | yes |
| certification tractable | **already** | unknown | yes |
| effort | weeks | months | weeks |
| risk of a negative finding | none | **high, and informative** | moderate |
| R12's own recommendation | ≈ this | — | — |

---

## 6. What I would actually advise, and why it is not a recommendation

The decision turns on one number that does not exist yet: **whether the
ordering certifies when the level sign does not.** If it does, Option A is a
real paper and Option B is a research programme that could upgrade it later.
If the ordering is *also* inside the grid noise, then A is not available
either, and the two-asset section cannot appear in any form — which would be a
much more serious finding than the referee's report contemplates, because it
would mean the fragility is not calibration-dependence but non-measurement.

So the ordering's signal-to-noise is the decision variable, and Track A exists
to produce it. **Nothing should be chosen before it reports.**

Two things that should happen regardless of the branch:

- The **numerical statement** should be in the paper either way. "On the
  discretizations we can currently solve, the two-asset level response is not
  resolved" is a legitimate and useful sentence, and it is more defensible than
  the current framing, which invites the reader to weigh a number against a
  precision it does not have.
- The **wealth-mobility validation** (R12 Major 1) is required under every
  option, because it disciplines the one-asset mechanism that all three retain.
- The **identification ledger** (R12 Major 2 items 1–3, now built) is required
  under every option for the same reason, and it has already returned an
  adverse verdict that does not wait on Gate 11: five internally solved
  parameters against three targeted moments, and the two parameters with no
  external target at all — φ and `bbar_liq` — are exactly the two that force
  WHtM ≡ 0.

These two are the only items here that are unblocked, unambiguous, and
load-bearing in every branch.

**The ledger sharpens Option B specifically.** §3 already noted that changing φ
or the adjustment technology is not a purely numerical refinement. The ledger
adds the reason it is worse than that: φ has *no external target*, so a
re-engineering pass that moves φ until the grids decouple is choosing an
unidentified parameter to make a numerical problem go away. Whatever comes out
would be a different economy selected by its numerical convenience, and a
referee who has already named φ as decisive would say so. If Option B is taken,
φ must be pinned by a stated external moment **before** the re-engineering, not
after — and the natural candidate is the WHtM share it currently sets to zero.

---

## 7. Status

| item | state |
|---|---|
| memo written | this file |
| Gate 11 evidence | preliminary; Track A not yet run |
| ordering signal-to-noise | **not measured — the decision variable** |
| identification ledger | built; verdict adverse and independent of Gate 11 |
| option chosen | **none.** Not mine to choose, and premature regardless |
