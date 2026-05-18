# rdborrow 0.0.3.0

## Changes
- New API introduced: eg `ec_ipw()` and `ec_aipw()` replace `setup_method_weighting()`. 
- Internally, core functions such as `EC_IPW_OPT()` are further broken down into atomic functions.
- Bootstrapping functions now call atomic functions (instead of similar, duplicated code).
- Additional test cases in preparation of deprecating legacy_ functions such as `EC_IPW_OPT()`.
- Bug fixes (AIPW called the IPW bootstrapping function)

# rdborrow 0.0.2.0

## Changes
- Refactor out imports, prepare for CRAN

# rdborrow 0.0.1.0

## Changes
- Original package with boht IPW and AIPW methods