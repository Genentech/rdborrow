# Bootstrap statistic for DID + IPW

Bootstrap statistic for DID + IPW

## Usage

``` r
DID_EC_IPW_bootstrap(
  data,
  indices,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  T_cross,
  model_form_piS = "",
  model_form_piA = ""
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

## Value

Named numeric vector of treatment effect estimates.
