# Evaluate operating characteristics via Monte Carlo simulation

Runs repeated simulations under user-specified data-generating scenarios
to estimate power, type I error rate, bias, and coverage for one or more
borrowing methods.

## Usage

``` r
run_simulation(simulation_obj, quiet = TRUE)
```

## Arguments

- simulation_obj:

  A simulation object created by
  [`setup_simulation_primary`](https://genentech.github.io/rdborrow/reference/setup_simulation_primary.md)
  or
  [`setup_simulation_OLE`](https://genentech.github.io/rdborrow/reference/setup_simulation_OLE.md).

- quiet:

  Logical. If `TRUE`, suppress iteration output.

## Value

A simulation report object containing estimated power, type I error
rate, and related operating characteristics for each method.

## Details

Six borrowing methods are available:

- [`ec_ipw`](https://genentech.github.io/rdborrow/reference/ec_ipw.md):

  Inverse probability weighting (primary analysis).

- [`ec_aipw`](https://genentech.github.io/rdborrow/reference/ec_aipw.md):

  Augmented inverse probability weighting (primary analysis).

- [`did_ec_ipw`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md):

  Difference-in-differences with IPW (open-label extension).

- [`did_ec_aipw`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md):

  Difference-in-differences with AIPW (open-label extension).

- [`did_ec_or`](https://genentech.github.io/rdborrow/reference/did_ec_or.md):

  Difference-in-differences with outcome regression (open-label
  extension).

- [`scm`](https://genentech.github.io/rdborrow/reference/scm.md):

  Synthetic control method (open-label extension).

## See also

[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md)
for analyzing a single dataset.

## Examples

``` r
method <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
sim <- setup_simulation_primary(
  data_matrix_list_null = list(SyntheticData, SyntheticData),
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_obj_list = list(method),
  true_effect = c(0, 0),
  method_description = "IPW"
)
run_simulation(sim)
```
