# Simulate trial status indicator

Simulate trial status indicator

## Usage

``` r
simulate_trial_status(X, model_specs)
```

## Arguments

- X:

  Data frame of covariates.

- model_specs:

  List with `family` and `coef` for the participation model.

## Value

a data frame containing the trial status vector

## Examples

``` r
if (FALSE) { # \dontrun{
S <- simulate_trial_status(X, model_specs = list(
  family = "binomial",
  coef = c(1, 2, 3)
))
} # }
```
