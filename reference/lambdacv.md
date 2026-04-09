# Find the optimal lambda via LOOCV

Find the optimal lambda via LOOCV

## Usage

``` r
lambdacv(
  ec,
  long_term_col_name,
  lambda.min = 0,
  lambda.max = 0.1,
  nlambda = 10,
  pb = NULL
)
```

## Arguments

- ec:

  Matrix of external control data (attributes by columns).

- long_term_col_name:

  Character vector of long-term outcome column names.

- lambda.min:

  Numeric. Minimum penalty parameter.

- lambda.max:

  Numeric. Maximum penalty parameter.

- nlambda:

  Integer. Number of lambda values to evaluate.

- pb:

  A progress bar object or `NULL`.
