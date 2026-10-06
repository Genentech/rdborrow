# Pilot baseline (2026-10-06)

Phase 0 record for the primary-analysis pilot of #101.

| Item | Value |
|---|---|
| Review branch commit | `3cc1ec0` (`adversarial-review`; package code identical to `main`) |
| `main` commit | `6185ba9` |
| R | 4.6.1 |
| BLAS | OpenBLAS (pthread) |
| rdborrow under review | 0.0.4.2 (development version on `main`), installed into a separate review library; the user library still has CRAN 0.0.4.1 |
| testthat / devtools | 3.3.2 / 2.5.2 |
| boot / CVXR | 1.3.32 / 1.9.1 |
| mutator / quickcheck / autotest | 0.2.1 / 0.1.3 / 0.2.0 |

## Baseline results

- `NOT_CRAN=true devtools::test()`: `[ FAIL 0 | WARN 20 | SKIP 0 | PASS 416 ]`. The 20 warnings are the known rank-deficiency warnings from #86.
- `devtools::check(vignettes = FALSE)`: 0 errors, 0 warnings, 0 notes.

## Pilot scope

`ec_ipw()` and `ec_aipw()`, plus everything they call: `.ec_weights()`, `.ec_ipw_core()`, `.ec_ipw_se()`, `.ec_ipw_boot_statistic()`, `.ec_aipw_core()`, `.ec_aipw_se()`, `.ec_aipw_boot_statistic()`, `.run_bootstrap()`, `.build_analysis_df()`, `setup_analysis_primary()`, `run_analysis()`, and their documentation.

Specification: paper 1 (Zhou et al. 2025, *JRSS-A*) and its supplement.

## Settings

- Four independent testers, each in its own worktree. Fresh agents, not forks, so findings are independent.
- No planted defects in this run; those are reserved for the phase 4 evaluation.
- Cap of about 15 confirmed findings per tester.
- `mutator`: `cran = FALSE` (so `skip_on_cran()` tests run), `isolate = TRUE`, `detectEqMutants = FALSE` (AI classifier off), bounded `max_mutants`.
