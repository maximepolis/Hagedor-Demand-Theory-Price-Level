# Policy transition risk, carbon premiums, and asset prices — drop-in folder

**Status: files NOT yet in the repository.** They exist only on your local
machine; nothing arrived on the remote or in chat. Place them here:

```
git checkout claude/hagedorn-dtpl-matlab-9abghk
git pull    (or re-download the branch ZIP first if working manually)
xcopy "C:\...\<your local folder>" "Policy Transition Risk Carbon Premiums and Asset Prices" /E /I
git add "Policy Transition Risk Carbon Premiums and Asset Prices"
git commit -m "Add transition-risk asset-pricing MATLAB package"
git push
```
(If you cannot push, upload via the GitHub web UI on the branch — Add file →
Upload files — or attach the key .m files directly in chat.)

## Planned use once the files arrive (assessment to be verified against the code)

1. **Transition-risk pricing for the E3 event study**: if the package prices
   carbon premia / transition-risk shocks, its identification or pricing
   kernel can discipline the sign test of our revaluation channel
   (announcement effects on nominal yields and breakevens).
2. **Greenium wedge**: a quantitative anchor for the planned sovereign
   green-bond spread (lambda^g) margin flagged in the literature section.
3. **Brown-capital stranding**: inputs for the staged U8 clean/dirty
   production block (Fried–Novan–Peterman-style transition risk).
