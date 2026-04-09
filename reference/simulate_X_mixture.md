# Simulate X from a mixture model

Simulate X from a mixture model

## Usage

``` r
simulate_X_mixture(
  n,
  p_cat,
  p_cont,
  cat_level_list,
  cat_comb_prob,
  cont_para_list
)
```

## Arguments

- n:

  total number of units simulated

- p_cat:

  dimension of categorical covariates

- p_cont:

  dimension of continuous covariates

- cat_level_list:

  a list describing the levels of categorical variables

- cat_comb_prob:

  probability of each combination of categorical variables

- cont_para_list:

  List of parameter lists for continuous covariates (each with `mean`
  and `sigma`).

## Value

a list contains simulated covariates

## Examples

``` r
if (FALSE) { # \dontrun{
X <- simulate_X_mixture(
  n = 100, p_cat = 0, p_cont = 2,
  cat_level_list = list(),
  cat_comb_prob = c(),
  cont_para_list = list(list(mean = c(0, 0), sigma = diag(2)))
)
} # }
```
