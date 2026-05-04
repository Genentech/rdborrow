# Construct an analysis_primary object

Construct an analysis_primary object

## Usage

``` r
setup_analysis_primary(
  data,
  trial_status_col_name,
  treatment_col_name,
  outcome_col_name,
  covariates_col_name,
  method_weighting_obj,
  alpha = 0.05
)
```

## Arguments

- data:

  A data frame containing all subject-level data.

- trial_status_col_name:

  Name of the trial status column.

- treatment_col_name:

  Name of the treatment column.

- outcome_col_name:

  Character vector of outcome column names.

- covariates_col_name:

  Character vector of covariate column names.

- method_weighting_obj:

  A weighting method object of class \`method_primary_obj\`.

- alpha:

  Significance level (default 0.05).

## Value

An object of class \`analysis_primary_obj\`.

## Examples

``` r
setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = setup_method_weighting(method_name = "IPW")
)
```
