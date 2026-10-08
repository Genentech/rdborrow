# EC-AIPW method

Creates a method object for augmented IPW estimation with external
control borrowing (Zhou et al., 2024). Augments the IPW estimator with
an outcome regression model for improved efficiency. Pass to
[`setup_analysis_primary`](https://genentech.github.io/rdborrow/reference/setup_analysis_primary.md)
and
[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md).

## Usage

``` r
ec_aipw(
  ps_formula,
  outcome_formula,
  weight = NULL,
  bootstrap = NULL,
  bootstrap_ci_type = NULL
)
```

## Arguments

- ps_formula:

  Formula string for the propensity score model predicting trial
  participation. The right-hand side should use only columns in
  `covariates_col_name`. `.` or any other column is an error; an outcome
  gives a warning, because adjusting for an outcome measured after
  randomization can bias the treatment effect.

- outcome_formula:

  Character vector of outcome model formulas, one per outcome (e.g.,
  `c("y1 ~ x1 + x2", "y2 ~ x1 + x2")`). Each formula is matched to an
  outcome by its left-hand side, so the order does not matter. The
  left-hand side must be the outcome name itself; to model a transformed
  outcome, transform the column first. The right-hand side should use
  only columns in `covariates_col_name`. `.` or any other column is an
  error; an outcome gives a warning, because adjusting for an outcome
  measured after randomization can bias the treatment effect.

- weight:

  Borrowing weight. `NULL` (default) for data-adaptive optimal weight,
  `0` for no direct borrowing, or a value in (0, 1\]. At `0` the
  external controls get no weight, but the outcome model is still fit on
  all controls, trial and external (as in Zhou et al., Theorem 2). The
  estimate stays valid by randomization alone; the external data affect
  only its precision. Unlike
  [`ec_ipw`](https://genentech.github.io/rdborrow/reference/ec_ipw.md),
  it therefore does not use trial data only.

- bootstrap:

  Number of bootstrap replicates (at least 2), or `NULL` (default) for
  sandwich variance with normal CIs.

- bootstrap_ci_type:

  Bootstrap CI type, or `NULL` (default) which resolves to `"perc"` when
  `bootstrap` is set. One of `"perc"`, `"bca"`, `"norm"`, or `"basic"`.
  Needs `bootstrap`.

## Value

An S4 object of class `ec_aipw_method`.

## References

Zhou et al. (2024). Causal estimators for incorporating external
controls in randomized trials with longitudinal outcomes. *JRSS-A*.
[doi:10.1093/jrsssa/qnae075](https://doi.org/10.1093/jrsssa/qnae075)

## Examples

``` r
# optimal weight, sandwich SE
ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)
#> An object of class "ec_aipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "outcome_formula":
#> [1] "y1 ~ x1 + x2 + x3 + x4 + x5" "y2 ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "weight":
#> NULL
#> 
#> Slot "method_name":
#> [1] "EC-AIPW"
#> 
#> Slot "bootstrap":
#> NULL
#> 
#> Slot "bootstrap_ci_type":
#> NULL
#> 

# no direct borrowing
ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  ),
  weight = 0
)
#> An object of class "ec_aipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "outcome_formula":
#> [1] "y1 ~ x1 + x2 + x3 + x4 + x5" "y2 ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "weight":
#> [1] 0
#> 
#> Slot "method_name":
#> [1] "EC-AIPW"
#> 
#> Slot "bootstrap":
#> NULL
#> 
#> Slot "bootstrap_ci_type":
#> NULL
#> 

# fixed weight with bootstrap
ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  ),
  weight = 0.3,
  bootstrap = 500
)
#> An object of class "ec_aipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "outcome_formula":
#> [1] "y1 ~ x1 + x2 + x3 + x4 + x5" "y2 ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "weight":
#> [1] 0.3
#> 
#> Slot "method_name":
#> [1] "EC-AIPW"
#> 
#> Slot "bootstrap":
#> [1] 500
#> 
#> Slot "bootstrap_ci_type":
#> [1] "perc"
#> 
```
