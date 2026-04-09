# simulate X by coupling several marginal distributions using copula

simulate X by coupling several marginal distributions using copula

## Usage

``` r
simulate_X_copula(n, p, cp, margins, paramMargins)
```

## Arguments

- n:

  total number of units simulated

- p:

  dimension of the parameters

- cp:

  copula

- margins:

  marginal distributions

- paramMargins:

  parameters for the marginal distributions

## Value

a list contains simulated data and true ATE

## Examples

``` r
if (FALSE) { # \dontrun{
normal <- normalCopula(param = c(0.8), dim = 4, dispstr = "ar1")
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
} # }
```
