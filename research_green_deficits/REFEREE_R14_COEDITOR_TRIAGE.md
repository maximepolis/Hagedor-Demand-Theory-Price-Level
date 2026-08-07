# R14 co-editor brief — triage, implementation record, and author decisions

Received 2026-08-07. The brief (sections A–AF) instructs a full co-editor
pass: page budget, exhibit budget, visual redesign, title/abstract/intro
rewrites, novelty threat map, mechanism stress tests, and a claim-discipline
audit. This document maps every section of that brief onto this repository:
what R13 work already satisfies it, what was implemented now, what is
scheduled, and what only the author can decide. It deliberately does NOT
duplicate `PAPER_ARCHITECTURE_R13.md` (the restructure plan) or
`CLAIM_STATUS_R13.md` (the claim register); it points into them.

Honesty rule carried over from every earlier round: nothing below asserts a
literature fact that was not checked, quotes a number that was not computed,
or upgrades a claim the register holds at WP.

---

## 1. Where the brief is already satisfied (do not redo)

| Brief section | Existing asset | Status |
|---|---|---|
| C (executable criticisms) | `REFEREE_R12_RESPONSE_PLAN.md` — every R12/R13 item carries a named driver and a decision rule | standing practice |
| F (break the mechanism) | Gate-11 certification (Track A complete: ordering certifies, magnitude fails 7.5×), D10/D11 parity, provenance audit, sign-map sweep, credibility surrogate | run; two-asset level sign remains uncertified and is *labelled* so |
| G (tax-elasticity scrutiny) | `main_identification_ledger` (order condition FAILS 5-vs-3 and is *answered* per block: V1 measured, V6 transplant, V2 structural zero); wealth-mobility validation table with four definition-robust gates | run |
| I (what is held fixed) | The fixed-real-program comparison exists as its own experiment; the C1/C2/C4 block states its held object (terminal debt) in the driver and now in the manuscript caveat paragraph | run; site-level sweep of remaining comparisons scheduled with the restructure |
| J (stationary vs transition) | The estimand split is R10-era discipline (`F_P` vs `F^{L-LS}_P` definitions, announcement vs stationary rows in the register) | standing |
| K (portfolio hierarchy A/B/C) | The manuscript's tiering (one-asset benchmark → linearized two-asset → ownership+KV) matches the requested hierarchy; the *identical-outcome-menu* requirement is a real gap → §4 below | partial |
| N (identification table) | `main_identification_ledger` produces exactly the requested table with the requested classes (NORM/EXT/CAL/DECL/NUM) plus verdicts V1–V7 | run |
| O (informative robustness) | Experiments 3, 4, 5, 10 on the brief's list are *already run* (fixed-real-program; matched-terminal-debt = C1/C2/C4 + timing frontier; damage-fixed two-asset transition caveat recorded; nominal-vs-indexed is the regime pair) | run |
| M (numerical audit) | Gate framework (gates 1–11), budget identities at 4e-14, parity harnesses, checkpointed certification | run for the one-asset chain; two-asset magnitude is the known failure |
| Z (policy-claim audit) | R10/R11 safety patches: "optimal-μ is never an inflation prescription", self-financing terminology, ratchet labels | applied |

The brief's warning "do not reward the paper for having many extensions" is
the R13 demotion map; `PAPER_ARCHITECTURE_R13.md` already moves multiplicity,
insulation, optimal-μ, NK, and aggregate risk out of the body.

## 2. Implemented in this pass (R11.34)

**Semantic figure styling (brief §T/§U).** `src/style_figure.m` already
enforced one typographic standard at export (fonts, weights, Okabe-Ito
colororder) — but by series *position*. Six plot files declared private RGB
constants, so a colour could change meaning between exhibits. New
`src/regime_style.m` is the single colour-by-*meaning* registry (benchmark
grey, program green, lump-sum blue, levy vermillion, rebate purple,
deficit/joint amber, timing sky, supply blue / demand vermillion for the
market diagrams), each with a B/W line style and marker; it errors on an
unknown meaning so a new figure cannot invent an encoding. All six plot
files now draw their constants from it — plot calls untouched, so restyling
cannot change what any figure reports. Regenerating figures picks this up
with no other action.

**Exhibit budget (§X).** Counted: the main text currently holds **5 figures
and 5 tables** (before `\appendix`) — already inside the brief's 6–8/6–8
budget. The R13 restructure achieved this; no further exhibit cuts are owed.
What is still owed from §U is caption discipline: each caption stating
experiment / fixed objects / moving object / unit. The ladder caption now
does (R11.33); the remaining four figure captions get this treatment
together with the §W restructure, not before (editing captions on exhibits
that may move or merge is wasted work).

**Page budget (§A/§W).** The brief's default is 35–40 pages;
`PAPER_ARCHITECTURE_R13.md` targets 40–45 with a section-by-section cut
list. Decision recorded there rather than re-litigated here: hit 40 first
via the existing cut list; the further 40→35 compression is only worth
doing against a named journal's actual limit — set `[TARGET JOURNAL]` and
the last five pages come out of §5 (calibration prose → the ledger table)
and §7 (transition mechanics → appendix), per the architecture doc's
COMPRESS entries.

## 3. Author decisions (drafted here, not applied)

### 3.1 Title (§S) — ten options, ranked

The paper's strongest identified contribution (per the register: RO on the
instrument ordering, QV on the timing sign, PP on the incidence formula) is
**financing incidence for productive public spending under demand-theoretic
price determination**, with adaptation as the flagship application. Titles
lead with that; "green" survives as application, not as subject.

1. *The Financing of Public Investment and the Price Level* — (macro,
   monetary) shortest true title; loses incidence.
2. *Who Pays for Public Investment? Financing Incidence and the Price Level
   in Incomplete Markets* — (public finance, macro) keeps the question-form
   hook, drops "green" from the headline.
3. *Tax Incidence Through the Price Level: Public Investment in
   Incomplete-Markets Economies* — (public finance) names the mechanism as
   the subject.
4. *Financing Public Adaptation: Tax Choice, Debt Revaluation, and the
   Price Level* — (climate, macro) honest scope if the climate framing is
   kept primary.
5. *The Price of Green Spending: Financing Choice and Nominal Debt
   Revaluation* — (climate, monetary) punchy; "price" pun may read as
   inflation-only.
6. *Nominal Debt, Real Programs: The Incidence of Public-Investment
   Finance* — (macro) the nominal/real contrast is the paper's engine.
7. *Public Investment When the Price Level Clears the Bond Market* —
   (monetary) mechanism-first; loses distribution.
8. *Precautionary Demand, Public Debt, and the Incidence of Green
   Investment* — (macro, HANK audience).
9. *Safe-Asset Demand and the Fiscal Incidence of Public Investment* —
   (macro/finance) connects to the safe-asset literature the referee keeps
   invoking.
10. Current title, retained — defensible if the climate application stays
    the selling point; it is the longest of the set and the only one with
    two subtitles' worth of nouns.

Recommendation: 2 for a public-finance outlet, 1 or 7 for a monetary
outlet, 4 if the climate framing is deliberately kept. This interacts with
the **held title patch** from R11 — decide both at once.

### 3.2 Abstract (§Q) — three drafts ≤ 180 words

**A (mechanism-first).** Who bears the burden of public investment when the
price level clears the market for nominal government debt? In an
incomplete-markets economy, the tax instrument financing a permanent public
program shifts precautionary demand for nominal liabilities and therefore
their real value: financing choice moves the price level. We derive an
incidence formula separating this financing-induced demand shift from the
determinacy margin, and show the ordering across instruments is robust
while the level response is portfolio-dependent. Lump-sum finance lowers
the price level and transfers resources to bondholders; a proportional levy
is more inflationary; a levy-plus-rebate is more progressive. A
fixed-real-program comparison isolates the channel; a matched-terminal-debt
decomposition shows delayed taxation alone reverses the announcement sign,
though two-thirds of the headline response is the associated debt ratchet.
Public adaptation investment is the flagship application: its inflationary
and distributional effects cannot be evaluated separately from its
financing and from who holds nominal public debt.

**B (quantitative/policy).** [Same skeleton; leads with the announcement
capitalization figure and the instrument ordering magnitude, quotes
`\OrdOne` and the timing/ratchet split via macros; only defensible AFTER
Gate 11 or under the ordering-only rescoping — do not adopt while level
magnitudes are uncertified.]

**C (public-finance framing).** Classical incidence asks who pays for
public spending given prices; with nominal government debt, the financing
choice itself moves the price that revalues the public's liabilities. We
study incidence through this channel in an incomplete-markets economy where
the price level clears the bond market... [rest as A from "We derive".]

Recommendation: A. It is the current abstract's content with the
R11.33-licensed timing sentence added and the extensions catalogue removed.
B is blocked by the register until certification.

### 3.3 Introduction (§R) — outline the architecture doc should absorb

Page 1: the policy question (who pays for a permanent public program when
its financing moves the price level), the one-sentence mechanism, and the
lump-sum result stated in words. Page 2: the incidence formula in one
display plus the instrument ordering; the fixed-real-program experiment as
the identifying comparison. Page 3: what is new against the three closest
literatures (DTPL: mechanism inherited, appropriations/financing/feedback
added; HANK fiscal incidence: price-level margin added; safe-asset demand:
fiscal-incidence use). Page 4: the two-sentence deficit/timing result
(per `PAPER_ARCHITECTURE_R13.md` §3, updated R11.33) + honest scope
paragraph (two-asset level sign uncertified; ordering is the robust
object). Page 5: roadmap, one paragraph. This is a *tightening* of the
architecture doc's §1 spec, not a rival to it.

## 4. New work the brief adds (scheduled, with what each buys)

1. **Common outcome menu across Models A/B/C (§K).** One table skeleton
   (P, dlnP, bond demand, real debt, revaluation, tax burden, group
   welfare, announcement response) filled per tier, `\pendingnum` where a
   tier's number is uncertified. Buys: the portfolio-robustness claim
   becomes *visually* checkable, and the uncertified cells become visible
   instead of prose caveats. Cost: one table, numbers already in `.mat`s.
   → build after the frontier rerun lands.
2. **Novelty threat map (§D/§E).** Requires literature access; nothing in
   this repository can honestly claim to have searched 2025–2026 working
   papers. Fabricating a threat map would be worse than none. → author
   supplies or commissions the sweep; the register then absorbs it. The
   four missing bibliography entries (Cronin–Fullerton–Sexton, Bradt–Aldy,
   fiscal foresight, ECB) are still open for the same reason.
3. **Debt-ownership experiment (§O item 7)** — move bond-ownership
   concentration independently of wealth (ι_H sweep exists as a parameter;
   the experiment is a driver flag away). Buys: separates "who holds debt"
   from "who is rich" in the incidence result. Referee non-negotiable 8
   (portfolio block) is the user's held decision; this experiment is its
   cheapest component.
4. **Sentence-level edit pass (§AC).** 30–50 edits are only worth making on
   text that survives the §W restructure. Sequence: restructure → caption
   discipline → sentence pass. Doing it now double-edits paragraphs the
   architecture doc already moves or deletes.
5. **Status-paragraph consolidation (§L).** The brief's "avoid repeated
   Status: paragraphs; use one compact claim-status appendix" matches the
   architecture doc's existing instruction; noted there as reinforced.

## 5. What the brief gets wrong for this paper (recorded, with reasons)

- "Require a resolution ladder n_a ∈ {250, 500, 1000}" — the one-asset
  chain already runs finer than this and the binding accuracy problem is
  the *two-asset* grid, where the ladder exists (Track A) and the honest
  answer is that refinement does not tighten Gate 11. Re-running a
  one-asset ladder would manufacture reassurance where the problem is not.
- "Combine four panels into one financing-incidence mega-figure" — the
  incidence decomposition and the welfare bars carry different fixed
  objects; merging them under one caption invites exactly the
  what-is-held-fixed confusion §I forbids. Merge only the pairs that share
  an experiment.
- "Decide independently what the strongest contribution is" — done in R13:
  the register's answer (ordering RO, formula PP, timing QV-in-kind) *is*
  the strongest supportable contribution, and it is what the architecture
  doc already leads with. The brief's own final challenge ("which result is
  stronger than the author realizes") has a repository answer: the
  **validated joint frontier + provisional timing frontier pair** — a
  measured decomposition of a policy threshold into timing and ratchet
  components, which no cited paper does. It should be a headline exhibit
  once the timing bracket closes, not a §7 caveat.
