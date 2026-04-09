# setup_simulation_report

setup_simulation_report

## Usage

``` r
setup_simulation_report(
  method_description,
  bias,
  variance,
  mse,
  coverage,
  type_I_error = numeric(0),
  power = numeric(0)
)
```

## Arguments

- method_description:

  Character vector of method labels.

- bias:

  Numeric vector of bias estimates.

- variance:

  Numeric vector of variance estimates.

- mse:

  Numeric vector of MSE estimates.

- coverage:

  Numeric vector of coverage probabilities.

- type_I_error:

  Numeric vector of type I error rates.

- power:

  Numeric vector of power estimates.

## Value

A `simulation_report_obj`.
