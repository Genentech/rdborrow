# Run an analysis with external control borrowing

Estimates treatment effects by combining randomized trial data with
external controls. Choose a method, wrap it in an analysis object, and
pass it here.

## Usage

``` r
run_analysis(analysis_obj, quiet = TRUE)
```

## Arguments

- analysis_obj:

  An analysis object created by
  [`setup_analysis_primary`](https://genentech.github.io/rdborrow/reference/setup_analysis_primary.md)
  or
  [`setup_analysis_OLE`](https://genentech.github.io/rdborrow/reference/setup_analysis_OLE.md).

- quiet:

  Logical. If `TRUE`, suppress printed output.

## Value

For primary methods
([`ec_ipw()`](https://genentech.github.io/rdborrow/reference/ec_ipw.md),
[`ec_aipw()`](https://genentech.github.io/rdborrow/reference/ec_aipw.md)),
a list with:

- `results`:

  A data frame with one row for each outcome, named `tau1`, `tau2`, and
  so on, in the order of `outcome_col_name`. The columns are
  `point_estimates`, `standard_deviation`, and either `lower_CI_normal`
  and `upper_CI_normal` (sandwich variance, when `bootstrap` is `NULL`)
  or `lower_CI_boot` and `upper_CI_boot`. `standard_deviation` is the
  sandwich standard error, or the standard deviation of the bootstrap
  replicates.

- `borrow_weight`:

  The borrowing weight that was used.

For OLE methods
([`did_ec_ipw()`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md),
[`did_ec_aipw()`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md),
[`did_ec_or()`](https://genentech.github.io/rdborrow/reference/did_ec_or.md),
[`scm()`](https://genentech.github.io/rdborrow/reference/scm.md)), a
data frame with one row for each open-label visit and the columns
`point_estimates`, `lower_CI_boot`, and `upper_CI_boot`. The rows are
named `tau<k>` for `k` from `T_cross + 1` to the number of outcomes,
where `k` is the position of the outcome in `outcome_col_name`. List the
outcomes in visit order.

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

[`run_simulation`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
for evaluating operating characteristics via Monte Carlo simulation.

## Examples

``` r
method <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)
run_analysis(analysis)
#> $results
#>      point_estimates standard_deviation lower_CI_normal upper_CI_normal
#> tau1      -0.1971969          0.5134018       -1.203446        0.809052
#> tau2       0.4697209          0.5410007       -0.590621        1.530063
#> 
#> $borrow_weight
#> [1] 0.1475196
#> 
```
