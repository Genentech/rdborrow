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
  participation.

- outcome_formula:

  Character vector of outcome model formulas, one per time point (e.g.,
  `c("y1 ~ x1 + x2", "y2 ~ x1 + x2")`).

- weight:

  Borrowing weight. `NULL` (default) for data-adaptive optimal weight,
  `0` for RCT-only, or a value in (0, 1\].

- bootstrap:

  Number of bootstrap replicates, or `NULL` (default) for sandwich
  variance with normal CIs.

- bootstrap_ci_type:

  Bootstrap CI type. Defaults to `"perc"`.

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

# no borrowing
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
