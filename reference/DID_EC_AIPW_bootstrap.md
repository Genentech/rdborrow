# Difference in difference + AIPW + external control borrowing

Difference in difference + AIPW + external control borrowing

## Usage

``` r
DID_EC_AIPW_bootstrap(
  data,
  indices,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  T_cross,
  model_form_piS = "",
  model_form_piA = "",
  model_form_mu0_ext = ""
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

- model_form_piS:

  Formula string for the trial participation model.

- model_form_piA:

  Formula string for the treatment assignment model.

- model_form_mu0_ext:

  Formula string(s) for the external control outcome model.

## Value

tau and standard deviation

## Examples

``` r
if (FALSE) { # \dontrun{
DID_EC_AIPW_bootstrap(
  data = my_data,
  indices = seq_len(nrow(my_data)),
  outcome_col_name = c("y1", "y2"),
  trial_status_col_name = "S",
  treatment_col_name = "A",
  covariates_col_name = c("x1", "x2"),
  T_cross = 1
)
} # }
```
