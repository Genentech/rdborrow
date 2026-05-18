# Set up a primary analysis with external control borrowing

Bundles data, column mappings, and a method object into an analysis
object ready to be passed to
[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md).

## Usage

``` r
setup_analysis_primary(
  data,
  trial_status_col_name,
  treatment_col_name,
  outcome_col_name,
  covariates_col_name,
  method_weighting_obj,
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

  Character vector of outcome column names.

- covariates_col_name:

  Character vector of covariate column names.

- method_weighting_obj:

  A method object created by
  [`ec_ipw`](https://genentech.github.io/rdborrow/reference/ec_ipw.md)
  or
  [`ec_aipw`](https://genentech.github.io/rdborrow/reference/ec_aipw.md).

- alpha:

  Significance level (default 0.05).

## Value

An object of class `analysis_primary_obj`, to be passed to
[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md).

## Details

Available primary methods:

- [`ec_ipw`](https://genentech.github.io/rdborrow/reference/ec_ipw.md):

  Inverse probability weighting.

- [`ec_aipw`](https://genentech.github.io/rdborrow/reference/ec_aipw.md):

  Augmented inverse probability weighting (doubly robust).

## See also

[`run_analysis`](https://genentech.github.io/rdborrow/reference/run_analysis.md),
[`setup_analysis_OLE`](https://genentech.github.io/rdborrow/reference/setup_analysis_OLE.md)

## Examples

``` r
method <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)
```
