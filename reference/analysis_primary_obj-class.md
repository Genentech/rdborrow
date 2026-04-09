# Analysis class

Analysis class

## Slots

- `method_obj`:

## Examples

``` r
if (FALSE) { # \dontrun{
method_weighting_obj <- setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = FALSE,
  wt = 0,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)
} # }
```
