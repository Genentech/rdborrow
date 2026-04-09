# simulate X by discretizing a multivariate normal distribution pkg: futile.logger, mvtnorm

simulate X by discretizing a multivariate normal distribution pkg:
futile.logger, mvtnorm

## Usage

``` r
simulate_X_dct_mvnorm(
  n,
  p,
  mu = rep(0, p),
  sig = diag(p),
  cat_cols = c(),
  cat_prob = list()
)
```

## Arguments

- n:

  total number of units simulated

- p:

  dimension of the parameters

- mu:

  mean for mvnorm

- sig:

  cov of mvnorm

- cat_cols:

  columns with categorical variables

- cat_prob:

  list

## Value

a list contains simulated data and true ATE

## Examples

``` r
if (FALSE) { # \dontrun{
simulate_X_dct_mvnorm(
  20, 3,
  mu = rep(0, 3), sig = diag(3),
  cat_cols = c(1),
  cat_prob = list(c(0.3, 0.7))
)
simulate_X_dct_mvnorm(
  20, 3,
  mu = rep(0, 3), sig = diag(3),
  cat_cols = c(1, 3),
  cat_prob = list(c(0.2, 0.6, 0.2), c(0.3, 0.7))
)
} # }
```
