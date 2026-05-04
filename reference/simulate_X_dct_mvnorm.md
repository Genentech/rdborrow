# Simulate covariates by discretizing a multivariate normal

Draws from a multivariate normal distribution and optionally discretizes
selected columns into categorical variables based on specified
probability cutpoints.

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

  Positive integer. Number of units to simulate.

- p:

  Positive integer. Number of covariates.

- mu:

  Numeric vector of length \`p\`. Mean of the multivariate normal.
  Defaults to a zero vector.

- sig:

  Numeric matrix of dimension \`p x p\`. Covariance matrix. Defaults to
  the identity matrix.

- cat_cols:

  Integer vector. Column indices to discretize into categorical
  variables. Each index must be between 1 and \`p\`.

- cat_prob:

  List of numeric vectors, one per element of \`cat_cols\`. Each vector
  gives the category probabilities (must sum to 1). The number of
  categories equals the length of the vector, and the resulting values
  are 0-indexed (0, 1, ..., K-1).

## Value

A data frame with \`n\` rows and \`p\` columns named \`x1\`, ...,
\`xp\`.

## Examples

``` r
simulate_X_dct_mvnorm(
  20, 3,
  mu = rep(0, 3), sig = diag(3),
  cat_cols = c(1),
  cat_prob = list(c(0.3, 0.7))
)
#>    x1            x2         x3
#> 1   0  3.4805397484 -0.6174220
#> 2   1  0.5925402530 -0.9003468
#> 3   1  1.0851326027 -1.7066874
#> 4   0 -1.4194533339  0.6459709
#> 5   1  1.1898281468 -0.1398591
#> 6   1  0.0575844052 -0.5872461
#> 7   1  0.7638003907 -0.6780967
#> 8   1  0.0419394664  0.9793096
#> 9   1  1.3811671565  0.1771869
#> 10  0 -0.0064125536 -1.0309176
#> 11  0  1.2300053344 -2.1252639
#> 12  1  1.0114553407  1.3671746
#> 13  1 -0.1225158540 -0.7994091
#> 14  1  0.1094528569  0.2309266
#> 15  0  0.6205258113 -0.6423485
#> 16  1  0.2458842772 -0.8478937
#> 17  1  0.8831759490  0.5863187
#> 18  1  1.2201357048  2.3258880
#> 19  0  0.0002714681  1.1425116
#> 20  1 -0.2083145925  0.7499227
simulate_X_dct_mvnorm(
  20, 3,
  mu = rep(0, 3), sig = diag(3),
  cat_cols = c(1, 3),
  cat_prob = list(c(0.2, 0.6, 0.2), c(0.3, 0.7))
)
#>    x1            x2 x3
#> 1   1  0.0990212037  1
#> 2   1 -1.0649372190  1
#> 3   1  1.2002630345  1
#> 4   1  0.5029684073  1
#> 5   1 -0.1559494684  1
#> 6   0 -0.2903433729  1
#> 7   1  0.0118239369  1
#> 8   1 -0.8981034882  1
#> 9   2 -1.1051534547  1
#> 10  0  0.7394716153  1
#> 11  0 -2.0112246984  1
#> 12  0 -1.1097503996  1
#> 13  0  0.9307754912  1
#> 14  2  0.4620031264  0
#> 15  2  0.4572947704  0
#> 16  2 -0.3381593680  1
#> 17  1  0.3550907169  0
#> 18  2 -0.0004656092  1
#> 19  1 -0.8612007223  1
#> 20  1 -2.0286071844  1
```
