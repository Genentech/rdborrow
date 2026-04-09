# Difference in difference + AIPW + external control borrowing

Difference in difference + AIPW + external control borrowing

## Usage

``` r
DID_EC_AIPW(
  data,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  T_cross,
  model_form_piS = "",
  model_form_piA = "",
  model_form_mu0_ext = "",
  Bootstrap = FALSE,
  R = 500,
  bootstrap_CI_type = "bca",
  alpha = 0.05,
  quiet = TRUE
)
```

## Arguments

- data:

  data.frame. The input data containing the outcome, trial status,
  treatment, and covariates.

- outcome_col_name:

  character. The column name for the outcome variable in the data.

- trial_status_col_name:

  character. The column name for the trial status variable in the data
  (indicating RCT vs external control).

- treatment_col_name:

  character. The column name for the treatment variable in the data.

- covariates_col_name:

  character vector. The column names for the covariates in the data.

- T_cross:

  numeric. The time point that separates the placebo-control period and
  the follow-up period.

- model_form_piS:

  character. The model formula for the selection model (S).

- model_form_piA:

  character. The model formula for the treatment model (A).

- model_form_mu0_ext:

  character. The model formula for the outcome model in the external
  data (mu0_ext).

- Bootstrap:

  logical. Whether to use bootstrap for inference.

- R:

  numeric. The number of bootstrap replications.

- bootstrap_CI_type:

  character. The type of bootstrap confidence interval to compute (e.g.,
  "bca", "norm", "perc", "basic", "stud").

- alpha:

  numeric. The significance level for confidence intervals.

- quiet:

  Logical. If `TRUE`, suppress printed output.

## Value

tau and standard deviation
