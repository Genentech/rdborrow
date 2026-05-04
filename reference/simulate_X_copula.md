# Simulate covariates using a copula

Couples several marginal distributions using a copula to generate
correlated multivariate covariates.

## Usage

``` r
simulate_X_copula(n, p, cp, margins, paramMargins)
```

## Arguments

- n:

  Positive integer. Number of units to simulate.

- p:

  Positive integer. Number of covariates. Must equal the dimension of
  \`cp\`.

- cp:

  A copula object (from the \`copula\` package).

- margins:

  Character vector of length \`p\`. Names of marginal distributions
  (e.g. \`"norm"\`, \`"binom"\`).

- paramMargins:

  List of length \`p\`. Each element is a named list of parameters for
  the corresponding marginal distribution.

## Value

A data frame with \`n\` rows and \`p\` columns named \`x1\`, ...,
\`xp\`.

## Examples

``` r
normal <- copula::normalCopula(param = c(0.8), dim = 4, dispstr = "ar1")
X <- simulate_X_copula(1000, 4, normal,
  margins = c("norm", "t", "norm", "binom"),
  paramMargins = list(
    list(mean = 2, sd = 3),
    list(df = 2),
    list(mean = 0, sd = 1),
    list(size = 10, prob = 0.5)
  )
)
cor(X, method = "spearman")
#>           x1        x2        x3        x4
#> x1 1.0000000 0.7843630 0.6290593 0.4916759
#> x2 0.7843630 1.0000000 0.7785835 0.6156791
#> x3 0.6290593 0.7785835 1.0000000 0.7689832
#> x4 0.4916759 0.6156791 0.7689832 1.0000000
```
