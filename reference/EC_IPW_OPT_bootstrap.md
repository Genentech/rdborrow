# Using IPW with external borrowing

Using IPW with external borrowing

## Usage

``` r
EC_IPW_OPT_bootstrap(
  data,
  indices,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  model_form_piS = "",
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
EC_IPW_OPT(
  outcome = outcome,
  trial_status = trial_status,
  treatment = treatment,
  covariates = covariates,
  model_form_piS = model_form_piS,
  wt = wt,
  optimal_weight_flag = optimal_weight_flag,
  Bootstrap
)
} # }
```
