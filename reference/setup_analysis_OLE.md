# Construct an analysis_OLE object

Construct an analysis_OLE object

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

  Character vector of outcome column names.

- covariates_col_name:

  Character vector of covariate column names.

- method_OLE_obj:

  A method object of class \`method_OLE_obj\` for OLE analysis.

- T_cross:

  Numeric crossover time point.

- alpha:

  Significance level (default 0.05).

## Value

An object of class \`analysis_OLE_obj\`.

## Examples

``` r
setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_OLE_obj = setup_method_DID(method_name = "IPW"),
  T_cross = 2
)
#> Warning: 'setup_method_DID' is being deprecated. Use did_ec_ipw() for DID with inverse probability weighting, did_ec_aipw() for DID with augmented IPW, or did_ec_or() for DID with outcome regression.
#> <analysis_OLE_obj>
#>   Observations: 300 
#>   Trial status: S 
#>   Treatment: A 
#>   Outcomes: y1, y2, y3, y4 
#>   Covariates: x1, x2, x3, x4, x5 
#>   Method: IPW 
#>   T_cross: 2 
#>   Alpha: 0.05 
```
