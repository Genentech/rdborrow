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
setup_simulation_OLE(
  data_matrix_list = list(SyntheticData),
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_obj_list = list(setup_method_DID(
    method_name = "IPW",
    bootstrap_flag = TRUE,
    bootstrap_obj = setup_bootstrap(),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5"
  )),
  T_cross = 2,
  true_effect = c(0, 0),
  method_description = "IPW, DID"
)
#> Warning: 'setup_method_DID' is being deprecated. Use did_ec_ipw() for DID with inverse probability weighting, did_ec_aipw() for DID with augmented IPW, or did_ec_or() for DID with outcome regression.
```
