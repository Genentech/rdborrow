# Difference in difference + outcome regression + external control borrowing

Difference in difference + outcome regression + external control
borrowing

## Usage

``` r
DID_EC_OR_bootstrap(
  data = data,
  indices = indices,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  T_cross,
  model_form_mu0_ext = "",
  model_form_mu0_rct = "",
  model_form_mu1_rct = ""
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

- T_cross:

  Integer crossover time point.

- model_form_mu0_ext:

  Formula string(s) for the external control outcome model.

- model_form_mu0_rct:

  Formula string(s) for the RCT control outcome model.

- model_form_mu1_rct:

  Formula string(s) for the RCT treatment outcome model.

## Value

tau and standard deviation

## Examples

``` r
if (FALSE) { # \dontrun{
model_form_mu <- c(
  "y1 ~ x1 + x2",
  "y2 ~ x1 + x2",
  "y3 ~ x1 + x2",
  "y4 ~ x1 + x2"
)
res1 <- DID_EC_OR(
  outcome = Y, trial_status = S, treatment = A, covariates = X,
  long_term_marker = c(F, T, T, T),
  model_form_mu0_ext = model_form_mu,
  model_form_mu0_rct = model_form_mu,
  model_form_mu1_rct = model_form_mu
)
} # }
```
