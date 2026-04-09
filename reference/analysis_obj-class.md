# Analysis class

Analysis class

## Slots

- `method_obj`:

  Method.

- `data`:

  Data frame of subject-level data.

- `covariates_col_name`:

  Character vector of covariate column names.

- `outcome_col_name`:

  Character vector of outcome column names.

- `treatment_col_name`:

  Name of the treatment column.

- `trial_status_col_name`:

  Name of the trial status column.

- `alpha`:

  Significance level.

## Examples

``` r
if (FALSE) { # \dontrun{
method_weighting_obj <- setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = FALSE,
  wt = 0,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
)


analysis_obj <- setup_analysis(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_obj = method_weighting_obj
)
} # }
```
