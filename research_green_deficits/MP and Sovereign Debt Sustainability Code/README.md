# Hurtado–Nuño–Thomas (JEEA 2023) replication package — drop-in folder

**Expected contents (currently on your local machine, not yet committed):**

```
a_inf/        model variant code (inflation-choice model)
a_noi/        model variant code (no-inflation benchmark)
c_graphs/     figure-generation scripts
jvac035.pdf   Hurtado, Nuño & Thomas, "Monetary Policy and Sovereign Debt
              Sustainability", Journal of the European Economic Association
              21(1), 2023, 293-325 (doi: 10.1093/jeea/jvac035)
jvac035_hurtado_nuno_thomas_online_appendix.pdf
readme.txt    authors' replication notes
```

**How to add them (from your Windows machine, repo root):**

```
git checkout claude/hagedorn-dtpl-matlab-9abghk
xcopy "C:\Users\up24706\Downloads\MP and Sovereign Debt Sustainability Code" ^
      "research_green_deficits\MP and Sovereign Debt Sustainability Code" /E /I
git add "research_green_deficits/MP and Sovereign Debt Sustainability Code"
git commit -m "Add Hurtado-Nuno-Thomas (JEEA 2023) replication package"
git push
```

*Note: the two PDFs are published, copyrighted articles. Committing them to a
private working repo is common practice for a research team; do not include
them if this repository is ever made public — link the DOI instead.*

## Relevance to this project (assessment)

Hurtado, Nuño and Thomas study a small open economy issuing **long-term
nominal debt without commitment**, where **inflation acts as a
state-contingent partial default**: the option to erode the real value of
debt through inflation is less costly than outright default, which reduces
default incentives and enlarges the repayment region.

Three direct connections to our paper:

1. **Disciplines the revaluation channel (our `nu_reval`).** Their framework
   prices the government's *incentive* to use inflation against nominal
   debt-holders. Our calibrated finding is that green programs move the
   revaluation channel *against* the fisc (green disinflation,
   `nu_reval ≈ −0.06`); their model supplies the natural counter-force —
   a government tempted to inflate — and hence bounds how much revaluation
   financing is credible in equilibrium. This is the missing
   commitment/credibility dimension of our Proposition 2.
2. **Template for roadmap U5 (debt maturity).** They model long-duration
   nominal bonds explicitly; their bond-pricing block is the natural way to
   implement our geometric-coupon maturity extension, which bounds the
   revaluation channel honestly (referee risk R9).
3. **Sovereign-risk block (literature block G).** Their default margin
   connects our fiscal-space-collapse result (equilibrium non-existence
   under regressive damages + tight money) to an explicit default decision:
   in their language, our collapse region is where the repayment set
   empties. A climate-augmented HNT economy — damages shrinking the
   repayment region, green investment enlarging it — is a natural companion
   paper.

**Classification for LITERATURE_MATRIX.md:** building block (U5 maturity;
sovereign-risk discipline) and calibration/validation source for the
credibility limits of revaluation financing; cite in the introduction's
revaluation discussion, the model section's maturity extension, and the
referee memo's R9 response. Entry added to `paper/references.bib` as
`hurtado2023sovereign` (verified).
