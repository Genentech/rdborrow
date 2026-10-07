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

  The true treatment effect at the final visit, a single number.
  \[run_simulation()\] evaluates estimates at the final visit only.

- method_description:

  Character vector of method labels, one per method in
  \`method_obj_list\`.

- data_matrix_list_alt:

  List of data frames simulated under the alternative.

- alt_effect:

  Numeric vector of alternative treatment effects.

- alpha:

  Significance level, more than 0 and less than 1.

## Value

An object of class \`simulation_primary_obj\`.

## Examples

``` r
setup_simulation_primary(
  data_matrix_list_null = list(SyntheticData),
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_obj_list = list(
    ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
  ),
  true_effect = 0,
  method_description = "IPW"
)
```
