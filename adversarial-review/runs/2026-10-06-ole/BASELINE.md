# OLE pilot baseline (2026-10-06)

Phase 0 record for the open-label extension run of #101. The package code,
review library, and baseline results are the same as for the primary-analysis
pilot: `main` has not changed. See `../2026-10-06-pilot/BASELINE.md`.

| Item | Value |
|---|---|
| `main` commit | `6185ba9` (0.0.4.2) |
| Review library | the same build of `6185ba9` used for the primary pilot |
| Baseline tests | `NOT_CRAN=true devtools::test()`: 0 fail, 20 known warnings (#86), 416 pass |
| Baseline check | 0 errors, 0 warnings, 0 notes |

## Scope

`did_ec_ipw()`, `did_ec_aipw()`, `did_ec_or()`, and `scm()`; `setup_analysis_OLE()`
and the OLE path of `run_analysis()`; the internals
`.did_ec_ipw_core()`, `.did_ec_aipw_core()`, `.did_ec_or_core()`,
`.scm_subject_sc()`, `.scm_lambdacv()`, their bootstrap statistics,
`.run_bootstrap()`, `.ec_weights()`, and `.build_analysis_df()`; and their
documentation.

Specification: paper 2 (Zhou et al. 2024, *J Biopharm Stat*), including
Appendices A–E.

## Known issues given to the testers

#103–#108 from the primary pilot. #103 is confirmed for `did_ec_ipw()` and
`did_ec_aipw()`. #104 is not yet checked for `did_ec_aipw()` or `did_ec_or()`.
Also #86, #79, #83, #84.

## Settings

The same as the primary pilot: four independent fresh agents in their own
worktrees, no planted defects, a cap of about 15 confirmed findings each, and
`mutator` with `cran = FALSE`, `isolate = TRUE`, `detectEqMutants = FALSE`.
Because the OLE methods use bootstrap inference only, and `scm()` solves an
optimization for every trial control patient, the Monte Carlo and mutation
budgets are smaller than in the primary pilot.
