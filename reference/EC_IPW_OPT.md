# Using IPW with external borrowing

Using IPW with external borrowing

## Usage

``` r
EC_IPW_OPT(
  data,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  model_form_piS = "",
  optimal_weight_flag = FALSE,
  wt = 0,
  Bootstrap = FALSE,
  R = 500,
  bootstrap_CI_type = "bca",
  alpha = 0.05,
  quiet = TRUE
)
```

## Arguments

- data:

  A data frame containing all subject-level data.

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

- Bootstrap:

  Logical. Whether to use bootstrap inference.

- R:

  Number of bootstrap replicates.

- bootstrap_CI_type:

  Type of bootstrap CI (e.g. `"bca"`, `"perc"`).

- alpha:

  Significance level.

- quiet:

  Logical. If `TRUE`, suppress printed output.

## Value

a list containing: tau (effect size), sd.tau (standard deviation), wt
(weight)

## Examples

``` r
if (FALSE) { # \dontrun{
EC_IPW_OPT(
  data = data,
  outcome_col_name = outcome_col_name,
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  covariates_col_name = covariates_col_name,
  model_form_piS = model_form_piS,
  wt = wt,
  optimal_weight_flag = optimal_weight_flag,
  Bootstrap, R, bootstrap_CI_type
)
} # }
```
