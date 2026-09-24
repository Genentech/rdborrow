# Changelog

## rdborrow (development version)

### Breaking changes

- `bootstrap_ci_type` no longer accepts `"stud"` in any method
  constructor. Studentized intervals require a variance estimate for
  each bootstrap replicate, which the estimators do not produce, so the
  option failed whenever it was used
  ([\#77](https://github.com/Genentech/rdborrow/issues/77)).

### Bug fixes

- `bootstrap_ci_type = "norm"` no longer returns `NA` confidence bounds.
  The normal component of
  [`boot::boot.ci()`](https://rdrr.io/pkg/boot/man/boot.ci.html) output
  has three columns rather than five, so the fixed index used to read
  the bounds ran past the end of it
  ([\#77](https://github.com/Genentech/rdborrow/issues/77)).
- `bootstrap_ci_type = "bca"` no longer errors. `boot.ci()` re-invokes
  the bootstrap statistic through `empinf()` without the arguments
  passed to `boot()`, so those are now captured in a closure
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
