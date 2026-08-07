# PAPER_ARCHITECTURE_R13 — cutting the manuscript to the referee's 40–45pp main paper

**Target file.** `research_green_deficits/paper/green_deficits_price_level.tex`
(5776 lines; `\begin{document}` at 267, `\appendix` at **3330**, `\bibliography` at 5774,
`\end{document}` at 5776).

**Correction to the brief.** The brief says "`\appendix` is around line 3325".
The actual `\appendix` is at **line 3330**; 3329 and 3331 are the `% ===` rule
comments that bracket it. Every line number in this document was read out of
the file, not inferred.

**Nothing in this plan deletes scientific content.** Every block marked
MOVE-TO-APPENDIX keeps its full text, its numbers, its labels and its status
lines; only its position changes. Blocks marked CUT are cut *from the main
body* and land in the appendix as well, except in the five places explicitly
marked `CUT-DEAD` (repeated cross-reference sentences that become false once
the material moves).

---

## 0. Measurement basis, and what is an estimate

**I could not compile.** There is no `pdflatex`/`latexmk` in this environment
and no built PDF anywhere in the tree (`find . -name "*.pdf"` returns only the
four source papers in the parent directory). **Therefore every page number
below is an estimate, not a measurement.**

**How the estimates are built.** For each `\section`/`\subsection` I counted
non-comment characters in its line range, and normalised so that the whole
document (line 267 to end, 320 871 characters) equals the 105 pages the brief
states. That yields **3056 characters per page**. The document is
`article, 12pt`, `margin=1.1in`, `\onehalfspacing` (preamble lines 11, 13,
247), which is consistent with a number in that neighbourhood, but the
anchor is the brief's own 105, not an independent measurement.

**Known bias of this method, stated so nobody trusts it too far.** Character
share *under-weights* figures and tables: a full-page figure contributes
almost no characters. The main body carries four `pfigguard` figures
(2066, 2157, 2343, 3203), one TikZ figure (1129–1199), five `table`
environments (1981, 2105, 2275, 2739, 2940) and two unlabelled inline
`tabular`s in §6 (2504–2513, 2523–2534). So the
main body's true page count is **higher** than the 58.5 estimate below,
probably by 4–8 pages. That cuts the same way as the plan: the cuts below
are, if anything, slightly under-scoped rather than over-scoped.

**Estimated present split**

| block | lines | est. pp |
|---|---|---|
| front matter (title/abstract/keywords) | 267–300 | 0.5 |
| **main body** | **301–3329** | **58.5** (+ figure/table overhead) |
| **appendix** | **3330–5773** | **45.5** |
| bibliography | 5774–5775 | — |

**Target.** Main body 40–45pp. Net movement required: about **17 estimated
pages out of the body**, *minus* about **2.8 estimated pages pulled forward
from the appendix into the new Section 4**, i.e. roughly **20 pages of body
text relocated** and ~2.8 pages relocated the other way.

---

## 1. Complete structural map with disposition

`K` = keep in main body · `A` = move to online appendix · `M` = merge/compress in place ·
`F` = move **forward** (appendix → main body) · `X` = cut-dead (sentence is false after the move)

### 1.1 Main body

| lines | len | est. pp | current heading | → target | disp. |
|---|---|---|---|---|---|
| 301–570 | 270 | 5.8 | `\section{Introduction}` `sec:intro` | §1 | M (to ~4.0) |
| 571–732 | 162 | 3.5 | `\section{Related literature}` `sec:literature` | Appendix (new §A.0) | **A** |
| 733–766 | 34 | 0.7 | `\section{Model}` `sec:model` | §2 | M |
| 767–815 | 49 | 0.8 | `Households` `subsec:households` | §2.1 | K |
| 816–939 | 124 | 2.1 | `The climate sector` `subsec:climate` | §2.3 + appendix | **split** |
| 940–972 | 33 | 0.5 | `Government` `subsec:government` | §2.2 | K |
| 973–1077 | 105 | 1.8 | `Equilibrium` `subsec:equilibrium` | §2.4 | K, trim |
| 1078–1201 | 124 | 2.0 | `The mechanism, in one picture` `subsec:mechanism` | §2.5 | M (fig K, prose −60%) |
| 1202–1249 | 48 | 0.9 | `\section{Theoretical results}` `sec:theory` | §3 preamble | M |
| 1250–1287 | 38 | 0.6 | `Preliminaries` | §3.1 | K, trim |
| 1288–1317 | 30 | 0.5 | `Determinacy` | §3 one-paragraph note | **A** (prop. only) |
| 1318–1409 | 92 | 1.7 | `The real fixed point…` `subsec:neutrality` | §3.2 | K, trim |
| 1410–1520 | 111 | 2.0 | `The incidence formula` `subsec:suffstat` | §3.3 | K, trim |
| 1521–1632 | 112 | 2.3 | `Resource, fiscal, and revaluation accounting` | §3.4 | K, trim |
| 1633–1782 | 150 | 2.7 | `Financing design…` `subsec:financingdesign` | §3.5–3.7 | K, trim |
| 1783–1807 | 25 | 0.5 | `\section{Quantitative analysis}` `sec:quant` | §5 preamble | rewrite |
| 1808–2079 | 272 | 5.5 | `Why the price level moves…` `subsec:safeasset` | §4 + §5.1 | **split** |
| 2080–2224 | 145 | 2.6 | `Welfare incidence by wealth group` `subsec:welfaregroups` | §5.2 | K, trim |
| 2225–2367 | 143 | 2.8 | `Financing regimes…` `subsec:regimes` | §5.3 | K, trim |
| 2368–2486 | 119 | 2.3 | `\section{The preferred quantitative calibration}` `subsec:twoassetnl` | §4 + §6 | **split** |
| 2487–2634 | 148 | 2.9 | `Ownership plus illiquidity restores…` | §6 | K, trim |
| 2635–2799 | 165 | 3.4 | `The announcement path with two markets clearing` | §6 + §7 | **split** |
| 2800–2837 | 38 | 0.8 | `\section{Transition dynamics}` `sec:transitions` | §7 preamble | M |
| 2838–3229 | 392 | 7.8 | `The nonlinear price-level transition` `subsec:tier2` | §7 | M (−55%) |
| 3230–3329 | 100 | 2.0 | `\section{Conclusion}` `sec:conclusion` | §8 | K, trim |

### 1.2 Appendix (present) — all `K` in the appendix unless marked

| lines | est. pp | heading | referee's appendix bucket |
|---|---|---|---|
| 3333–3764 | 8.2 | `Proofs` `app:proofs` (11 subsections, 3335–3742) | "full proofs" |
| 3765–4144 | 6.9 | `The New Keynesian model…` `app:nkmodel` (+ `app:nkcommon` 3798, `app:nkrank` 3881, `app:nkhank` 3914, `subsec:ranktrans` 3982, `subsec:hanktier1` 4050) | "NK diagnostics" |
| 4145–4271 | 2.7 | `Numerical method` `app:numerics` | "numerical algorithms" |
| 4272–4422 | 2.8 | `Aggregate climate risk…` `app:aggrisk` | "aggregate risk" |
| 4423–4652 | 4.3 | `Climate damages and the nominal anchor` `app:determinacy` (+ `subsec:sunspots` 4584) | "multiplicity and indexation"; "fiscal-space collapse" |
| 4653–4684 | 0.6 | `Supplementary results` `app:supp` preamble | **rewrite** — its inventory becomes wrong |
| 4685–4742 | 1.2 | `subsec:maturity` | "robustness grids" |
| 4743–4815 | 1.4 | `subsec:twoasset` (linearized two-asset) | "robustness grids" |
| 4816–4865 | 1.0 | `subsec:zten` (KVJ point estimate) | "robustness grids" |
| 4866–4973 | 1.9 | `subsec:workedexample` | "worked examples" |
| 4974–5162 | 3.7 | `subsec:robustness` | "robustness grids"; **`tab:sources` 4986–5014 moves FORWARD** |
| 5163–5196 | 0.6 | `subsec:regimesreal` | "secondary financing mixes" |
| 5197–5242 | 0.9 | `subsec:optmu` | "optimal-real-rate" |
| 5243–5269 | 0.5 | `subsec:aggriskwelfare` | "aggregate risk" |
| 5270–5385 | 2.2 | `subsec:calibrated` | **calibration text 5273–5287 moves FORWARD to §4; `tab:calibrated` 5289–5319 moves FORWARD to §5** |
| 5386–5428 | 0.9 | `subsec:extended` | "adaptation/mitigation variants" |
| 5429–5465 | 0.7 | `subsec:calibration` (worked-example summary) | "worked examples" |
| 5466–5501 | 0.7 | `subsec:detlimits` | "multiplicity and indexation" |
| 5502–5532 | 0.6 | `Optimal accommodation` (**second, unlabelled**) | "optimal-real-rate" — **see §7.3, duplicate title** |
| 5533–5562 | 0.6 | `subsec:aggrisk` | "aggregate risk" |
| 5563–5586 | 0.5 | infrequent-rebalancing variant | portfolio robustness → **feeds §4 evidence line** |
| 5587–5607 | 0.4 | who pays in the two-asset economy | supplementary welfare cuts |
| 5608–5625 | 0.3 | ownership and specification checks | **feeds §4 (ι_H, direct/indirect ownership)** |
| 5626–5690 | 1.3 | is the restoration an artifact of a poor economy? | robustness grids |
| 5691–5773 | 1.2 | `Supplementary figures` `app:figures` | figures |

---

## 2. Target architecture, page budget, and where each target section comes from

| target section | budget | fed by (main-body lines) | fed by (appendix lines, moving **forward**) | new prose |
|---|---|---|---|---|
| 1 Introduction | 4.5 | 301–570 (compressed), 2–3 sentences salvaged from 571–732 | — | roadmap rewrite |
| 2 Minimal environment and accounting | 5.0 | 733–841, 856–890, 940–1077, 1078–1128+figure | — | 1 short §2.3 bridge |
| 3 Analytical incidence results | 6.5 | 1202–1287, 1318–1782, one paragraph distilled from 1288–1317 + 1629–1631 | — | 1 determinacy paragraph |
| **4 Calibration and identification** | 5.5 | 1931–1979, 2006–2022, 2414–2448, 2489–2502, 2783–2786 | 4986–5014 (`tab:sources`), 5273–5287, 5608–5617, 5563–5568 | **~2.7pp, mostly new** |
| 5 Stationary financing incidence | 6.0 | 1783–1807, 1808–1870, 1981–2004, 2024–2079, 2080–2163, 2225–2349 | 5289–5319 (`tab:calibrated`), 5321–5348 | linking prose |
| 6 Portfolio discipline and certification | 6.0 | 2368–2413, 2449–2486, 2487–2573, 2724–2796 | 5587–5607 (optional) | certification paragraph |
| 7 Announcement dynamics | 6.0 | 2635–2722, 2800–2872, condensed 2873–3013, 3041–3101, 3103–3164 (cut), 3166–3201 | — | deficit-block summary ¶ |
| 8 Conclusion | 2.0 | 3230–3329 | — | trims only |
| **total** | **41.5** | | | |

41.5 estimated text pages plus figure/table overhead lands inside 40–45 with the
figure budget below (§6.4).

---

## 3. Section-by-section instructions

### §1 Introduction — target 4.5pp (from 9.3pp incl. literature)

**KEEP, essentially as written**
- 304–326 — the question, the "no deficit to account for" framing. Keep. Trim
  the parenthesis 322–325 to one clause.
- 327–342 — the four building blocks. **Compress to 6 lines**: after 571–732
  moves out, this paragraph is the only positioning left, so it must absorb
  the two load-bearing distinctions from the literature section (the
  `kaplannikolakoudisviolante2023` regime/object/content contrast, 585–611;
  the `angeletos2024deficits` sign-flip contrast, 644–657). Everything else at
  571–732 goes to the appendix.
- 344–355 — the environment. Keep, 3 lines.
- 357–365 — "theory survives the climate sector". **Compress to 2 lines.**
- 367–391 — the centrepiece (incidence decomposition + instrument ordering).
  **Keep — this is the "one principal contribution".**
- 436–447 — the capitalization result. **Keep — this is the "one secondary
  dynamic contribution".** Trim 447–459 (the deficit-ratchet paragraph) to
  **two sentences**, since the ladder itself moves out of §7 — and make them
  the decomposition's: (i) at matched terminal debt, delaying the tax alone
  reverses the announcement sign; (ii) roughly two-thirds of the headline
  magnitude is the terminal-debt ratchet, and the 1.4-year frontier is the
  *joint* frontier. Do not quote a timing-alone half-life in the intro while
  the C2 frontier is provisional (`CLAIM_STATUS_R13.md` item 18).
- 489–510 — "Contributions, in order of robustness", first half. Keep.
- 548–554 — the one-thread paragraph. Keep.

**MOVE-TO-APPENDIX (the four blocks the referee names)**
- **393–412** extended multiplicity/sunspots/insulation → appendix
  `app:determinacy` preamble. Replace in the intro with **one clause** inside
  the "everything else is conditional" sentence.
- **428–434** optimal accommodation / trend-inflation margin → `subsec:optmu`.
  Cite `prop:muneutral` once and stop.
- **465–473** the unmatched NK discussion → `app:nkmodel` preamble.
- **475–487** aggregate risk → `app:aggrisk` preamble.
- **511–519** the conditional-results list. Keep **only** the clause naming
  what is conditional; the four itemised qualifiers duplicate 393–434 and go
  with them.
- **521–546** the four-foundations "relative to X" passage → move to the
  appendix literature section as its opening. It is 26 lines and it repeats
  the contrasts of 327–342.

**REWRITE**
- **556–568** the roadmap. Every pointer in it becomes wrong. This is a
  five-line rewrite naming the eight new sections.

**MOVE-TO-APPENDIX in full**
- **571–732** `\section{Related literature}` `sec:literature`. It becomes
  Appendix A.0 "Related literature in full", placed immediately after
  `\appendix` (3330) and before `app:proofs`.

**Effort.** Compression of 301–570 is **new prose**, not scissors: five of the
eight paragraphs above are load-bearing sentences woven into surrounding text,
not standalone blocks. Estimate **6–8 hours**. Moving 571–732 is
**mechanical** (cut, paste after 3330, add one `\label`), **20 minutes**.

---

### §2 Minimal environment and accounting — target 5.0pp (from 8.0pp)

**KEEP**
- 736–748 (framing; trim the NK forward-reference 742–747 to one sentence).
- **749–764** "The scenarios, up front" — **compress to 6 lines.** It
  currently enumerates five environments, three of which leave the body.
- 767–815 `subsec:households` — keep whole. This is the referee's "households;
  nominal debt and tax instruments".
- 821–840 abatement capital + `eq:Kg` + `eq:abatement` — keep. This is the
  referee's "reduced-form adaptation capital".
- 856–890 damages and incidence, `eq:damages` + `eq:incidence` + the floor
  discussion — keep. `eq:incidence` is needed by `subsec:households` (792)
  and by §3.
- 940–972 `subsec:government` — keep whole (`eq:nominalrule`, `eq:fisher`,
  `eq:gbc`).
- 975–1007 `def:equilibrium`, `eq:assetmarket`, `def:nu` — keep whole.
- **1009–1049** the three-object separation (resource BCR / strictly fiscal
  share / what ν is). **Keep whole.** This is *verbatim* the referee's
  "ν_dam / ν_reval / ν / L distinction" and it must not be trimmed.
- 1051–1061 `def:elasticity` — keep.
- 1129–1199 the TikZ mechanism figure + caption — keep.

**MOVE-TO-APPENDIX — the carbon-stock mitigation block**
- **842–855** `eq:emissions`, `eq:carbon`.
- **891–902** `eq:climatefixedpoint` and the sentence introducing the reduced
  form. Retain **one** sentence in the body: "we take the reduced form
  `D = D_0 e^{-θ_g K_g}` — public adaptation capital — as the benchmark, and
  develop the carbon-stock mitigation variant in Appendix X."
- **904–937** "Mitigation or adaptation?" — **compress to 4 lines** in the
  body (the adaptation reading is the benchmark; θ_g has no empirical
  counterpart), full text to appendix beside `subsec:extended` (5386–5428).
- **1269–1274** `lem:climate` moves with the carbon block (see §3).

**TRIM**
- **1063–1076** the scope note on the clearing object → move to §6 opening,
  where the two-asset economy is actually built. It reads as a forward
  reference here and as a motivation there.
- **1080–1128** the mechanism prose. **Cut 1116–1127 outright** (it describes
  two channels *omitted from the figure* which the caption 1181–1197 already
  describes) and compress 1080–1115 by half.

**Effort.** The carbon-block excision is **mechanical** except for the
one-sentence bridge and the "Mitigation or adaptation?" compression, which is
**new prose** (~1 hour). The `subsec:mechanism` trim is **new prose**
(~1.5 hours). Total **4–5 hours**.

---

### §3 Analytical incidence results — target 6.5pp (from 10.7pp)

The referee's list maps one-to-one onto existing propositions. Nothing here is
invented; the work is deletion of discussion around the statements.

| referee item | source | disposition |
|---|---|---|
| joint nominal-rescaling neutrality | `lem:neutrality` 1334–1342, discussion 1346–1357 | K |
| incidence formula | `prop:suffstat` 1433–1461 + status 1462–1470 | K |
| resource/revaluation accounting | `prop:selffinancing` 1523–1563 + status 1564–1567 | K |
| financing comparative static | `prop:financingdesign` 1642–1667 + status 1668–1673 | K |
| covariance decomposition | `prop:covincidence` 1728–1751 | K |
| two-market Schur extension | `prop:twomarket` 1680–1706 + status 1707–1717 | K |
| **ONE short paragraph** on determinacy and indexation | see below | new, ~10 lines |

**KEEP**
- 1205–1215 section preamble — **rewrite to match the new order** (it currently
  promises sunspots and accommodation, both of which leave).
- 1217–1221 `ass:feasible`.
- 1252–1267 `lem:S`, 1276–1285 `lem:anchor`.
- 1321–1332 the real fixed point + `eq:realfp`; 1334–1357 `lem:neutrality`.
- 1380–1384 the ε_S ↔ d ln S/d ln b restatement.
- 1386–1395 `prop:muneutral` + status.
- 1412–1431 the composite setup + `eq:Scomposite`; 1433–1470 `prop:suffstat`.
- 1523–1587 `prop:selffinancing` and `res:disinflation`.
- 1635–1673 `prop:financingdesign`; 1675–1717 `prop:twomarket`;
  1719–1751 `prop:covincidence`.

**MOVE-TO-APPENDIX**
- **1223–1247** the "analytical status, up front" paragraph. The per-statement
  `\textsc{Status:}` lines under each proposition already carry this
  information; keep those, move the summary paragraph to `app:proofs` (3333)
  as its opening. −25 lines.
- **1288–1317** the whole `Determinacy` subsection, including
  `prop:determinacy` (1290–1304) and its status line and discussion. It goes
  to `app:determinacy` (4423). **Replace with the referee's one short
  paragraph**, built by merging what is already at **1629–1631** (which
  already says the determinacy questions are developed in the appendix) with
  three sentences: existence holds under the crossing condition; uniqueness
  under ε_S > −1; indexing the spending line insulates the anchor and the
  calibrated sunspot region is empty. New prose, ~10 lines.
- **1359–1379** the "no stationary deficit" paragraph. Keep the first
  sentence in the body; the rest (the transition/deficit forward-reference,
  1364–1379) goes to §7's opening.
- **1397–1407** the optimal-accommodation interpretation of `prop:muneutral`
  → `subsec:optmu` (5197). Keep one clause.
- **1472–1508** "Every headline result is a reading of (suffstat)". **Cut to
  half.** Keep 1472–1487 (numerator/denominator + financing sign) and
  1502–1508 (the elasticity map is the formula's empirical content, now a
  forward reference to §4). Move 1488–1501 (sunspot denominator, portfolio
  bound) to the appendix.
- **1509–1518** the "nothing above referenced climate" generality paragraph —
  keep, it is 10 lines and it is the paper's analytical claim.
- **1589–1627** the intuition for why ∂S/∂τ > 0. **Compress to 12 lines.**
  1611–1626 (the borrowing-limit sweep, the non-monotone magnitude, the
  "we deliberately do not assert" hedge) belongs in §4 with
  `tab:elasticitymap`.
- **1631** the optimal-accommodation pointer — keep as one sentence.
- **1752–1779** `prop:covincidence` status + the numerical answer
  (`\covTiltDirect`, `\epsTilt`, `\covTiltShift`). **Keep the status block
  1752–1762; move the measured numbers 1762–1779 to §4**, where the direct-vs-
  distributional identification is the referee's own agenda item.

**Effort.** ~55% mechanical. The determinacy paragraph and the §3 preamble
rewrite are **new prose** (~2 hours); the 1472–1508 and 1589–1627
compressions are **new prose** (~3 hours). Total **6–7 hours**.

---

### §4 Calibration and identification — target 5.5pp — **REORDERING + REWRITE**

> **This section does not exist in the manuscript.** Grep confirms:
> "untargeted" — **NOT FOUND** (0 hits). "identification ledger" —
> **NOT FOUND**. "targeted moment" — 1 hit at 4834, inside an unrelated
> convenience-yield aside. "order condition" — 1 hit at 4828, and it is a
> *first-order condition*, not an identification count. "Financial Accounts" —
> **NOT FOUND**. Per project rule 3, I return no patch for referee phrases I
> cannot locate; §4 is therefore **construction**, not relocation.

**This is the single largest structural change in the plan, and it is a
reordering as well as a rewrite.** The referee requires calibration *before*
the results. In the current manuscript the calibration is not merely late — it
is **in the appendix**:

- `subsec:calibrated` (the β\* bisection to debt/income = 1.10, the 2%-of-income
  program, the three externally disciplined damage columns) is at **5270–5385**;
- `tab:sources` (climate parameters by evidentiary status) is at **4986–5014**,
  buried inside `subsec:robustness`;
- `subsec:calibration` (the worked example) is at **5429–5465**;
- the two-asset calibration is scattered across the *results* section at
  **2414–2448** (χ_b, ζ, the Krishnamurthy–Vissing-Jorgensen mapping) and
  **2489–2502** (λ, ι_H, the recalibrated β).

So the body currently states results whose calibration the reader must find
2 000 lines later, in three different appendix subsections. The referee is
right and the fix is structural.

**4.1 Targeted moments — MOVE FORWARD (mechanical)**
- **5273–5287** verbatim (β\* = 0.9267 by bisection to debt/income 1.10 in
  pre-damage income; program = 2.0% of income at the calibrated price level;
  D_0 ∈ {0.02, 0.06, 0.20}).
- **4986–5014** `tab:sources` verbatim — this *is* the referee's "climate
  parameters classified by evidentiary status" (columns: benchmark, status
  `anchored`/`swept`, source). Leave `\label{tab:sources}` untouched; it is
  referenced from 1860, 4983, 5365, 5712 and all four survive the move.
- **2414–2448** the two-asset preference block and the KVJ curvature mapping.
  This is a *move*, not a copy: §6 keeps a one-sentence recall.
- **2489–2502** the ownership-plus-illiquidity calibration (λ = `\OwnKVLam`,
  the β recalibrated so directly-held liquid position matches `\OwnKVSb`,
  the liquidity weight held at its frictionless value).

**4.2 Untargeted moments — MOVE FORWARD + NEW**
- **2006–2022** "Observable counterparts" — the 17.7% constrained share against
  `kaplanviolanteweidner2014`, and the explicit statement that the *magnitude*
  is a model output. Move whole; it is already written as an untargeted-moment
  paragraph.
- **2499–2502** the untargeted top-decile/top-percentile shares
  (`\OwnKVTopTen`, `\OwnKVTopOne`), total wealth `\OwnKVW`, illiquidity premium
  `\OwnKVPrem` — the manuscript already says "none of which are targeted".
- **5608–5617** ι_H and the intermediated slice; **2783–2786** the ι_H =
  `\KVTrIota` direct-holding share. Together these are the referee's "direct
  and indirect debt ownership".
- **5563–5568** and **2666–2675** the adjustment-frequency λ — the referee's
  "portfolio-adjustment evidence".
- **NEW:** the untargeted-moment table itself. Source:
  `main_identification_ledger.m` Section C (file lines 371–486).

**4.3 Direct vs distributional tax-demand identification — MOVE FORWARD**
- **1762–1779** (from `prop:covincidence`'s status block): the direct
  fixed-state covariance term `\covTiltDirect` against the full stationary tilt
  `\epsTilt`, with `\covTiltShift` carried by 𝒟_α.
- **1931–1979** the tilt decomposition, the exact finite-change split
  (`\covPolExact` direct vs `\covDistExact` distributional), the reconciliation
  of the linearised and exact splits (1942–1954), and "What disciplines what"
  (1954–1960). This is *the referee's agenda item verbatim* and it currently
  sits in the middle of a results subsection.
- **1981–2004** `tab:elasticitymap` — **decision required**. It is both a
  calibration object (the primitive map) and a result. Recommendation: **keep
  the table in §4** and reference it from §5. `\ref{tab:elasticitymap}` is
  called from 505, 1503, 1614, 1842, 1881, 1931, 2021, 4484; all eight still
  resolve, but 1842 and 1881 will now be *backward* references, which is the
  correct direction.
- **1611–1626** the borrowing-limit sweep and the non-monotone magnitude,
  moved down from §3.

**4.4 NEW PROSE — the identification ledger**

The repository now produces exactly this section's content:
`research_green_deficits/main_identification_ledger.m` (647 lines). Its own
header states it was written for "referee report R12, Major Comment 2, items
1–3":

- **Section A** (file 176–300) — the parameter ledger, every parameter
  classified `NORM` / `EXT` / `CAL` / `DECL` / `NUM`, where `DECL` is
  explicitly "chosen by the authors with NO external target".
- **Section B** (file 301–370) — free parameters against targeted moments, the
  order condition made visible. It counts *distinct moments*, not instruments,
  and explains why (file 314–322).
- **Section C** (file 371–486) — the untargeted validation table: liquid and
  illiquid wealth, direct/indirect debt ownership, adjustment frequency,
  convenience yields, returns, mobility, wealthy hand-to-mouth.
- **Section D** (file 487–609) — structural verdicts that need no external
  number (e.g. V1, whether the superstar state is identified by its single
  moment).

**Three hard constraints on this subsection.**

1. **The driver has not been run.** `output/tables/` contains 45 `.txt` files;
   `identification_ledger.txt` is **not** among them (`ls output/tables/ | grep
   -i ident` returns nothing). Run
   `clear; main_identification_ledger` before drafting. Note the driver calls
   `clearvars` at its own line 50 — that is fine because it is the entry
   point, but do **not** wrap it inside another script (project rule 5:
   `clearvars` in a script kills the caller's workspace).
2. **The data column is NaN by design.** `main_identification_ledger.m`
   lines 61–101 define `DATA` with every field `= NaN` and the source named in
   the comment above it (`[SCF]`, `[FA]` Financial Accounts L.210, `[KV]`
   Kaplan–Violante ECMA 2014, `[KVW]` Kaplan–Violante–Weidner BPEA 2014(1),
   `[KVJ]` Krishnamurthy–Vissing-Jorgensen JPE 2012). **Ship the table with
   the NaN slots and the named sources.** Project rule 2: a wrong decimal in a
   validation table is worse than an empty one. The driver's own header says
   the same thing in more words (file lines 24–29).
3. **Two-asset rows carry the UNCERTIFIED stamp.** The driver header (file
   lines 38–45) and `CLAIM_STATUS_R13.md` both record that the two-asset block
   has not cleared Gate 11. Every two-asset row in §4 must be stamped, and no
   two-asset number may be presented as an established model moment
   (project rule 6).

**Effort.** This is the **most expensive section in the plan**. Moving 4.1–4.3
is mechanical (~2 hours) but the ordering rewrite around them is not: every
moved block currently opens with a sentence that presupposes the results
already stated. The ledger subsection (4.4) is **entirely new prose plus one
MATLAB run**: ~1 hour to run and read the driver output, **8–10 hours** to
write the two tables and their surrounding argument. **Section total: 12–14
hours.** Budget it first; everything else in the plan is cheaper.

---

### §5 Stationary financing incidence — target 6.0pp (from ~11.4pp, minus §4 exports)

**KEEP**
- 1786–1806 the section preamble — **rewrite** (it currently promises the
  aggregate-risk subsection and the worked example, both gone).
- 1811–1870 the exact counterfactual decomposition (−6.37 tax / −1.45 damage /
  +2.20 risk / +0.17 interaction). Keep whole; this is the mechanism.
- 2024–2064 the magnitude caveat and the portfolio forward-reference. **Trim to
  8 lines** — after §6 exists as its own section, most of 2038–2058 is a
  preview of it.
- 2066–2074 figure `PFig15`.
- 2083–2103 the two-incidence-objects framing; 2105–2130 `tab:incidence`;
  2132–2155 the two findings.
- 2157–2163 figure `PFig8`.
- 2228–2273 the four regimes and the fixed-nominal/fixed-real caveat; 2275–2297
  `tab:regimes`; 2299–2305 the fixed-real pointer; 2308–2341 the three results.
- 2343–2349 figure `PFig9`.
- **PULL FORWARD** 5289–5319 `tab:calibrated` and 5321–5348 (the four
  conclusions by damage column). These are results, and after §4 exists they
  have a home. `\ref{tab:calibrated}` is called from 496, 3573, 5039, 5287 —
  all resolve after the move.

**MOVE TO §4** (listed above): 1871–1908, 1910–1979, 1981–2004, 2006–2022.

**MOVE-TO-APPENDIX**
- **2165–2180** "Extended groups" → supplementary welfare cuts. Keep two
  sentences in the body (the constrained lose −2.64% against −1.56%; every
  ordering reverses under the rebate).
- **2182–2218** "Decile resolution" → supplementary welfare cuts, whole. It is
  37 lines of tail-resolution caveats and a `castaneda2003` re-targeting.
- **2352–2364** the bounding paragraph. It is already only a pointer to
  `subsec:maturity`; **cut to two sentences.**
- **2220–2221** — `CUT-DEAD`. This is a comment recording that PFig16 was
  already relocated; it is stale bookkeeping.

**Effort.** Mostly mechanical, but the §5 preamble and the two joins (moving
`tab:calibrated` forward, dropping the elasticity map back to §4) are **new
prose**: **4–5 hours**.

---

### §6 Portfolio discipline and certification — target 6.0pp (from ~5.2pp + certification)

This section is close to its target already; the work is re-scoping, not
cutting.

**KEEP**
- 2370–2380 the opening.
- **2381–2412** "Two claims, deliberately separated" — the `\begin{quote}`
  block with the Robust claim and the Preferred-calibration claim. **Keep
  verbatim.** It is the paper's compliance with project rule 6 and it must not
  be softened in the compression.
- 2449–2479 the two results (financing experiment on the nominal margin;
  the ζ sweep).
- 2487–2573 the ownership-plus-illiquidity restoration, both the 2×2
  (2504–2513) and the matched-parameter ladder (2523–2534). Keep both tables.
- 2724–2737 the transition-inclusive financing incidence framing;
  2739–2760 `tab:kvwel`; 2762–2796 the discussion (including the finding that
  the transition adds almost nothing). **Move this whole block here from §7's
  neighbourhood** — it is portfolio incidence, not announcement timing.
- 1063–1076, moved down from §2, as the section's motivation.

**MOVE TO §4**: 2414–2448, 2489–2502 (calibration), leaving one-sentence
recalls.

**MOVE-TO-APPENDIX**
- **2575–2633** the "why wealthy hand-to-mouth cannot arise" remark and the
  friction-only limit. 59 lines. It is a genuine negative result and it should
  be preserved in full — but in the appendix, beside 5563–5586.
- **2481–2485, 2798** — already one-line pointers; keep, repoint.

**NEW PROSE — the certification paragraph.** The referee's section title says
"and certification", and the manuscript has no such paragraph. Source
material exists: `CLAIM_STATUS_R13.md` (Gate 11, the `RO`/`CS`/`WP` vocabulary,
items 8, 9, 13, 14, 15), `TWO_ASSET_FAILURE_FALLBACK_MEMO.md`, and the
manuscript's own hedge at **1712–1717** ("the quantification is reported only
for discretizations that clear the numerical certification protocol, which is
in progress"). Write ~15 lines stating: which claims are certified one-asset
(`RO`), which are calibration-dependent signs (`CS`), and which are withheld
pending Gate 11 (`WP`). **Do not upgrade any two-asset number.**

**Effort.** Relocations mechanical (~1.5 hours). The certification paragraph is
**new prose that must be checked line-by-line against `CLAIM_STATUS_R13.md`**
— ~3 hours. Total **4–5 hours**.

---

### §7 Announcement dynamics — target 6.0pp (from ~10.5pp)

**KEEP**
- 2803–2812 the opening.
- **2635–2660** the two-market announcement path and the front-loading shares
  (`\TwoTrShare` vs `\OneTrShare`), and **2662–2722** the disciplined
  economy's announcement path with its four gates. Move these here from §6's
  present location — this is *timing*, and it belongs with the timing section.
- 2842–2872 the transition setup (the unknown price path, the detrending).
- 3041–3101 the three statements (−3.9% impact, 77% front-loading, the 5.3%
  windfall, denomination irrelevance on-path). Keep, trim the NK contrast
  3088–3101 to 4 lines.
- 3128–3155 the rebate path along the same announcement.
- 3166–3182 "When does the instrument ordering become operative?" — keep; it is
  the bridge from §5's steady-state ranking to a policy statement.
- 3203–3226 figure `PFig18`.

**COMPRESS**
- **2813–2836** the NK-diagnostic scoping paragraph → **6 lines**, pointing at
  `app:nkmodel`.
- **2873–2911** "The dynamic nominal budget, made explicit" (`eq:nombudget`,
  `eq:nomtrend`). Keep both equations and 8 lines of text; move 2893–2911 (the
  two facts and the licensing argument) to the appendix numerics/derivations.
- **3184–3201** "three objects, one signature" → 6 lines; it is elegant and it
  is also a recap.
- **3155–3164** the perfect-foresight scoping — keep, it is a real limitation.

**MOVE-TO-APPENDIX — "secondary financing mixes"**
- **2913–2938** the deficit-financing experiment; **2940–2959**
  `tab:deficitladder`; **2961–2978** the ladder discussion; **2980–2997**
  "What the following number is, and is not"; **2999–3013** the frontier
  `eq:deficitfrontier` and ρ_d\*. That is 100 lines ≈ 2.0pp. Replace with a
  **6-line summary** in the body: taxes phased in rather than levied
  contemporaneously overturn the announcement sign, and the reversal survives
  full consolidation — at matched terminal debt the sign flips
  (C1 −0.040 → C2 +0.022), so it is a tax-timing effect *in kind*; the
  reported *magnitude* is a joint object, roughly one-third timing and
  two-thirds terminal-debt ratchet; the 1.4-year frontier is the *joint*
  frontier (validated, ρ* = 0.6121 → 1.41 y); the timing-alone frontier is
  slower and enters only through its exporter-gated macro. **The caveat must
  travel with the summary, not stay behind with the table** — `CLAIM_STATUS_R13.md`
  item 18 records that "caveat precedes the number" is an applied edit and must
  not be undone by this move.
- **3015–3023** and **3025–3040** the computational-fixed-point and
  two-solvers paragraphs → `app:numerics`. Keep one sentence: the announcement
  is solved twice, independently, and nothing is reported unless the two agree.
- **3103–3126** "Transition-inclusive welfare". **Keep 8 lines** (the
  transition deepens regressivity: poorest −2.61 → −3.39, top decile
  −1.0 → −0.5); move the rest to supplementary welfare cuts.

**Effort.** The deficit-block excision is **mechanical plus one carefully
written summary paragraph** where the danger is dropping the caveat (~2 hours,
of which 1 is checking against `CLAIM_STATUS_R13.md` item 18). The rest is
compression: **5–6 hours** total.

---

### §8 Conclusion — target 2.0pp (from 2.0pp)

Already at budget. **Trims only, to pay for the pointer rewrites:**
- 3233–3244, 3246–3262, 3264–3275, 3277–3285 — keep.
- **3287–3315** — trim by a third. 3302–3315 (the matched HANK sign, the 2×2
  discriminating test, high-frequency identification) can lose 6 lines without
  losing a claim.
- 3317–3327 — keep whole (the open questions, including the honest statement
  that the distributional term's discipline is internal).
- **3285** repoints to `app:determinacy` — still valid after the move.

**Effort.** **1 hour**, mechanical.

---

## 4. What the online appendix looks like afterwards

Ordering, with the new arrivals marked **NEW**:

| appendix section | content | source |
|---|---|---|
| A.0 Related literature **NEW** | 571–732 whole + 521–546 from the intro | body |
| A Proofs | 3333–3764 unchanged + `prop:determinacy` (1290–1315) + the status paragraph (1223–1247) as its opening | body + appendix |
| B Multiplicity, indexation, fiscal-space collapse | 4423–4652 + intro 393–412 + `subsec:detlimits` 5466–5501 | merge |
| C Aggregate risk | 4272–4422 + `subsec:aggrisk` 5533–5562 + `subsec:aggriskwelfare` 5243–5269 + intro 475–487 | merge |
| D Optimal real rate | 5197–5242 + 5502–5532 (`prop:optimalmu`) + intro 428–434 + body 1397–1407 | merge — **resolve the duplicate title, §7.3** |
| E NK diagnostics | 3765–4144 + intro 465–473 + body 2813–2836 residue | merge |
| F Secondary financing mixes **NEW** | 2913–3013 (deficit ladder) + `subsec:regimesreal` 5163–5196 | body + appendix |
| G Robustness grids | 4685–4742, 4743–4815, 4816–4865, 4974–5162 (minus `tab:sources`), 5626–5690 | appendix |
| H Numerical algorithms | 4145–4271 + body 3015–3040, 2893–2911 | merge |
| I Worked examples | 4866–4973 + 5429–5465 | appendix |
| J Supplementary welfare cuts **NEW** | 2165–2180, 2182–2218, 3103–3126 residue, 5587–5607 | body + appendix |
| K Adaptation/mitigation variants **NEW** | 842–855, 891–902, 904–937, `lem:climate` 1269–1274, `subsec:extended` 5386–5428 | body + appendix |
| L Portfolio negative results | 2575–2633, 5563–5586, 5608–5625 | body + appendix |
| M Supplementary figures | 5691–5773 | appendix |

**`app:supp`'s preamble (4653–4684) must be rewritten.** It currently
enumerates "eight supporting analyses" by name and cross-reference; after this
restructuring that inventory is wrong in six of eight entries. Treat it as
**new prose**, ~45 minutes.

---

## 5. Label audit — every `\label` in a moved block, and every site that references it

**Nothing dangles.** LaTeX resolves `\ref` across the `\appendix` boundary in
both directions, so a body → appendix move never breaks a reference. What it
*does* break is **prose**: a sentence saying "Section~\ref{X}" when X is now an
appendix subsection reads wrong. The list below is therefore a
**text-repair list**, not a compile-error list.

### 5.1 Body labels that move to the appendix

| label | defined | referenced at | after the move |
|---|---|---|---|
| `sec:literature` | 571 | 556 | 556 is the roadmap, being rewritten. Change "Section" → "Appendix". |
| `eq:emissions` | 847 | 907 | 907 moves with it. Self-contained. |
| `eq:carbon` | 853 | — | **unreferenced anywhere.** Moves cleanly. |
| `eq:climatefixedpoint` | 897 | 981, 1085, 1270, 3363, 3453, 3776 | 981 (`def:equilibrium`) and 1085 (mechanism prose) **stay in the body** and will point into the appendix — reword both to "the carbon-stock block of Appendix K". 1270 moves with `lem:climate`. |
| `lem:climate` | 1269 | 900, 3362, 4479 | 900 moves with the block; 4479 is appendix→appendix. Clean. |
| `prop:determinacy` | 1290 | 362, 1234, 1468, 3380, 3479, 3489, 3627, 4444, 4493, 4517, 5653 | **The heaviest single move in the plan — 11 sites.** 362 is in the intro (being compressed anyway); 1234 is in the status paragraph, which moves too; 1468 is inside `prop:suffstat`'s status line and **stays in the body** — reword to "Appendix". The seven appendix sites are appendix→appendix. |
| `eq:nombudget` | 2879 | 2904, 2918 | 2904 stays (kept text), 2918 moves with the deficit block. Reword 2918's neighbourhood. |
| `eq:nomtrend` | 2891 | 2866, 2897 | Both stay in the kept portion. Clean. |
| `tab:deficitladder` | 2947 | 2961 | Both move together. Clean. |
| `eq:deficitfrontier` | 3006 | — | **unreferenced.** Moves cleanly. |
| `eq:tiltdecomp` | 1920 | — | **unreferenced.** Moves to §4 cleanly. |
| `fig:pfig15/8/9/18` | 2073, 2162, 2348, 3225 | — | **all four unreferenced by `\ref`.** Figures stay in the body; no action. |

### 5.2 Appendix labels moving **forward** into the body

| label | defined | referenced at | after the move |
|---|---|---|---|
| `tab:sources` | 4991 | 1860, 4983, 5365, 5712 | Moves to §4. 4983 is `subsec:robustness`'s own sentence introducing it — **rewrite that sentence**, it will otherwise introduce a table that is no longer there. 5365 and 5712 become appendix→body, fine. |
| `tab:calibrated` | 5299 | 496, 3573, 5039, 5287 | Moves to §5. 5287 is `subsec:calibrated`'s own lead-in and moves with the calibration text; **5039 (inside `subsec:robustness`) must be reworded**. |
| `subsec:calibrated` | 5271 | 378, 1790, 3062 | The subsection is split (calibration → §4, results → §5). **Re-point all three body sites explicitly**; do not leave one label covering two destinations. Recommend two labels: `sec:calibration` (§4) and keep `subsec:calibrated` on the §5 results block. |

### 5.3 Labels that stay put but whose *referencing sentences* move

These are the quiet failure mode. Each of the following labels is referenced
from a block that changes section, so the referring sentence's word
("Section" vs "Appendix") must be re-checked:

- `subsec:sunspots` (4584) ← body 405, 515, 1314 — 1314 disappears with
  `prop:determinacy`'s discussion; 405 and 515 are in intro text being cut.
- `subsec:robustness` (4976) ← body 380, 513, 926, 933, 1037, 1792, 2798 —
  **926 and 933 move to the appendix** with "Mitigation or adaptation?", so
  they become appendix→appendix.
- `subsec:optmu` (5197) ← body 1398, 1631 — 1398 moves into `subsec:optmu`
  itself; check for a self-reference.
- `subsec:twoasset` (4743) ← body 2412, 2481, 2483 — 2412 moves to §4 with the
  two-asset calibration.
- `subsec:aggrisk` (5534) ← body 480, 737, 760, 1284, 1407, 1798 — 480 (intro)
  and 1798 (§5 preamble) are cut; 737, 760, 1284, 1407 all currently say
  "Section~\ref{subsec:aggrisk}" for a subsection that is **already in the
  appendix**. That is a pre-existing defect, not one this plan creates, and it
  should be fixed in the same pass.
- `subsec:tier2` (2838) — **25 reference sites**, the most-referenced label in
  the paper. It stays in the body as §7. Verify all 25 after the move;
  4 of them (2643, 2667, 2691, 2793) are in the block relocating from §6 to
  §7 and become intra-section references.
- `prop:muneutral` (1386) ← 431, 517, 533 in the intro (all three in blocks
  being cut or compressed), 1228 (status paragraph, moving), 1397 (moving),
  plus five appendix sites. Verify the proposition still has at least one body
  reference after the cuts — currently every body citation of it is inside a
  block scheduled to move.

### 5.4 Labels with no reference at all (safe to move, worth a glance)

`sec:intro`, `eq:Sdef`, `eq:carbon`, `subsec:government`, `subsec:mechanism`,
`subsec:neutrality`, `eq:covincidence`, `eq:covfull`, `eq:tiltdecomp`,
`fig:pfig15`, `fig:pfig8`, `fig:pfig9`, `eq:deficitfrontier`, `fig:pfig18`,
`eq:nk-carbon`, `eq:rank-euler`, `eq:rank-labor`, `eq:rank-nkpc`,
`eq:rank-resource`, `eq:hank-labor`, `eq:hank-div`, `eq:hank-policy`,
`fig:pfig13`, `fig:pfig7`, `fig:pfig10`, `fig:pfig11`, `fig:pfig16`,
`fig:pfig21`.

---

## 6. Practical notes

### 6.1 The number macros survive every move
All quoted values are macros expanded from `numbers_auto.tex` (written by
`export_paper_numbers.m`) and `numbers_manual.tex`, `\input` at preamble lines
46 and 49. Moving a paragraph moves its macros intact; there is **no** risk of
a number drifting during relocation, and `check_manuscript_numbers.py` /
`check_output_staleness.py` still apply afterwards. Run
`paper/check_tex.py` after each move batch.

### 6.2 `\pendingnum` fallbacks
Preamble lines 55–60 `\providecommand` the fixed-real regime macros to
`\pendingnum`. `subsec:regimesreal` (5163–5196) moves into appendix F; the
`\providecommand` block stays in the preamble and keeps working. No action.

### 6.3 Float barriers
`\FloatBarrier` appears at column 1 on lines 1782, 2077, 2224, 2352, 2367,
3229, 3332, 3980, 4420 (the last two are appendix-internal). After
resectioning, re-place them at the new section boundaries; `placeins` is
loaded with `[section]` (line 30), so figures are already section-anchored.

### 6.4 Figure budget for the 40–45pp target
After the moves the body keeps five figures (`fig:mechanism` 1129, PFig15,
PFig8, PFig9, PFig18) and **six** `table` environments — `tab:elasticitymap`,
`tab:incidence`, `tab:regimes`, `tab:kvwel`, plus `tab:sources` and
`tab:calibrated` moved forward — **plus the two unlabelled §6 tabulars
(2504–2513, 2523–2534) and the two new §4 ledger tables**. That is ten table
objects against a 41.5pp text budget, which is two or three too many.
**Recommendation:** move `tab:kvwel` (2739–2760) to the appendix and report its
gradient in text; fold `tab:sources` into the §4 ledger table rather than
printing both; and keep only the matched-parameter ladder (2523–2534) of the
two §6 tabulars. That buys ~1.5pp and takes the body to a defensible 5 figures
and 6 table objects.

### 6.5 Do not touch
No step in this plan edits anything under `src_project/`. In particular
`solve_hank_dtpl_transition.m`, `solve_household_twoasset_kv.m`,
`kv_solve_alpha.m`, `kv_solve_bond_given_q.m`, `kv_stationary_block.m`,
`kv_calibrate_on_grid.m` are untouched — D10/D11 parity is not disturbed.
The only code run is `main_identification_ledger.m`, which is read-only over
stored `.mat` files by construction (its header, file lines 14–22).

---

## 7. Effort ledger

| # | target section | mechanical | new prose | total | dominant risk |
|---|---|---|---|---|---|
| 1 | Introduction | 0.5 h | 6–8 h | **7–9 h** | the four deletions are interleaved, not blocked |
| 2 | Environment and accounting | 1 h | 3–4 h | **4–5 h** | the carbon-block bridge sentence |
| 3 | Analytical results | 3 h | 4 h | **6–7 h** | determinacy paragraph must not overclaim |
| 4 | **Calibration and identification** | 2 h | **10–12 h** | **12–14 h** | **section does not exist; ledger unrun; NaN discipline** |
| 5 | Stationary incidence | 2.5 h | 2 h | **4–5 h** | joining `tab:calibrated` to §5's argument |
| 6 | Portfolio and certification | 1.5 h | 3 h | **4–5 h** | certification wording vs `CLAIM_STATUS_R13.md` |
| 7 | Announcement dynamics | 3 h | 2.5 h | **5–6 h** | the deficit caveat must travel with the summary |
| 8 | Conclusion | 1 h | — | **1 h** | — |
| — | appendix assembly + `app:supp` preamble | 3 h | 1 h | **4 h** | six of eight inventory entries go stale |
| — | label/reference repair pass (§5) | 3 h | — | **3 h** | 25 sites for `subsec:tier2` alone |
| — | compile, `check_tex.py`, page count | 2 h | — | **2 h** | first real page measurement |
| | **total** | **22.5 h** | **32–35 h** | **≈55–60 h** | |

**Honest split: about 40% of this is scissors and 60% is writing.** The three
places where "move it" is a lie are:

1. **§4 in its entirety.** It is construction, and the driver that supplies its
   content has not been run.
2. **The introduction.** The four blocks the referee wants removed
   (393–412, 428–434, 465–473, 475–487) are clean excisions, but the
   surrounding argument then has to carry the weight the literature section
   used to carry, because that section leaves too.
3. **The §7 deficit summary.** The decomposition run changes what the 6
   lines may say: the *sign* claim may now be strengthened (it survives
   consolidation), the *magnitude* may not (two-thirds ratchet), and the
   timing-alone half-life may not be quoted beyond its exporter-gated macro
   while its bracket is provisional. The easiest mistake is no longer
   accidental strengthening but drawing the licensed/unlicensed line in the
   wrong place — check the summary against `CLAIM_STATUS_R13.md` item 18
   before committing it.

---

## 8. Compliance record

- **Rule 1 (no invented line numbers).** Every line number here was read out of
  `green_deficits_price_level.tex` or `main_identification_ledger.m` in this
  session. The brief's "`\appendix` around 3325" is corrected to 3330.
- **Rule 2 (no invented values).** No empirical value is asserted. Page counts
  are labelled estimates with their method and their known bias stated (§0).
  The §4 validation table ships with NaN slots and named sources.
- **Rule 3 (NOT FOUND).** The referee's phrases "untargeted moments",
  "targeted moments", "identification", "portfolio-adjustment evidence" and
  "direct and indirect debt ownership" **do not appear as manuscript text**.
  No patch is proposed for them; §4 is flagged as new construction.
- **Rule 4 (solvers).** No file under `src_project/` is touched.
- **Rule 5 (MATLAB).** Only `main_identification_ledger.m` is run, as a
  top-level entry point (it calls `clearvars` at its own line 50).
- **Rule 6 (two-asset UNCERTIFIED).** §6 keeps the "Two claims, deliberately
  separated" quote block (2381–2412) verbatim, adds a certification paragraph,
  and stamps every two-asset row of the §4 ledger UNCERTIFIED.
