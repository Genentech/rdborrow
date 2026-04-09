# method class

method class

## Slots

- `parallel`:

  Parallelization type for boot.

- `ncpus`:

  Number of CPUs for parallel bootstrap.

- `lambda.min`:

  Minimum penalty parameter.

- `lambda.max`:

  Maximum penalty parameter.

- `nlambda`:

  Number of lambda values for cross-validation.

## Examples

``` r
if (FALSE) { # \dontrun{
method_SCM_obj <- setup_method_SCM(
  method_name = "SCM",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  lambda.min = 0,
  lambda.max = 1e-3,
  nlambda = 10,
  parallel = "multicore",
  ncpus = 4
)
} # }
```
