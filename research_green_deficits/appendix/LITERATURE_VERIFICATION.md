# Literature verification record

*Web-verification pass of 2026-07-03 over the ten priority items flagged in
the editorial roadmap (Step 7). Method: web search + primary-source pages
(NBER, arXiv, publisher, BIS, IMF). Anything not confirmable is labeled,
not guessed. Machine-readable copy: run
`export_literature_verification` (src_project) →
`output/tables/literature_verification.txt`.*

## Verified items (citable)

| # | Citation | Status | Source |
|---|---|---|---|
| 1 | Kaplan, Nikolakoudis & Violante (2023, rev. 2026), "Price Level and Inflation Dynamics in Heterogeneous Agent Economies," **NBER WP 31433** (also CEPR DP18260). No journal version as of 2026-07. | VERIFIED | nber.org/papers/w31433 |
| 2 | Auclert, Rognlie & Straub (2025), "Fiscal and Monetary Policy with Heterogeneous Agents," **Annual Review of Economics 17, 539–562** (also NBER WP 32991). | VERIFIED | annualreviews.org, doi:10.1146/annurev-economics-091624-044646 |
| 3 | Höfer (2025), "Price Levels in Heterogeneous-Agent Models," **arXiv:2510.26065**. FTPL in Bewley–Huggett–Aiyagari; two equilibria under constant primary deficits. Cite as recent working paper only. | VERIFIED | arxiv.org/abs/2510.26065 |
| 4 | Douenne, Dyrda, Hummel & Pedroni (2025), "Optimal Climate Policy with Incomplete Markets," **U Toronto Dept. of Economics WP tecipa-807**. | VERIFIED (paper); the claimed CEPR DP 20820 number could NOT be confirmed — cite the U Toronto WP | economics.utoronto.ca (tecipa-807) |
| 4b | Douenne, Hummel & Pedroni (2026), "Optimal Fiscal Policy in a Climate-Economy Model with Heterogeneous Households," **Economic Journal, advance article** (doi:10.1093/ej/ueag006; CEPR DP19151). Distinct paper — do not conflate with 4. | VERIFIED | academic.oup.com |
| 5 | Sahuc, Smets & Vermandel (2024), "The New Keynesian Climate Model," **Banque de France WP 977** (also SSRN 5035207). | VERIFIED | banque-france.fr |
| 6 | Nakov & Thomas (2026), "Climate-Conscious Monetary Policy," **JPE Macroeconomics, ahead of print** (doi:10.1086/740430; earlier ECB WP 2845). Cite the journal version. | VERIFIED | journals.uchicago.edu |
| 7 | Garcia-Macia, Lam & Nguyen (2024), "Public Debt Dynamics During the Climate Transition," **IMF WP/24/71**. | VERIFIED | elibrary.imf.org |
| 8 | Caselli, Lagerborg & Medas (2024), "Green Fiscal Rules? Challenges and Policy Alternatives," **IMF WP/24/125**. | VERIFIED | elibrary.imf.org |
| 9 | Anyfantaki, Blix Grimaldi, Madeira, Malovaná & Papadopoulos (2025), "Decoding Climate-Related Risks in Sovereign Bond Pricing: A Global Perspective," **BIS WP 1275**. | VERIFIED | bis.org/publ/work1275.htm |
| 10 | Ando, Fu, Roch & Wiriadinata (2022), "Sovereign Climate Debt Instruments: An Overview of the Green and Catastrophe Bond Markets," **IMF Staff Climate Note 2022/004**. | VERIFIED | imf.org |

## Discrepancies found and resolved

- Item 4: the roadmap's "CEPR DP 20820" could not be confirmed from any
  indexed source (CEPR/RePEc returned 403 through the proxy); the paper
  itself is real — `references.bib` cites the U Toronto WP number.
- Item 6: the "latest version" is now the JPE Macroeconomics article, which
  supersedes the ECB WP — bib updated accordingly.
- Item 1: still unpublished; cite as NBER WP, not as a journal article.

## Remaining [u] items in LITERATURE_MATRIX.md (NOT yet verified)

- Economides & Xepapadeas (NK + climate stabilization) — outlet unknown.
- IMF Fiscal Monitor *Climate Crossroads* chapter — exact edition to pin.
- Banque de France (Dees & Seghini), *The Green Transition and Public
  Finances* — outlet unknown.

These remain excluded from the paper draft until verified (project
standard: never cite an [u] item in a submission).

## Grouping for the related-literature section (Step 7 taxonomy)

- **DIRECT COMPETITORS:** Hagedorn (IER 2026); Kaplan–Nikolakoudis–Violante
  (NBER 31433); Angeletos–Lian–Wolf (ECMA 2024); Garcia-Macia–Lam–Nguyen
  (IMF 24/71); Caselli–Lagerborg–Medas (IMF 24/125);
  Douenne–Dyrda–Hummel–Pedroni (tecipa-807); Del Negro–di Giovanni–Dogra
  (NY Fed SR 1053); Sahuc–Smets–Vermandel (BdF 977).
- **METHODS:** Auclert–Bardóczy–Rognlie–Straub (ECMA 2021);
  Auclert–Rognlie–Straub (ARE 2025); Kaplan–Moll–Violante (AER 2018);
  Acharya–Challe–Dogra (AER 2023); Bilbiie (REStud); Acharya–Benhabib.
- **CALIBRATION:** Nordhaus/DICE; Golosov–Hassler–Krusell–Tsyvinski (ECMA
  2014); Dell–Jones–Olken; Burke–Hsiang–Miguel; Bilal–Känzig (NBER 32450);
  Bom–Ligthart (JES 2014); IEA/NGFS/IMF investment pathways.
- **VALIDATION:** Känzig (carbon-price incidence); Fried–Novan–Peterman;
  Anyfantaki et al. (BIS 1275); Baker–Bergstresser–Serafeim–Wurgler (green
  bonds); Ando et al. (IMF SCN 2022/004); Auclert et al. energy-shock HANK
  [u — verify before use].
