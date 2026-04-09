# Construct an analysis_OLE object

Construct an analysis_OLE object

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

  A weighting method object.

- alpha:

  Significance level (default 0.05).

## Value

An analysis object \[\`Analysis\`\]\[Analysis-class\]

## Examples

``` r
if (FALSE) { # \dontrun{
analysis_obj <- setup_analysis(
  trial_status_col_name = S,
  treatment_col_name = A,
  outcome_col_name = Y,
  covariates_col_name = X,
  method = method_obj
)
} # }
```
