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
X_int <- data.frame(x1 = rnorm(20), x2 = rnorm(20))
X_ext <- data.frame(x1 = rnorm(30), x2 = rnorm(30))
specs <- list(
  list(
    effect = 1.5,
    model_form_x = c("1" = 2.0, "x1" = 0.5, "x2" = -0.3),
    noise_mean = 0, noise_sd = 1
  ),
  list(
    effect = 0,
    model_form_x = c("1" = 1.0, "x1" = 0.2, "x2" = 0.1),
    noise_mean = 0, noise_sd = 1
  )
)
Data <- simulate_trial(X_int,
  X_ext,
  num_treated = 10,
  OLE_flag = FALSE,
  T_cross = 2,
  outcome_model_specs = specs
)
```
