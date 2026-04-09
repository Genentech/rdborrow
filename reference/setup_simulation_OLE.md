# Construct a simulation object for OLE analysis

Construct a simulation object for OLE analysis

## Usage

``` r
setup_simulation_OLE(
  data_matrix_list,
  trial_status_col_name,
  treatment_col_name,
  outcome_col_name,
  covariates_col_name,
  method_obj_list,
  T_cross,
  true_effect,
  method_description,
  alpha = 0.05
)
```

## Arguments

- data_matrix_list:

  List of simulated data frames.

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

- T_cross:

  Integer crossover time point.

- true_effect:

  Numeric vector of true treatment effects.

- method_description:

  Character vector of method labels.

- alpha:

  Significance level.

## Value

a simulation object for OLE phase

## Examples

``` r
if (FALSE) { # \dontrun{
simulation_OLE_obj <- setup_simulation_OLE(
  data_matrix_list = data_matrix_list, # two scenarios
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  outcome_col_name = outcome_col_name,
  covariates_col_name = covariates_col_name,
  method_obj_list = method_obj_list,
  true_effect = true_effect_long,
  T_cross = 2,
  alpha = alpha,
  method_description = c(
    "IPW, DID",
    "AIPW, DID",
    "OR, DID"
  )
)
} # }
```
