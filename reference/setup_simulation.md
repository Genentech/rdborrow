# Construct an simulation object

Construct an simulation object

## Usage

``` r
setup_simulation(
  trial_status_col_name,
  treatment_col_name,
  outcome_col_name,
  covariates_col_name,
  method_obj_list,
  method_description,
  alpha = 0.05
)
```

## Arguments

- trial_status_col_name:

  Name of the trial status column.

- treatment_col_name:

  Name of the treatment column.

- outcome_col_name:

  Character vector of outcome column names.

- covariates_col_name:

  Character vector of covariate column names.

- method_obj_list:

  List of method objects to evaluate.

- method_description:

  Character vector of method labels.

- alpha:

  Significance level.

## Value

An simulation object

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
