# Simulate outcome from given effect additive models

Simulate outcome from given effect additive models

## Usage

``` r
simulate_outcome_from_model(X, A, outcome_model_specs, OLE_flag, T_cross)
```

## Arguments

- X:

  Data frame of covariates.

- A:

  Data frame of treatment indicators.

- outcome_model_specs:

  List of outcome model specifications.

- OLE_flag:

  Logical. Whether this is an OLE simulation.

- T_cross:

  Integer crossover time point.

## Value

a data frame containing simulated outcome

## Examples

``` r
if (FALSE) { # \dontrun{
model_form1 <- "y1 = A*3 + x1*1 + x2*1 + rnorm(n, mean = 0, sd=0.5)"
model_form2 <- "y2 = A*0 + x1*1 + x2*(-1) + rnorm(n, mean = 0, sd=0.5)"
Y <- simulate_outcome_from_model(
  T_follow = 2, X = X, A = A,
  outcome_model_specs = list(
    list(
      model_form = model_form1
    ),
    list(
      model_form = model_form2
    )
  )
)
Y
} # }
```
