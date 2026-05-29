# DID-EC-IPW method

Creates a method object for difference-in-differences inverse
probability weighting (DID-EC-IPW) estimation with external control
borrowing for the open-label extension phase (Zhou et al., 2024, Eq. 4).

## Usage

``` r
did_ec_ipw(
  ps_formula,
  trt_formula = NULL,
  bootstrap = 500L,
  bootstrap_ci_type = NULL
)
```

## Arguments

- ps_formula:

  Formula string for the propensity score model predicting trial
  participation.

- trt_formula:

  Formula string for the treatment assignment model, or `NULL` (default)
  for marginal probability.

- bootstrap:

  Number of bootstrap replicates (required for DID methods). Defaults to
  500.

- bootstrap_ci_type:

  Bootstrap CI type. Defaults to `"perc"`.

## Value

An S4 object of class `did_ec_ipw_method`.

## References

Zhou et al. (2024). Estimating treatment effect in randomized trial
after control to treatment crossover using external controls. *Journal
of Biopharmaceutical Statistics*.
[doi:10.1080/10543406.2024.2444222](https://doi.org/10.1080/10543406.2024.2444222)

## Examples

``` r
did_ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
  bootstrap = 500
)
#> An object of class "did_ec_ipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "trt_formula":
#> [1] "A ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "bootstrap":
#> [1] 500
#> 
#> Slot "bootstrap_ci_type":
#> [1] "perc"
#> 
#> Slot "bootstrap_flag":
#> [1] TRUE
#> 
#> Slot "bootstrap_obj":
#> <bootstrap_obj>
#>   Replicates: 500 
#>   CI type: Percentile 
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
#> [1] "DID-EC-IPW"
#> 
```
