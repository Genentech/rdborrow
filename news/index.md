# Changelog

## rdborrow (development version)

### Breaking changes

- [`setup_simulation_primary()`](https://genentech.github.io/rdborrow/reference/setup_simulation_primary.md)
  and
  [`setup_simulation_OLE()`](https://genentech.github.io/rdborrow/reference/setup_simulation_OLE.md)
  now require `true_effect` to be a single number, the true effect at
  the final visit.
  [`run_simulation()`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
  scores only the final visit, so a vector was recycled across simulated
  trials rather than matched to visits, and bias, coverage, type I
  error, and power were silently wrong unless every element was equal.
  With an even number of trials there was no warning
  ([\#90](https://github.com/Genentech/rdborrow/issues/90)).

### Minor improvements

- [`scm()`](https://genentech.github.io/rdborrow/reference/scm.md) now
  solves its optimizations with CVXR’s current interface (`psolve()` and
  `value()`) instead of [`solve()`](https://rdrr.io/r/base/solve.html)
  and `$getValue()`, which CVXR has deprecated and will remove. rdborrow
  now requires CVXR \>= 1.8.1. Estimates are unchanged
  ([\#97](https://github.com/Genentech/rdborrow/issues/97)).

### Bug fixes

- All method constructors now require `bootstrap` to be at least 2.
  `bootstrap = 1` was accepted and then failed inside
  [`run_analysis()`](https://genentech.github.io/rdborrow/reference/run_analysis.md)
  with an opaque confidence interval error
  ([\#91](https://github.com/Genentech/rdborrow/issues/91)).
- [`ec_ipw()`](https://genentech.github.io/rdborrow/reference/ec_ipw.md),
  [`ec_aipw()`](https://genentech.github.io/rdborrow/reference/ec_aipw.md),
  [`did_ec_ipw()`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md),
  and
  [`did_ec_aipw()`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md)
  now work when the trial-status column is not named `S`, and
  `trt_formula` works when the treatment column is not named `A`. The
  formula’s left-hand side was rewritten to the user’s column name after
  the data had been copied into columns named `S` and `A`, so the model
  could not find it, or silently used a same-named object from the R
  session ([\#103](https://github.com/Genentech/rdborrow/issues/103)).
- [`run_simulation()`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
  no longer errors with “‘x’ is NULL” when a method’s results have a
  single column. It kept the last row of each replicate without
  `drop = FALSE`, so a one-column data frame collapsed to a vector
  ([\#93](https://github.com/Genentech/rdborrow/issues/93)).

### Documentation

- Two new developer articles. “Adding a new method” explains how an
  estimator plugs into
  [`run_analysis()`](https://genentech.github.io/rdborrow/reference/run_analysis.md)
  and
  [`run_simulation()`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
  through S4 dispatch, walks through a runnable toy method, and gives a
  checklist for adding a method to the package
  ([\#87](https://github.com/Genentech/rdborrow/issues/87)). “Developing
  with AI coding agents” explains the new `AGENTS.md` file of agent
  instructions and gives a workflow, example prompts, and review habits
  for working on the package with an AI coding agent
  ([\#88](https://github.com/Genentech/rdborrow/issues/88)).

## rdborrow 0.0.4.2

CRAN release: 2026-10-01

### Bug fixes

- Two tests asserted exact floating-point equality between a marginal
  treatment model and an equivalent intercept-only model. The two are
  mathematically identical but computed by different routes, so they can
  differ in the last bit under BLAS libraries such as BLIS; both now
  compare with a tolerance.

## rdborrow 0.0.4.1

CRAN release: 2026-09-24

### Breaking changes

- `bootstrap_ci_type` no longer accepts `"stud"` in any method
  constructor. Studentized intervals require a variance estimate for
  each bootstrap replicate, which the estimators do not produce, so the
  option failed whenever it was used
  ([\#77](https://github.com/Genentech/rdborrow/issues/77)).

### Bug fixes

- Corrected the DOIs in the package references. The two DOIs cited in
  `DESCRIPTION` pointed to unrelated papers, and the open-label
  extension methods and vignettes cited an unrelated paper rather than
  Zhou X, Pang H, Drake C, Burger HU, Zhu J (2024). Reported by Herb
  Pang.
- `bootstrap_ci_type = "bca"` no longer errors. `boot.ci()` re-invokes
  the bootstrap statistic through `empinf()` without the arguments
  passed to `boot()`, so those are now captured in a closure
  ([\#77](https://github.com/Genentech/rdborrow/issues/77)).
- `bootstrap_ci_type = "norm"` no longer returns `NA` confidence bounds.
  The normal component of
  [`boot::boot.ci()`](https://rdrr.io/pkg/boot/man/boot.ci.html) output
  has three columns rather than five, so the fixed index used to read
  the bounds ran past the end of it
  ([\#77](https://github.com/Genentech/rdborrow/issues/77)).
- [`did_ec_ipw()`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md)
  and
  [`did_ec_aipw()`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md)
  no longer return `NA` estimates when `trt_formula` is left at its
  default of `NULL`. The marginal randomization probability was a
  scalar, so subsetting the treatment weights by a length-N logical
  produced `NA` for all but the first subject
  ([\#71](https://github.com/Genentech/rdborrow/issues/71)).

## rdborrow 0.0.4.0

CRAN release: 2026-08-31

### Breaking changes

- [`setup_bootstrap()`](https://genentech.github.io/rdborrow/reference/setup_bootstrap.md)
  has been removed. Bootstrap settings are now specified directly in
  method constructors (e.g.,
  `ec_ipw(bootstrap = 500, bootstrap_ci_type = "perc")`). Calling
  [`setup_bootstrap()`](https://genentech.github.io/rdborrow/reference/setup_bootstrap.md)
  now raises an error with migration instructions.
- [`setup_method_weighting()`](https://genentech.github.io/rdborrow/reference/setup_method_weighting.md),
  [`setup_method_DID()`](https://genentech.github.io/rdborrow/reference/setup_method_DID.md),
  and
  [`setup_method_SCM()`](https://genentech.github.io/rdborrow/reference/setup_method_SCM.md)
  have been removed. Use
  [`ec_ipw()`](https://genentech.github.io/rdborrow/reference/ec_ipw.md),
  [`ec_aipw()`](https://genentech.github.io/rdborrow/reference/ec_aipw.md),
  [`did_ec_ipw()`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md),
  [`did_ec_aipw()`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md),
  [`did_ec_or()`](https://genentech.github.io/rdborrow/reference/did_ec_or.md),
  or [`scm()`](https://genentech.github.io/rdborrow/reference/scm.md)
  instead. Calling the old constructors now raises an error with
  migration instructions.
- `EC_IPW_OPT()`, `EC_AIPW_OPT()`, and all `legacy_DID_EC_*` /
  `legacy_SCM*` internal functions have been deleted.
- [`did_ec_ipw()`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md)
  and
  [`did_ec_aipw()`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md):
  `trt_formula` default changed from `""` to `NULL`.

### Changes

- [`ec_ipw()`](https://genentech.github.io/rdborrow/reference/ec_ipw.md)
  and
  [`ec_aipw()`](https://genentech.github.io/rdborrow/reference/ec_aipw.md)
  QC’d against Zhou et al. (2024a, JRSS-A). Internal code now maps
  directly to paper equations (Def 1/2, Eq 6/7, Theorems 3/4).
- All estimator internals refactored: redundant parameters removed,
  `potential` trick replaced with direct weighted means, consistent
  naming (`_core`, `_se`, `_boot_statistic`).
- `build_analysis_df()` is now an S4 method on `method_weighting_obj`.
- Bootstrap logic moved from `.format_primary_results()` (deleted) to
  inline control flow in each
  [`estimate()`](https://genentech.github.io/rdborrow/reference/estimate.md)
  method.
- Added input validation: S/A must be binary 0/1, `T_cross` must be a
  positive integer less than the number of outcomes, `outcome_formula`
  length must match number of outcomes.
- Vignette improvements: `T_cross` semantics documented,
  [`head()`](https://rdrr.io/r/utils/head.html) calls added,
  rank-deficiency warnings suppressed in OLE simulation output.

## rdborrow 0.0.3.0

### Changes

- New API introduced: eg
  [`ec_ipw()`](https://genentech.github.io/rdborrow/reference/ec_ipw.md)
  and
  [`ec_aipw()`](https://genentech.github.io/rdborrow/reference/ec_aipw.md)
  replace
  [`setup_method_weighting()`](https://genentech.github.io/rdborrow/reference/setup_method_weighting.md).
- Internally, core functions such as `EC_IPW_OPT()` are further broken
  down into atomic functions.
- Bootstrapping functions now call atomic functions (instead of similar,
  duplicated code).
- Additional test cases in preparation of deprecating legacy\_ functions
  such as `EC_IPW_OPT()`.
- Bug fixes (AIPW called the IPW bootstrapping function)

## rdborrow 0.0.2.0

### Changes

- Refactor out imports, prepare for CRAN

## rdborrow 0.0.1.0

### Changes

- Original package with both IPW and AIPW methods
