# Set up an open-label extension (OLE) analysis

Bundles data, column mappings, crossover time, and a method object into
an analysis object ready to be passed to
[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md).

## Usage

``` r
setup_analysis_OLE(
  data,
  trial_status_col_name,
  treatment_col_name,
  outcome_col_name,
  covariates_col_name,
  method_OLE_obj,
  T_cross,
  alpha = 0.05
)
```

## Arguments

- data:

  A data frame containing all subject-level data.

- trial_status_col_name:

  Name of the trial status column.

- treatment_col_name:

  Name of the treatment column.

- outcome_col_name:

  Character vector of outcome column names covering both
  placebo-controlled and OLE periods.

- covariates_col_name:

  Character vector of covariate column names.

- method_OLE_obj:

  A method object created by
  [`did_ec_ipw`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md),
  [`did_ec_aipw`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md),
  [`did_ec_or`](https://genentech.github.io/rdborrow/reference/did_ec_or.md),
  or [`scm`](https://genentech.github.io/rdborrow/reference/scm.md).

- T_cross:

  Integer crossover time point (column index boundary). The first
  `T_cross` outcome columns are from the placebo-controlled phase and
  are used as negative controls for bias correction. The remaining
  `length(outcome_col_name) - T_cross` columns are from the open-label
  extension phase and are used to estimate the treatment effect. Must be
  a positive integer strictly less than `length(outcome_col_name)`.

- alpha:

  Significance level (default 0.05).

## Value

An object of class `analysis_OLE_obj`, to be passed to
[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md).

## Details

Available OLE methods:

- [`did_ec_ipw`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md):

  Difference-in-differences with IPW.

- [`did_ec_aipw`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md):

  DID with augmented IPW.

- [`did_ec_or`](https://genentech.github.io/rdborrow/reference/did_ec_or.md):

  DID with outcome regression.

- [`scm`](https://genentech.github.io/rdborrow/reference/scm.md):

  Synthetic control method.

## See also

[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md),
[`setup_analysis_primary`](https://genentech.github.io/rdborrow/reference/setup_analysis_primary.md)

## Examples

``` r
method <- did_ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
  bootstrap = 50
)
setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_OLE_obj = method,
  T_cross = 2
)
#> <analysis_OLE_obj>
#>   Observations: 300 
#>   Trial status: S 
#>   Treatment: A 
#>   Outcomes: y1, y2, y3, y4 
#>   Covariates: x1, x2, x3, x4, x5 
#>   Method: DID-EC-IPW 
#>   T_cross: 2 
#>   Alpha: 0.05 
```
