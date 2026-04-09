# run analysis

run analysis

## Usage

``` r
run_analysis(analysis_obj, quiet = TRUE)
```

## Arguments

- analysis_obj:

  An analysis object created by `setup_analysis`,
  `setup_analysis_primary`, or `setup_analysis_OLE`.

- quiet:

  Logical. If `TRUE`, suppress printed output.

## Value

a list containing: tau (effect size), sd.tau (standard deviation), wt
(weight)

## Examples

``` r
if (FALSE) { # \dontrun{
run_analysis(analysis_obj, Bootstrap = FALSE)
} # }
```
