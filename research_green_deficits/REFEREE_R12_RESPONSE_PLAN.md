# Referee report R12 — triage and response plan

Recommendation received: **reject, encourage field-journal resubmission.** The
report is careful, largely correct, and in several places says what earlier
internal rounds had already concluded. This file converts it into work.

**Two findings first, because they change what is owed.**

---

## 0. Two claims in the report checked against the source

### 0.1 Minor 4 — the Proposition 5 inconsistency is REAL

The report says the manuscript describes Proposition 5 as relying on
approximate homogeneity in one place and as exact in another. Verified, and
they are the same proposition (`prop:financingdesign` is the 5th
`\begin{proposition}` in the file, at line 1640):

| line | text |
|---|---|
| 1243 | "Financing design (Proposition~\ref{prop:financingdesign}) uses an **approximate** homogeneity (exact only in the homothetic limit)." |
| 1666 | "**exact** local comparative static at a differentiable stationary equilibrium — **no homotheticity approximation is used**, an earlier version having imposed $d\tau_{ls}=-(1-D)\,d\vartheta$…" |

The status line at 1666 records that the homotheticity-based tax rule was a
**superseded** version. So line 1243 is stale: it describes the version that
was corrected. The fix is a one-line edit at 1243, and it is a strict
improvement to the paper's claim, not a concession.

### 0.2 Major 2 item 4 — the Prop 6 decomposition IS implemented

The report states the numerical Schur decomposition "has not yet been
performed", and quotes the manuscript's own line 1712: *"is the natural next
step and is not yet done."* The **manuscript sentence is out of date**.
`main_preferred_decomposition.m` computes every component by central
difference at lines 583–660:

```matlab
Fbq = (resid_b(P, q+hq, ...) - resid_b(P, q-hq, ...)) / (2*hq);
N   = Fba - Fbq*Fka/Fkq;   M = FbP - Fbq*FkP/Fkq;
rows(i,:) = [hr FbP Fbq Fba Fkq N -N/M];
```

with a step-size ladder and a G3 gate comparing the Schur prediction against
the solved finite difference.

So the correct statement is: **implemented, not yet certified.** It sits
downstream of the two-asset grid certification, which is the actual blocker.
The manuscript sentence at 1712 must be corrected either way — it currently
understates what exists.

---

## 1. Where the report agrees with work already done

Listing these is not point-scoring; it determines what is *new* work.

| report item | status here |
|---|---|
| Major 8 — "self-financing" misused for a household object | done in figure code (R11.1); prose pending |
| Major 8 — separate ν_reval, ν_dam, ν, L | already the accounting; the report endorses it |
| Major 9 — deficit experiment confounds timing with debt supply | agreed internally in R10; C1/C2/C4 built |
| Major 9 — consolidation surcharge to match terminal debt | **built**: ξ_t = a_ξ h_t, amplitude solved by `kv_solve_consolidation` |
| Minor 18 — no "timing threshold" until terminal debt matched | in `PAPER_SAFETY_PATCH_R11.md` §C |
| Major 4 — ordering is the robust claim, not the level sign | in `PAPER_SAFETY_PATCH_R11.md` §A |
| Major 10 — demote multiplicity, insulation, optimal-μ, NK | overlaps the R9 demotion map |
| Major 11 — sign certification vs residual floor | Gate 11 + Track A/B |
| Minor 8 — nominal vs real program displayed together | exists (Appendix F.6, `tab:regimesreal`) |

**A correction the report needs:** it says the manuscript "has not completed
the numerical Schur-complement decomposition promised by Proposition 6". The
code exists; certification does not. Different remedy, different timeline.

---

## 2. Built in response to this report

| file | referee item | what it does |
|---|---|---|
| `solve_hank_dtpl_transition.m` (`opts.xi_index`) | Major 5 | partial indexation $G_{g,t}=\bar G_g (P_t/\bar P)^\xi$ |
| `main_partial_indexation.m` | Major 5 | ξ sweep with the ordering tested at each ξ |
| `kv_wealth_mobility.m` | **Major 1** | liquid-wealth transition matrices, bin-level accumulation, half-life of the redistribution |
| `main_identification_ledger.m` | **Major 2, items 1–3** | parameter ledger, order condition, untargeted-moment census (§2.3) |

### 2.1 Partial indexation nests both existing regimes exactly

$g_t=(\bar G_g/\bar P)(P_t/\bar P)^{\xi-1}$ with $\bar P = P^{\text{green}}_\infty$:

| ξ | reduces to | max abs difference |
|---|---|---|
| 1 | real mandate, $\bar G_g/P^{green}_\infty$ | 0 |
| 0 | nominal appropriation, $\bar G_g/P_t$ | 0 |

Verified arithmetically. The legacy branches are untouched and are still taken
whenever `xi_index` is absent — which is what keeps the D11 parity test
meaningful. `main_partial_indexation` runs that endpoint identity as a **gate**
before the sweep: if the partial rule does not reproduce the endpoints it is
not a generalization of the manuscript's experiment, and nothing downstream
means anything.

**The referee's own observation sharpens the test.** They note the nominal and
indexed paths are nearly identical on the equilibrium path. If the two
endpoints barely differ, the interval between them cannot carry a first-order
result — so the likely finding is that multiplicity and anchor insulation are
limiting cases, exactly the disposition proposed. That is worth establishing
rather than asserting.

### 2.2 Wealth mobility — the falsification test, model side

The report names this as "the single experiment that could most seriously
falsify the paper", and the arithmetic is why: **+3.44 distributional against
+0.34 direct, with the marginal direct term at −0.07, i.e. the opposite
sign.** The headline is a long-run mobility result wearing precautionary-saving
clothing, and MPC evidence disciplines only the small term.

`kv_wealth_mobility` produces the model side in a form a panel statistic can
be laid against: a K×K transition matrix over liquid-wealth quantile bins,
built with the **same lottery split the forward iteration uses** (snapping to
the nearest node would understate mobility by exactly the within-cell movement
the channel consists of), plus bin-level accumulation, retention, one-step
up/down mobility, the Shorrocks index, and a **half-life** for the
redistribution.

The half-life matters independently: a mechanism that takes eighty years is not
disciplined by the same evidence as one that takes five, and the manuscript's
distributional term is a stationary-distribution object with no stated horizon
at all.

**This is not validation.** It fetches no external data. Nothing from it may be
called disciplined until it is compared against actual panel series.

### 2.3 The identification ledger — and what it settles without a run

`main_identification_ledger` is read-only over the stored calibrations and
solves nothing, which is the point: it audits the calibration the paper
actually uses rather than reporting a fresh solve. It runs in seconds.

Five things it establishes that do **not** depend on Gate 11, because they are
statements about targets rather than about resolution:

1. **The order condition fails.** Five internally solved parameters — β
   (one-asset), β and χ_b (two-asset), and the superstar pair (mult, p_in) —
   against **three** distinct targeted moments: debt/income = 1.10, the direct
   liquid holding S_b = 0.30, and the top-1% wealth share. Under-identified,
   independent of any discretization.

2. **ι_H is not a second moment.** It is 0.30/1.10 by construction — an
   algebraic consequence of two targets already counted. Classing it as a
   calibrated parameter would manufacture identification out of arithmetic.

3. **β and χ_b chase the same moment in two different economies.** χ_b is
   fitted in the *frictionless* companion (λ = 1) to S_b = 0.30 and then
   transplanted into the infrequent-adjustment economy, where β is refitted to
   S_b = 0.30. The transplant has a stated reason — the friction roughly
   doubles precautionary wealth, putting the level out of χ's reach — but it is
   a modelling choice, not an identification, and the moment is counted once.

4. **The superstar state is 2 parameters against 1 moment**, with p_out held
   fixed and (mult, p_in) selected off a 3×3 grid by proximity to a single
   top-1% target. A one-dimensional family reproduces any given top-1% share.
   The fix is nearly free: `wealth_concentration_fit` already computes the
   top-10% share and the wealth Gini, so adding a second concentration moment
   costs no extra solve. **This is the cheapest identification improvement
   anywhere in the project.**

5. **The two parameters with no external target are the two that govern the
   moment the model cannot reproduce.** φ (`div_payout` = 1) and `bbar_liq`
   both carry the DECL class, and between them they force WHtM ≡ 0 — a
   *structural* zero, not a calibration outcome, so it fails against any
   positive external value without needing the number transcribed. R12's Major
   2 names φ as quantitatively decisive; the ledger shows why that is not a
   coincidence.

The untargeted-moment census (section C of the ledger) carries the model column
filled from `twoasset_ownership_kv.mat` and a **deliberately empty data
column**, with the source named in each slot — the same rule as
`main_validation_mobility`. Every row is stamped UNCERTIFIED, because the model
column comes from the two-asset block.

**Where this leaves Major 2.** Item 4 (the Schur decomposition) is implemented
and blocked on Gate 11. Items 1–3 are now answered, and the answer is *adverse*:
the preferred calibration is under-identified and its worst-fitting moment is
governed by its least-identified parameters. That is worth stating in the paper
in the ledger's own terms rather than waiting to be told again.

---

## 3. Triage of the eleven major comments

| # | comment | verdict | disposition |
|---|---|---|---|
| 1 | nominal-liability demand not externally identified | **accept in full** | machinery built; external comparison outstanding — the gating item |
| 2 | two-asset sign restoration is fragile | **accept, with one correction** | Schur decomposition exists; certification blocked. Ledger **built** (§2.3); items 1–3 answered, adversely |
| 3 | price-level regime needs institutional justification | **accept** | large; regime menu is a separate paper-scale exercise |
| 4 | ordering, not "green disinflation", is the result | **accept** | already the R11 safety patch; makes it the organizing claim |
| 5 | nominal appropriation creates the feedback mechanically | **accept** | **built** (§2.1) |
| 6 | capitalization rests on extreme credibility | **accept** | needs Markov reversal + finite duration; not built |
| 7 | preferred model does not answer the title | **accept** | requires two-asset transition with damages moving; blocked on certification |
| 8 | accounting still easy to misinterpret | **partly accept** | ν terminology done in code; foreign/central-bank in the core block is new |
| 9 | deficit experiment confounds timing and debt | **accept; already agreed** | C1/C2/C4 + surcharge built; equal-PV and equal-terminal-real cases to add |
| 10 | extensions should not be coequal | **accept** | demotion map exists |
| 11 | numerical accuracy not shown for sign-sensitive transitions | **accept** | Track A/B + Gate 11; transition Euler errors are a genuine gap |

### The one place the report understates the problem

Major 11 asks for numerical uncertainty relative to each price movement. Our
own diagnostics are worse than the report knows: a **pure grid change** (`bmax`
12→96) moved the two-asset tree price by **7.7%** while the entire financing
signal across α is **0.6%**. Signal an order of magnitude below one axis of
grid noise. The report infers fragility from the calibration; the sharper
statement is that on the current discretization the two-asset level sign is
**not yet measurable**, independent of calibration. That is why Gate 11
normalizes by |ΔP| rather than by P.

### Where I would push back

**Major 6 — "partly mechanical asset-pricing logic".** Fair for the *fact* of
capitalization. But the paper's claim is comparative: the DTPL environment and
a Phillips-curve environment price the same announcement with **opposite
signs**. That is not mechanical, and it survives the credibility critique,
which affects magnitude rather than sign. The credibility experiments are still
worth running; the framing should be that they bound the magnitude.

**Minor 25 — "remove repeated claims that the price level prices the news".**
Agreed as to repetition. But it should be stated once *precisely*, because it
is the observable distinction from a Phillips-curve economy.

---

## 3a. Status of the code the report's concerns rest on

The report treats the numerical apparatus as a source of doubt. Two of the
three parity legs are now settled, which narrows what is actually in question.

| test | result |
|---|---|
| **D10 comparison A** — pre-refactor `bf0a4e8` vs current script | **PASS: 40 fields exact, 0 FAIL** |
| **D11 comparisons A/B/C** — transition solver, all three legs | **PASS: 48 fields exact**, `neutrality_gap` exactly 0 |
| D10 comparisons B/C — script vs callable | driver defect, fixed in R11.11 (leg 3 was given the script's outputs as its inputs) |

So the **refactor is not a source of numerical doubt**, and the transition
solver reproduces the pre-refactor commit bit-for-bit including its residual
history. Nominal neutrality — $P_\infty^{d}/P_\infty^{b} = \kappa_\infty$ —
holds to zero relative gap, which is the sharpest available internal check
that the debt recursion and the terminal pin are mutually consistent.

**This does not answer the report.** Parity says the code computes what it
computed before; it says nothing about whether the discretization resolves the
economics. The FAST transition paths are NOT CONVERGED (T=60, maxit=80), and
the two-asset grid noise still exceeds the financing signal. Major 11 stands
in full. What is now excluded is the possibility that the refactor introduced
the problem.

## 4. Ordering

Nothing here jumps the queue ahead of parity and certification. The report's
Essential item 7 (certify numerical signs) is a **precondition** for its items
2, 3 and 4, not a parallel task: decomposing a signal smaller than the grid
noise produces a decomposition of noise.

1. **Now (running):** D10/D11 parity → Track A/B certification → Gate 11.
2. **Unblocked, no MATLAB:** Prop 5 line-1243 correction; the line-1712
   correction; the safety patch.
3. **Unblocked, needs a run:** the identification ledger (seconds, read-only);
   partial indexation; wealth mobility.
4. **Blocked on Gate 11:** Prop 6 decomposition certification; the full
   two-asset transition with damages moving (Major 7).
5. **Paper-scale, needs a decision:** regime menu (Major 3), distortionary
   instruments (Major 4), credibility (Major 6).

**If Gate 11 fails**, items 2 and 7 cannot be answered in this model at this
resolution, and the honest response to the report is the narrower paper it
proposes — built on the certified one-asset economy and the ordering — rather
than a defence of the two-asset level sign. That branch is the subject of
`TWO_ASSET_FAILURE_FALLBACK_MEMO.md`, which is owed and not yet written.

---

## 5. On the recommendation

The report's core judgement — that the level sign is calibration-dependent,
the dominant channel externally undisciplined, and the preferred model does not
solve the title experiment — matches what the internal rounds concluded before
this report arrived. The disagreement is narrower than the recommendation
suggests: it is about whether the ordering plus a certified one-asset economy
is a field-journal paper or a general-interest one, not about whether the
current draft supports its headline.
