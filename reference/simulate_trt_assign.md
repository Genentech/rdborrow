# Simulate treatment assignment

Randomly assigns treatment to RCT patients (\`S = 1\`) with a given
probability. External control patients (\`S = 0\`) always receive
control (\`A = 0\`).

## Usage

``` r
simulate_trt_assign(X, S, prob)
```

## Arguments

- X:

  Data frame of covariates. Must have the same number of rows as \`S\`.

- S:

  Data frame with a column \`S\` indicating trial status (1 = RCT, 0 =
  external control).

- prob:

  Numeric scalar between 0 and 1. Probability of treatment assignment
  for RCT patients.

## Value

A single-column data frame with column \`A\` indicating treatment status
(1 = treated, 0 = control).

## Examples

``` r
X <- SyntheticData[c("x1", "x2")]
S <- SyntheticData["S"]
A <- simulate_trt_assign(X, S, prob = 1 / 2)
```
