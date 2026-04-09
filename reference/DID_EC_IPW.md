# Difference in difference + IPW + external control borrowing

Difference in difference + IPW + external control borrowing

## Usage

``` r
DID_EC_IPW(
  data,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  T_cross,
  model_form_piS = "",
  model_form_piA = "",
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

- T_cross:

  Integer crossover time point.

- model_form_piS:

  Formula string for the trial participation model.

- model_form_piA:

  Formula string for the treatment assignment model.

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

tau and standard deviation
