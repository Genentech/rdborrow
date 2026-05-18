# DID-EC-OR method constructor

Creates a method object for difference-in-differences outcome regression
estimation with external control borrowing for the open-label extension
phase (Zhou et al., 2024).

## Usage

``` r
did_ec_or(
  outcome_formula_ext,
  outcome_formula_rct_ctrl,
  outcome_formula_rct_trt,
  bootstrap = 500L,
  bootstrap_ci_type = NULL
)
```

## Arguments

- outcome_formula_ext:

  Character vector of outcome model formulas for external controls, one
  per time point.

- outcome_formula_rct_ctrl:

  Character vector of outcome model formulas for RCT control subjects,
  one per time point.

- outcome_formula_rct_trt:

  Character vector of outcome model formulas for RCT treated subjects,
  one per time point.

- bootstrap:

  Number of bootstrap replicates. Defaults to 500.

- bootstrap_ci_type:

  Bootstrap CI type. Defaults to `"perc"`.

## Value

An S4 object of class `did_ec_or_method`.

## References

Zhou et al. (2024). Estimating treatment effect in randomized trial
after control to treatment crossover using external controls. *Journal
of Biopharmaceutical Statistics*.
[doi:10.1080/10543406.2024.2444222](https://doi.org/10.1080/10543406.2024.2444222)

## Examples

``` r
model_forms <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)
did_ec_or(
  outcome_formula_ext = model_forms,
  outcome_formula_rct_ctrl = model_forms,
  outcome_formula_rct_trt = model_forms,
  bootstrap = 500
)
#> An object of class "did_ec_or_method"
#> Slot "outcome_formula_ext":
#> [1] "y1 ~ x1 + x2 + x3 + x4 + x5" "y2 ~ x1 + x2 + x3 + x4 + x5"
#> [3] "y3 ~ x1 + x2 + x3 + x4 + x5" "y4 ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "outcome_formula_rct_ctrl":
#> [1] "y1 ~ x1 + x2 + x3 + x4 + x5" "y2 ~ x1 + x2 + x3 + x4 + x5"
#> [3] "y3 ~ x1 + x2 + x3 + x4 + x5" "y4 ~ x1 + x2 + x3 + x4 + x5"
#> 
#> Slot "outcome_formula_rct_trt":
#> [1] "y1 ~ x1 + x2 + x3 + x4 + x5" "y2 ~ x1 + x2 + x3 + x4 + x5"
#> [3] "y3 ~ x1 + x2 + x3 + x4 + x5" "y4 ~ x1 + x2 + x3 + x4 + x5"
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
#> [1] "DID-EC-OR"
#> 
```
