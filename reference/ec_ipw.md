# EC-IPW method constructor

Creates a method object for IPW estimation with external control
borrowing (Zhou et al., 2024). Pass to
[`setup_analysis_primary`](https://genentech.github.io/rdborrow/reference/setup_analysis_primary.md)
and
[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md).

## Usage

``` r
ec_ipw(ps_formula, weight = NULL, bootstrap = NULL, bootstrap_ci_type = NULL)
```

## Arguments

- ps_formula:

  Formula string for the propensity score model predicting trial
  participation. The left-hand side is replaced internally (e.g.,
  `"S ~ x1 + x2 + x3"`).

- weight:

  Borrowing weight. `NULL` (default) for data-adaptive optimal weight,
  `0` for RCT-only, or a value in (0, 1\].

- bootstrap:

  Number of bootstrap replicates, or `NULL` (default) for sandwich
  variance with normal CIs.

- bootstrap_ci_type:

  Bootstrap CI type, or `NULL` (default) which resolves to `"perc"` when
  `bootstrap` is set. One of `"perc"`, `"bca"`, `"norm"`, `"basic"`, or
  `"stud"`.

## Value

An S4 object of class `ec_ipw_method`.

## References

Zhou et al. (2024). Causal estimators for incorporating external
controls in randomized trials with longitudinal outcomes. *JRSS-A*.
[doi:10.1093/jrsssa/qnae075](https://doi.org/10.1093/jrsssa/qnae075)

## Examples

``` r
# optimal weight, sandwich SE
ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
#> An object of class "ec_ipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "weight":
#> NULL
#> 
#> Slot "bootstrap":
#> NULL
#> 
#> Slot "bootstrap_ci_type":
#> NULL
#> 
#> Slot "optimal_weight_flag":
#> [1] FALSE
#> 
#> Slot "wt":
#> [1] 0
#> 
#> Slot "model_form_piS":
#> [1] ""
#> 
#> Slot "model_form_piA":
#> [1] ""
#> 
#> Slot "model_form_mu0_ext":
#> [1] ""
#> 
#> Slot "model_form_mu0_rct":
#> [1] ""
#> 
#> Slot "model_form_mu1_rct":
#> [1] ""
#> 
#> Slot "method_name":
#> [1] "EC-IPW"
#> 
#> Slot "bootstrap_flag":
#> [1] FALSE
#> 
#> Slot "bootstrap_obj":
#> <bootstrap_obj>
#>   Replicates: 500 
#>   CI type: Percentile 
#> 

# no borrowing
ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5", weight = 0)
#> An object of class "ec_ipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "weight":
#> [1] 0
#> 
#> Slot "bootstrap":
#> NULL
#> 
#> Slot "bootstrap_ci_type":
#> NULL
#> 
#> Slot "optimal_weight_flag":
#> [1] FALSE
#> 
#> Slot "wt":
#> [1] 0
#> 
#> Slot "model_form_piS":
#> [1] ""
#> 
#> Slot "model_form_piA":
#> [1] ""
#> 
#> Slot "model_form_mu0_ext":
#> [1] ""
#> 
#> Slot "model_form_mu0_rct":
#> [1] ""
#> 
#> Slot "model_form_mu1_rct":
#> [1] ""
#> 
#> Slot "method_name":
#> [1] "EC-IPW"
#> 
#> Slot "bootstrap_flag":
#> [1] FALSE
#> 
#> Slot "bootstrap_obj":
#> <bootstrap_obj>
#>   Replicates: 500 
#>   CI type: Percentile 
#> 

# optimal weight with bootstrap
ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  bootstrap = 500
)
#> An object of class "ec_ipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "weight":
#> NULL
#> 
#> Slot "bootstrap":
#> [1] 500
#> 
#> Slot "bootstrap_ci_type":
#> [1] "perc"
#> 
#> Slot "optimal_weight_flag":
#> [1] FALSE
#> 
#> Slot "wt":
#> [1] 0
#> 
#> Slot "model_form_piS":
#> [1] ""
#> 
#> Slot "model_form_piA":
#> [1] ""
#> 
#> Slot "model_form_mu0_ext":
#> [1] ""
#> 
#> Slot "model_form_mu0_rct":
#> [1] ""
#> 
#> Slot "model_form_mu1_rct":
#> [1] ""
#> 
#> Slot "method_name":
#> [1] "EC-IPW"
#> 
#> Slot "bootstrap_flag":
#> [1] TRUE
#> 
#> Slot "bootstrap_obj":
#> <bootstrap_obj>
#>   Replicates: 500 
#>   CI type: Percentile 
#> 

# fixed weight with bootstrap
ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  weight = 0.3,
  bootstrap = 500
)
#> An object of class "ec_ipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "weight":
#> [1] 0.3
#> 
#> Slot "bootstrap":
#> [1] 500
#> 
#> Slot "bootstrap_ci_type":
#> [1] "perc"
#> 
#> Slot "optimal_weight_flag":
#> [1] FALSE
#> 
#> Slot "wt":
#> [1] 0
#> 
#> Slot "model_form_piS":
#> [1] ""
#> 
#> Slot "model_form_piA":
#> [1] ""
#> 
#> Slot "model_form_mu0_ext":
#> [1] ""
#> 
#> Slot "model_form_mu0_rct":
#> [1] ""
#> 
#> Slot "model_form_mu1_rct":
#> [1] ""
#> 
#> Slot "method_name":
#> [1] "EC-IPW"
#> 
#> Slot "bootstrap_flag":
#> [1] TRUE
#> 
#> Slot "bootstrap_obj":
#> <bootstrap_obj>
#>   Replicates: 500 
#>   CI type: Percentile 
#> 
```
