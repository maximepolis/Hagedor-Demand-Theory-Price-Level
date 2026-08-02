# Function-path exposure and the namespacing plan (R11)

The D10 refactor moved ten functions from `main_twoasset_ownership_kv.m`'s
local-function block into `src_project/`. Their bodies are unchanged. Their
**visibility** is not: a local function is visible to one file, a file
function is visible to everything on the path. That is a behavioural change
from the project's point of view even when no line of the body moved.

---

## 1. The collision that already exists, and why it is blocking

Two files named `solve_household_egm.m`, with **different signatures**:

| file | signature | outputs |
|---|---|---|
| `src/solve_household_egm.m` | `[V, polA_idx, polA, polC, hhdiag] = f(r, tau, params)` | 5 |
| `src_project/solve_household_egm.m` | `[V, polA, polC, hhdiag] = f(r, tau, p)` | 4 |

Two callers with incompatible expectations:

| caller | line | asks for |
|---|---|---|
| `src/aggregate_asset_demand.m` | 136 | `[~, polA_idx, polA, polC, hhdiag] = solver(...)` — 5 |
| `src_project/S_green.m` | 108 | `[V, polA, polC, hhdiag] = solve_household_egm(...)` — 4 |

**One polarity fails silently.** Which one you get is decided by the order of
two `addpath` calls.

- **`src_project` wins** (today's order): the `src` caller requests five
  outputs from a four-output function and MATLAB errors. Loud, immediate,
  harmless. This is the safe polarity.
- **`src` wins**: `S_green` requests four outputs from a five-output function
  and *gets them*, bound as

  ```
  polA   <- polA_idx     integer grid INDICES, 1..na
  polC   <- polA         asset levels
  hhdiag <- polC         consumption
  ```

  **No error is raised.** Asset grid indices would be used as asset holdings
  and the run would complete and produce numbers.

Every driver currently does
`addpath(genpath(.../src)); addpath(genpath(.../src_project));`
and `addpath` prepends, so the second call wins and the safe polarity holds —
**by accident of ordering, not by design**. `restoredefaultpath` followed by a
different order flips it. That is why the user's Step 0 (`restoredefaultpath;
run_project_path_setup`) is exactly the right precaution and why it must run
before parity, not after.

### Interim guard (in place now)

`run_project_path_setup.m` declares the precedence explicitly (`-begin` written
out rather than relying on `addpath`'s default), enumerates every filename
shared by the two trees, and **errors** if any resolves outside
`src_project/`. `main_function_provenance_r10.m` additionally reports the
declared **output arity** of each colliding file, because the hazard is not
that two files exist — it is that they return different numbers of outputs.

---

## 2. The permanent fix: rename, not ordering

A path-order guard is a guard, not a fix. Two stages, in this order:

### Stage 1 — parity under a frozen path (BEFORE any rename)

Run the three-way D10/D11 parity against `bf0a4e8` with the path fixed by
`run_project_path_setup`. Renaming first would change two things at once and
make a parity failure uninterpretable.

### Stage 2 — namespace, then re-run parity

| current name | becomes | why |
|---|---|---|
| `src_project/solve_household_egm.m` | `solve_household_egm_green.m` | different contract from the `src/` function; not a `kv_` helper, so a descriptive suffix is right. Update `S_green.m:108` and `verify_egm_vs_vfi.m`. |
| `resid_of.m` | `kv_resid_of.m` | generic; was local |
| `report2d.m` | `kv_report2d.m` | generic; was local |
| `eval_own.m` | `kv_eval_own.m` | generic; was local |
| `bracket_finite.m` | `kv_bracket_own.m` | **most dangerous name in the set** — and it already sits beside `kv_bracket_finite.m`, which is a *different* bracketing routine. Two similarly named bracketers one letter apart is a defect waiting to happen. |
| `calib_beta.m` | `kv_calib_beta.m` | generic; was local |
| `calib_chi.m` | `kv_calib_chi.m` | generic; was local |
| `calib_beta_chi.m` | `kv_calib_beta_chi.m` | generic; was local |
| `solve_own_kv.m` | `kv_solve_own.m` | already project-marked; renamed for consistency of prefix position |
| `kv_agg.m` | *(unchanged)* | already prefixed |
| `htm_bk.m` | `kv_htm_bk.m` | generic; was local |

**Prefix over package.** A `+kv/` package is the cleaner namespace in the
abstract, but it forces every call site to `kv.calib_beta(...)` or an
`import`, and `import` is scoped per-function — so a `parfor` worker or a
function handle built in one file and evaluated in another silently loses it.
This project already builds handles across files (`pick_solver` returns
`@solve_household_egm`). The `kv_` prefix has the same disambiguating effect
with no scoping semantics to get wrong.

### Stage 3 — re-run parity after the rename

Against the **same** frozen baseline. A rename should be a no-op numerically;
if it is not, something was resolving to a file nobody intended.

---

## 3. `download_data.m`: parser limitation, not a file defect

**Question asked:** is the block-parser failure a defect in `download_data.m`
or a limitation of the parser?

**Answer: the parser.** No exclusion is recorded, and the data pipeline is not
modified.

The earlier report came from an ad-hoc keyword count, not from a committed
tool. `paper/check_matlab_blocks.py` now implements MATLAB's actual lexical
rules — `end` as a subscript, one-line blocks, block comments, and the
overloaded apostrophe — and self-tests on 18 controls (`--selftest`).

My **first** version of that parser still failed the file, at line 116:

```matlab
rec.key = [iso3 '|' R.date];
```

It tracked the last non-*space* significant character before a quote, saw
`iso3`, and read `'` as a **transpose**. MATLAB reads `'` as a transpose only
when it *immediately* follows a value; inside `[]` a space is a column
separator, so that quote opens a string. Misreading it swallowed the rest of
the line as code and lost the `end` tokens that followed — five spurious
"unclosed blocks" in a perfectly well-formed file.

With the rule corrected to use the immediately preceding character:

```
267 file(s) checked, 0 unbalanced
```

`download_data.m` is well-formed MATLAB. It uses a **nested function**
(`fetch_indicator`, line 96, inside the parent's body), which is legal and
which naive parsers routinely mis-balance. Nothing about it needs changing.

**The general rule this establishes:** when a static check disagrees with
working code, the burden is on the check. The file was correct; two successive
versions of my tooling were not.

---

## 4. Status

| item | state |
|---|---|
| collision detected and named | done |
| silent-corruption polarity identified | done |
| interim path guard | `run_project_path_setup.m`, errors on the unsafe polarity |
| provenance audit driver | `main_function_provenance_r10.m` |
| `which -all` + SHA-256 for 47 critical names | in the audit |
| rename | **not done** — deliberately deferred until parity passes |
| `download_data.m` | no change; parser fixed instead |
