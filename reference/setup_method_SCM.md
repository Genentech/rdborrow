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

  numeric. The minimum value of the regularization parameter lambda for
  SCM.

- lambda.max:

  numeric. The maximum value of the regularization parameter lambda for
  SCM.

- nlambda:

  numeric. The number of lambda values to consider for SCM.

- parallel:

  character. The type of parallelization to use for SCM (e.g., "no",
  "multicore", "snow").

- ncpus:

  numeric. The number of CPU cores to use for parallelization in SCM.

## Value

An object of class \`method_SCM_obj\`.
