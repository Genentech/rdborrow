# Implement the Synthetic Control Method

SCM() is the main function that calculates the estimated ATE by SC
method and Bootstrap CI. It calls subject_SC() and lambdacv().

## Usage

``` r
SCM(
  data,
  outcome_col_name,
  trial_status_col_name,
  treatment_col_name,
  covariates_col_name,
  T_cross,
  Bootstrap = TRUE,
  R = 100,
  bootstrap_CI_type = "bca",
  alpha = 0.05,
  lambda.min = 0,
  lambda.max = 0.1,
  nlambda = 2,
  parallel = "no",
  ncpus = 1,
  quiet = TRUE
)
```

## Arguments

- data:

  A data frame containing all subject-level data.

- outcome_col_name:

  Character vector of outcome column names.

- trial_status_col_name:

  Name of the trial status column.

- treatment_col_name:

  Name of the treatment column.

- covariates_col_name:

  Character vector of covariate column names.

- T_cross:

  Integer crossover time point.

- Bootstrap:

  Logical. Whether to use bootstrap inference.

- R:

  Number of bootstrap replicates.

- bootstrap_CI_type:

  Type of bootstrap CI (e.g. `"bca"`, `"perc"`).

- alpha:

  Significance level.

- lambda.min:

  Numeric. Minimum penalty parameter.

- lambda.max:

  Numeric. Maximum penalty parameter.

- nlambda:

  Integer. Number of lambda values for cross-validation.

- parallel:

  Character. Parallelization type for `boot`.

- ncpus:

  Integer. Number of CPUs for parallel bootstrap.

- quiet:

  Logical. If `TRUE`, suppress printed output.

## Value

A list contains: estimated ATE, SE, weight used, SE by Bootstrap and a
95 Bootstrap=TRUE)
