# Bootstrap class

Bootstrap class

## Slots

- `replicates`:

  Number of bootstrap replicates.

- `bootstrap_CI_type`:

  Type of bootstrap confidence interval.

## Examples

``` r
if (FALSE) { # \dontrun{
bootstrap_obj <- setup_bootstrap(
  replicates = 2e3,
  bootstrap_CI_type = "perc"
)

method_weighting_obj <- setup_method_weighting(
  method_name = "AIPW",
  optimal_weight_flag = TRUE,
  wt = 0,
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_mu0_ext = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status = "S",
  treatment = "A",
  outcome = c("y1", "y2"),
  covariates = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)

res <- run_analysis(analysis_primary_obj)
} # }
```
