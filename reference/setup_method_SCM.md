# Construct a method_SCM object

Construct a method_SCM object

## Usage

``` r
setup_method_SCM(
  method_name = "SCM",
  bootstrap_flag = FALSE,
  bootstrap_obj = .bootstrap_obj(),
  lambda.min,
  lambda.max,
  nlambda = 10,
  parallel = "no",
  ncpus = 1
)
```

## Arguments

- method_name:

  character. Name of the method.

- bootstrap_flag:

  logical. Whether to use bootstrap for inference.

- bootstrap_obj:

  bootstrap_obj. An object of class \`bootstrap_obj\` containing
  bootstrap settings.

- lambda.min:

  numeric. Minimum value of the regularization parameter.

- lambda.max:

  numeric. Maximum value of the regularization parameter.

- nlambda:

  numeric. Number of lambda values for cross-validation.

- parallel:

  character. Parallelization type (\`"no"\`, \`"multicore"\`, or
  \`"snow"\`).

- ncpus:

  numeric. Number of CPU cores to use for parallelization.

## Value

An object of class \`method_SCM_obj\`.

## Examples

``` r
setup_method_SCM(
  lambda.min = 0,
  lambda.max = 1e-3
)
```
