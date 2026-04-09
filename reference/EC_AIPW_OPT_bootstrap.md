# Using AIPW with external borrowing

Using AIPW with external borrowing

## Usage

``` r
EC_AIPW_OPT_bootstrap(
  data,
  indices,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  model_form_piS = "",
  model_form_mu0_ext = "",
  optimal_weight_flag = FALSE,
  wt = 0
)
```

## Arguments

- data:

  A data frame containing all subject-level data.

- indices:

  Bootstrap sample indices.

- outcome_col_name:

  Character vector of outcome column names.

- trial_status_col_name:

  Name of the trial status column.

- treatment_col_name:

  Name of the treatment column.

- covariates_col_name:

  Character vector of covariate column names.

- model_form_piS:

  Formula string for the trial participation model.

- model_form_mu0_ext:

  Formula string(s) for the external control outcome model.

- optimal_weight_flag:

  Logical. Whether to use the optimal borrowing weight.

- wt:

  Numeric fixed borrowing weight.

## Value

a list containing: tau (effect size), sd.tau (standard deviation), wt
(weight)

## Examples

``` r
if (FALSE) { # \dontrun{
res <- EC_AIPW_OPT(
  data = data,
  outcome_col_name = outcome_col_name,
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  covariates_col_name = covariates_col_name,
  model_form_piS = model_form_piS,
  model_form_mu0 = model_form_mu0,
  wt = wt,
  optimal_weight_flag = optimal_weight_flag,
  Bootstrap
)
} # }
```
