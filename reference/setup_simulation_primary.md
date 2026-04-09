# Construct a simulation object for primary analysis

Construct a simulation object for primary analysis

## Usage

``` r
setup_simulation_primary(
  data_matrix_list_null,
  trial_status_col_name,
  treatment_col_name,
  outcome_col_name,
  covariates_col_name,
  method_obj_list,
  true_effect,
  method_description,
  data_matrix_list_alt = list(),
  alt_effect = numeric(0),
  alpha = 0.05
)
```

## Arguments

- data_matrix_list_null:

  List of data frames simulated under the null.

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

- true_effect:

  Numeric vector of true treatment effects.

- method_description:

  Character vector of method labels.

- data_matrix_list_alt:

  List of data frames simulated under the alternative.

- alt_effect:

  Numeric vector of alternative treatment effects.

- alpha:

  Significance level.

## Value

return a simulation object for primary analysis

## Examples

``` r
if (FALSE) { # \dontrun{
simulation_primary_obj <- setup_simulation_primary(
  data_matrix_list_null = data_matrix_list_null, # two scenarios
  data_matrix_list_alt = data_matrix_list_alt,
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  outcome_col_name = outcome_col_name,
  covariates_col_name = covariates_col_name,
  method_obj_list = method_obj_list,
  true_effect = true_effect,
  alt_effect = alt_effect,
  alpha = alpha,
  method_description = c(
    "IPW, optimal weight",
    "AIPW, optimal weight",
    "IPW, zero weight",
    "AIPW, zero weight"
  )
)
} # }
```
