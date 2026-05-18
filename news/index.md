# Changelog

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

- Original package with boht IPW and AIPW methods
