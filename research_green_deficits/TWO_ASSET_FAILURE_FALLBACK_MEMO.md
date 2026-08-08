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

### 1.1 A second, independent measurement — from the D10 parity run

The FAST leg of the D10 parity run (2026-08-04) solved the identical
experiment on a coarser grid, with β recalibrated to the same target on each
grid. That makes it a **Track-B-style** comparison — calibration robustness,
not frozen-Θ̄ discretization error — but it is a clean paired measurement of
the same object Gate 11 is defined on, and it is the first one available.

| | benchmark 60/34/150 | FAST 40/22/100 |
|---|---|---|
| β (recalibrated to S_b = 0.30) | 0.87396 | 0.87404 |
| lump-sum $d\ln P$ | −0.0226 | −0.0108 |
| levy $d\ln P$ | +0.0137 | +0.0116 |
| **ordering gap $\Delta\ln P = $ levy − lump-sum** | **0.0363** | **0.0224** |
| $q$ under lump-sum | 1.5370 | 1.5878 |
| $q$ under levy | 1.5133 | 1.5878 |
| **$\Delta q$ across the financing experiment** | **−0.0237** | **0.0000** |

Two things follow, and they point in opposite directions.

**The ordering survives both grids.** The sign contrast holds at 60/34/150 and
at 40/22/100: the levy is more inflationary than the lump-sum tax on each. This
is the first evidence that the *ordering* is robust to a discretization change
that moves the levels substantially — which is the asymmetry §2 relies on and
which had not previously been measured.

**The magnitude does not.** Grid-induced movement in the ordering gap is
|0.0363 − 0.0224| / 0.0363 = **0.38**, against Gate 11's threshold of 0.10. The
lump-sum level alone moves by **52%**. On this pair the level is not resolved,
and the gap is resolved only in sign.

**And the tree market is not resolved at all on the coarse grid.** At FAST,
$q$ is *identical to four decimals* under α = 0 and α = 1, while at the
benchmark it differs by 0.0237. The financing instrument's effect on the tree
price is entirely below the coarse grid's resolution. That is not a magnitude
problem — it is a zero where the benchmark finds a nonzero. It bears directly
on Proposition 6: $F_{k\alpha}$ is one of the Schur components, and a grid on
which it is numerically zero cannot support the decomposition at all.

**Caveats, stated so this is not over-read.** This is FAST-vs-benchmark, not
the certification ladder: the two runs differ in `nb`, `nk`, `nx`, `nac` and
`nsh` simultaneously, so it attributes nothing to a single axis, and β was
recalibrated on each grid. It does not replace Track A. It does establish that
the concern is not confined to the `bmax` axis, and it puts a second number
next to the 7.7% one.

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
out. That asymmetry is what makes Option A viable — and §1.1 now shows the
ordering surviving a grid change that moves the levels by half, which is the
first direct evidence for it rather than an argument from structure.

---

## 1.2 TRACK A HAS NOW RUN. The decision variable is measured.

Full 3x3 matrix, narrow family, frozen parameters, 4.4 hours, 2026-08-05.
All nine cells solved and produced a dP. **No cell certified** — every one fails
the residual gates (1, 2, 3, 3.1) and the boundary gates (7, 8, 9, 9.1).

| | nk=17 | nk=22 | nk=28 |
|---|---|---|---|
| **nb=30** | +0.027451 | +0.025260 | +0.034802 |
| **nb=38** | +0.025042 | +0.020961 | +0.028821 |
| **nb=48** | +0.042625 | +0.037195 | +0.029845 |

**ORDERING: certified in the only sense available. 9 of 9 cells give dP > 0.**
The levy is more inflationary than the lump-sum tax on every discretization
solved, across a 2.3x spread in the magnitude. This is the number
§6 said did not exist and called the decision variable.

**MAGNITUDE: fails Gate 11 by a factor of 7.5.**

| statistic | value | gate |
|---|---|---|
| range / \|median\| | **0.752** | < 0.10 required, < 0.05 preferred |
| s.d. / \|mean\| | 0.225 | — |
| median dP | 0.028821 | — |

### The sharper finding: refinement does not tighten it

A failing gate could mean "not yet refined enough". This matrix says otherwise.
Spread of dP **within each nb row**, as the b-grid refines:

| nb | spread as % of that row's median |
|---|---|
| 30 | 35% |
| 38 | 31% |
| 48 | **34%** |

Refining the liquid grid by 60% does not reduce the dispersion at all. The
sequence is also **non-monotone in both dimensions** — dP falls then rises in
nk at every nb, and falls then rises in nb at every nk. There is no convergent
sequence here to extrapolate.

The k dimension is where the action is: the spread across nb is 64% at nk=17,
64% at nk=22, and 20% at nk=28. That is consistent with the tree market being
the binding block, as the FAST diagnostic in §1.1 already suggested when q was
identical to four decimals across the financing experiment.

**But the finest cell is not usable.** At (48, 28), alpha = 1 returns a tree
residual of 0.0902 relative to Kbar — 9% — and a residual **4.14 times debt
service**. That is a solver breakdown at the finest grid, not a refinement of
it, so the one cell that makes the nk=28 column look tight is the one whose
levy solve failed. Excluding it moves range/|median| to 0.770; the verdict does
not depend on it either way.

### Two further diagnostics worth recording

**Target drift, on a matrix where parameters are FROZEN.** S_b at alpha = 0
ranges 0.2988 to 0.3137 against a 0.30 target — up to **4.6% off**. Freezing
parameters does not freeze the moments, because the node count moves them. The
largest dP (0.042625) sits in the cell with the largest drift (+0.0137), so
part of the dP spread is calibration drift, not discretization alone, even
inside Track A.

**MULTIPLE_ROOTS in all nine cells.** Most spreads are tiny (1e-6 to 1e-4), but
at (38, 17) the P spread across starts is 2.69e-03 — roughly a tenth of dP
itself. Root selection is therefore not negligible relative to the signal in at
least one cell. Three cells additionally lost the cold_lo start to
SOLVER_SCATTERED.

### What this settles

§6 said: *"The decision turns on one number that does not exist yet: whether
the ordering certifies when the level sign does not."* It now exists.

- The **ordering** is robust: 9/9, across grids that disagree about the
  magnitude by a factor of 2.3. This is exactly the asymmetry §2 predicted —
  the ordering compares two solves on the same grid and the common
  discretization error differences out.
- The **level** is not resolved and, on this evidence, will not be resolved by
  refining the current discretization. That is Option B item 2 — the adjuster's
  discrete argmax putting a floor under the residual — and it makes Option B
  **necessary rather than optional** if the level is ever to be reported.

**Option A is now supported by measurement rather than by argument.** The
narrow paper reports the financing ordering and declines the level. Nothing
here forces that choice, but it is no longer a choice made in ignorance.

---

## 1.3 THE WIDENED FAMILY HAS NOW RUN. The last defence is measured and fails.

Track A's narrow-family verdict rested on one open question: its refinement
held the grid BOUNDS fixed and varied only node counts, so it could not
distinguish a *density* problem from a *boundary* problem. The widened
family authorised 2026-08-04 — bmax 12 → 96 (x8), kmax 60 → 360 (x6), node
counts scaled x2.38 / x2.11 to hold density constant — tests that directly.
Run 2026-08-08. **The first cell settles it, and the remaining eight cannot
overturn it.**

Cell nb=72 nk=36, against the narrow-family pre-flight:

| gate | narrow | widened | verdict |
|---|---|---|---|
| 7 liquid top-two-node mass | 0.00275 | 0.000246 | still FAILS 1e-4, improved 11x |
| 8 illiquid top-two-node mass | 0.00143 | — | **PASSES** |
| 9 liquid highest occupied node | 1.0000 | **1.0000** | still FAILS, *unchanged* |
| 9.1 illiquid highest occupied node | 1.0000 | — | **PASSES** |

**The illiquid truncation was an extent problem and widening fixed it. The
liquid truncation is not, and widening did not.** The gate pair was built to
tell those apart and it did: `kv_boundary_mass`'s own header warns that
"widening a grid mechanically shrinks the top-two-node mass, so a small ks on
its own proves nothing; ks small AND ko well below 1 is a distribution with
interior support, while ks small and ko ~ 1 is a distribution still leaning on
the wall through a thinner slice of it." Gate 7's 11x improvement is exactly
the mechanical shrinkage; gate 9 unchanged at 1.0000 means there is still mass
above 1e-8 at b = 96, eight times the original ceiling. With the superstar
state (ergodic mass ~0.003, multiplier 12) the liquid tail is genuinely long,
not clipped — this is not a ceiling you can afford to raise.

Two further findings, either of which would disqualify the widened matrix on
its own:

- **Target drift +0.1537 on a 0.30 target.** S_b at alpha=0 is 0.4537: the
  widened economy holds 45% of income in liquid assets, not 30%. On the narrow
  family the drift was at most 4.6%. The frozen calibration does not sit at its
  targets here, so the cell's dP is not the calibrated economy's dP and a
  spread across cells would not be a discretization measurement. The driver
  reports this rather than assuming it small, which is why it is visible.
- **The residual gates fail too**, by one to two orders of magnitude: bond
  residual/S_b = 4.8e-06 against 1e-06, tree residual/Kbar = 1.31e-04,
  max residual/tax revenue = 2.5e-03 against 1e-05. Setting truncation aside
  entirely, this grid does not clear markets to tolerance.

### What this settles, and what it does not

It closes the question §6 said nothing should be chosen before: the ordering
certifies on the narrow family while the level does not, and the one remaining
explanation for the level failure — that 0.752 was a boundary artifact rather
than a resolution limit — is now tested and rejected. **Option A is supported
by two independent measurements rather than one.**

It does NOT reject Option B in general. What it rejects is Option B's cheapest
form: buy certification with a bigger grid. Anything else under that heading
is a change of method, not a change of parameters, and is a research programme
rather than a revision.

### A resolution that must NOT be taken

The pre-flight offers a second way out: score gates 7-9 once for the family
rather than per cell, on the ground that they are properties of the extent and
Track A holds extent fixed. As bookkeeping that is defensible. As a route to
certification it is not, and it should be refused explicitly so nobody
rediscovers it as a shortcut: the liquid distribution genuinely leans on the
wall at eight times the ceiling, and scoring the gate once does not move the
mass. It would convert a demonstrated truncation failure into a passed
certification by redefinition. No threshold and no scoring rule may change on
the strength of a run that failed.

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
| ordering signal-to-noise | **MEASURED, §1.2: 9/9 cells same sign. Ordering robust.** |
| level signal-to-noise | **MEASURED, §1.2: Gate 11 = 0.75 against a 0.10 gate, and refinement does not tighten it** |
| identification ledger | built; verdict adverse and independent of Gate 11 |
| option chosen | **none.** Still not mine to choose — but no longer premature: the decision variable has reported |
