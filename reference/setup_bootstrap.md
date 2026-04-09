# Construct a bootstrap object

Construct a bootstrap object

## Usage

``` r
setup_bootstrap(replicates = 500, bootstrap_CI_type = "bca")
```

## Arguments

- replicates:

  Number of bootstrap replicates.

- bootstrap_CI_type:

  Type of bootstrap CI (e.g. `"bca"`, `"perc"`).

## Value

An bootstrap object

## Examples

``` r
if (FALSE) { # \dontrun{
analysis_obj <- setup_analysis(
  trial_status_col_name = S,
  treatment_col_name = A,
  outcome_col_name = Y,
  covariates_col_name = X,
  method = method_obj
)
} # }
```
