# SCM method constructor

Creates a method object for synthetic control estimation with external
control borrowing for the open-label extension phase (Zhou et al.,
2024). Constructs a weighted combination of external controls matching
each RCT control subject on covariates and pre-crossover outcomes. The
penalty is chosen by leave-one-out cross-validation over the external
controls, so the data needs at least 2 external controls. The covariates
must be numeric or logical; code a factor as 0/1 indicators first.

## Usage

``` r
scm(
  lambda_min = 0,
  lambda_max = 0.1,
  nlambda = 2L,
  parallel = "no",
  ncpus = 1L,
  bootstrap = 200L,
  bootstrap_ci_type = NULL
)
```

## Arguments

- lambda_min:

  Minimum penalty parameter for LOOCV. A finite number of at least 0.

- lambda_max:

  Maximum penalty parameter for LOOCV. A finite number of at least
  `lambda_min`.

- nlambda:

  Number of lambda values to evaluate in LOOCV, evenly spaced from
  `lambda_min` to `lambda_max`. With `nlambda = 1`, `lambda_max` must
  equal `lambda_min`.

- parallel:

  Parallelization type for bootstrap (`"no"`, `"multicore"`, or
  `"snow"`).

- ncpus:

  Number of CPUs for parallel bootstrap.

- bootstrap:

  Number of bootstrap replicates (at least 2). Defaults to 200.

- bootstrap_ci_type:

  Bootstrap CI type. Defaults to `"perc"`.

## Value

An S4 object of class `scm_method`.

## Details

The analysis result from
[`run_analysis()`](https://genentech.github.io/rdborrow/reference/run_analysis.md)
has an attribute `"lambda"`, the penalty that cross-validation selected:
`attr(result, "lambda")`.

## References

Zhou et al. (2024). Estimating treatment effect in randomized trial
after control to treatment crossover using external controls. *Journal
of Biopharmaceutical Statistics*.
[doi:10.1080/10543406.2024.2330209](https://doi.org/10.1080/10543406.2024.2330209)

## Examples

``` r
scm(lambda_min = 0, lambda_max = 0.001, nlambda = 2, bootstrap = 50)
#> An object of class "scm_method"
#> Slot "lambda_min":
#> [1] 0
#> 
#> Slot "lambda_max":
#> [1] 0.001
#> 
#> Slot "nlambda":
#> [1] 2
#> 
#> Slot "parallel":
#> [1] "no"
#> 
#> Slot "ncpus":
#> [1] 1
#> 
#> Slot "method_name":
#> [1] "SCM"
#> 
#> Slot "bootstrap":
#> [1] 50
#> 
#> Slot "bootstrap_ci_type":
#> [1] "perc"
#> 
```
