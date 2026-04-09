# Simulate trials

Simulate trials

## Usage

``` r
simulate_trial(
  X_int,
  X_ext,
  num_treated,
  OLE_flag,
  T_cross,
  outcome_model_specs
)
```

## Arguments

- X_int:

  Data frame of internal (RCT) covariates.

- X_ext:

  Data frame of external control covariates.

- num_treated:

  Number of treated subjects.

- OLE_flag:

  Logical. Whether this is an OLE simulation.

- T_cross:

  Integer crossover time point.

- outcome_model_specs:

  List of outcome model specifications.

## Value

a data frame for the simulated data

## Examples

``` r
if (FALSE) { # \dontrun{
Data <- simulate_trial(X_int,
  X_ext,
  num_treated = 150,
  OLE_flag = TRUE,
  T_cross = 2,
  outcome_model_specs
)
} # }
```
