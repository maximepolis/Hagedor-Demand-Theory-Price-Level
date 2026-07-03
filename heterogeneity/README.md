# heterogeneity — Dynare HANK framework examples (drop-in folder)

**Status: files NOT yet in the repository.** Place your Dynare-HANK example
files here (same commands as the neighboring drop-in folders, with this
folder name).

## Why this matters for the roadmap

`appendix/HANK_TRANSITION_PLAN.md` (U7) currently specifies a hand-rolled
sequence-space implementation in MATLAB. Recent Dynare versions ship a
native heterogeneity framework for heterogeneous-agent models. If your
examples cover it, U7 can potentially be implemented directly in Dynare:

1. map our household block (CRRA, borrowing limit, Rouwenhorst income) into
   the framework's heterogeneous-agent declarations;
2. add the climate block (kg, x, d) and the nominal-debt/price-level
   equation as aggregate equations;
3. reproduce the package's stationary equilibria as the framework's steady
   state (validation), then run the program-announcement transition and the
   financing-regime transitions.

Once the files are pushed I will inspect them, judge feasibility against
the plan, and either port U7 to Dynare or keep the sequence-space route
with reasons documented.
