# Simulate trial participation status

Simulates a binary trial participation indicator using a logistic model.
The probability of participation is \`inv.logit(X_intercept covariate
matrix with an intercept column prepended.

## Usage

``` r
simulate_trial_status(X, model_specs)
```

## Arguments

- X:

  Data frame of covariates. The number of columns must equal
  \`length(model_specs\$coef) - 1\` (the intercept is added
  automatically).

- model_specs:

  List with:

  \`family\`

  :   Character string. Currently only \`"binomial"\` is supported.

  \`coef\`

  :   Numeric vector of length \`ncol(X) + 1\`. Logistic regression
      coefficients (intercept first).

## Value

A single-column data frame with column \`S\` (1 = RCT participant, 0 =
external control).

## Examples

``` r
X <- data.frame(x1 = rnorm(20), x2 = rnorm(20))
S <- simulate_trial_status(X, model_specs = list(
  family = "binomial",
  coef = c(0, 0.5, -0.5)
))
```
