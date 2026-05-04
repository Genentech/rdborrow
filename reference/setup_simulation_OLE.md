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

  Numeric crossover time point.

- true_effect:

  Numeric vector of true treatment effects.

- method_description:

  Character vector of method labels, one per method in
  \`method_obj_list\`.

- alpha:

  Significance level.

## Value

An object of class \`simulation_OLE_obj\`.

## Examples

``` r
if (FALSE) { # \dontrun{
setup_simulation_OLE(
  data_matrix_list = data_matrix_list,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_obj_list = list(setup_method(method_name = "AIPW")),
  T_cross = 2,
  true_effect = c(0, 0),
  method_description = "AIPW"
)
} # }
```
