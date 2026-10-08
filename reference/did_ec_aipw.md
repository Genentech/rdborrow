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
  participation. The right-hand side should use only columns in
  `covariates_col_name`. `.` or any other column is an error; an outcome
  gives a warning, because adjusting for an outcome measured after
  randomization can bias the treatment effect.

- trt_formula:

  Formula string for the treatment assignment model, or `NULL` (default)
  for the marginal probability of treatment in the trial. The model is
  fit on trial patients only, and its predicted probabilities set the
  inverse-probability weights of trial treated and trial control
  patients. The left-hand side is replaced by the treatment column, so
  it can be any name. The right-hand side should use only columns in
  `covariates_col_name`. `.` or any other column is an error; an outcome
  gives a warning, because adjusting for an outcome measured after
  randomization can bias the treatment effect.

- outcome_formula:

  Character vector of outcome model formulas, one per outcome. Each
  formula is matched to an outcome by its left-hand side, so the order
  does not matter. The left-hand side must be the outcome name itself;
  to model a transformed outcome, transform the column first. The
  right-hand side should use only columns in `covariates_col_name`. `.`
  or any other column is an error; an outcome gives a warning, because
  adjusting for an outcome measured after randomization can bias the
  treatment effect.

- bootstrap:

  Number of bootstrap replicates (at least 2). Defaults to 500. Use
  about 1000 or more for reported intervals; small values are for quick
  checks only, and their interval can exclude the point estimate.

- bootstrap_ci_type:

  Bootstrap CI type: one of `"perc"` (default), `"bca"`, `"norm"`, or
  `"basic"`. `"bca"` is slow when `bootstrap` is smaller than the number
  of patients:
  [`boot::boot.ci()`](https://rdrr.io/pkg/boot/man/boot.ci.html) then
  refits the estimator once for each patient.

## Value

An S4 object of class `did_ec_aipw_method`.

## References

Zhou et al. (2024). Estimating treatment effect in randomized trial
after control to treatment crossover using external controls. *Journal
of Biopharmaceutical Statistics*.
[doi:10.1080/10543406.2024.2330209](https://doi.org/10.1080/10543406.2024.2330209)

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
