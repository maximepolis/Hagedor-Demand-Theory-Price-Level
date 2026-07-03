# Data folder

- `green_budget_panel.csv` — **PLACEHOLDER: header-only schema, NO data.**
  E2 green-budget denomination registry (one row per program). Populate
  only from primary budget documents; record source_document + source_url
  per row. The project standard forbids fabricated rows; the loader and
  empirical scripts skip E2 while the file has no data rows.
  This program-level registry complements the country-year schema expected
  by `src_project/load_green_budget_data.m` (E2a aggregate panel); the
  loader will be extended when real rows exist.
- `wb_panel.csv` — World Bank panel downloaded by `download_data.m`
  (user-run; 7,684 country-year rows on the user machine — not committed
  here if absent).
