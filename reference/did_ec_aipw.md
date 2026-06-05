# DID-EC-AIPW method

Creates a method object for difference-in-differences augmented inverse
probability weighting (DID-EC-AIPW) estimation with external control
borrowing for the open-label extension phase (Zhou et al., 2024, Eq. 5).
Doubly robust: consistent if either the propensity score model or the
outcome model is correct.

## Usage

``` r
did_ec_aipw(
  ps_formula,
  trt_formula = NULL,
  outcome_formula,
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

- outcome_formula:

  Character vector of outcome model formulas, one per time point.

- bootstrap:

  Number of bootstrap replicates. Defaults to 500.

- bootstrap_ci_type:

  Bootstrap CI type. Defaults to `"perc"`.

## Value

An S4 object of class `did_ec_aipw_method`.

## References

Zhou et al. (2024). Estimating treatment effect in randomized trial
after control to treatment crossover using external controls. *Journal
of Biopharmaceutical Statistics*.
[doi:10.1080/10543406.2024.2444222](https://doi.org/10.1080/10543406.2024.2444222)

## Examples

``` r
did_ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5",
    "y3 ~ x1 + x2 + x3 + x4 + x5",
    "y4 ~ x1 + x2 + x3 + x4 + x5"
  ),
  bootstrap = 500
)
#> An object of class "did_ec_aipw_method"
#> Slot "ps_formula":
#> [1] "S ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "trt_formula":
#> [1] "A ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "outcome_formula":
#> [1] "y1 ~ x1 + x2 + x3 + x4 + x5" "y2 ~ x1 + x2 + x3 + x4 + x5"
#> [3] "y3 ~ x1 + x2 + x3 + x4 + x5" "y4 ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "method_name":
#> [1] "DID-EC-AIPW"
#> 
#> Slot "bootstrap":
#> [1] 500
#> 
#> Slot "bootstrap_ci_type":
#> [1] "perc"
#> 
```
