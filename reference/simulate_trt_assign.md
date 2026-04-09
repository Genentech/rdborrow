# Title

Title

## Usage

``` r
simulate_trt_assign(X, S, prob)
```

## Arguments

- X:

  Data frame of covariates.

- S:

  Data frame with trial status indicator.

- prob:

  Probability of treatment assignment.

## Value

Vector A that indicates the treatment status

## Examples

``` r
if (FALSE) { # \dontrun{
A <- simulate_trt_assign(
  X = SyntheticData %>% select(x1, x2),
  S = SyntheticData %>% select(S),
  prob = 1 / 2
)
} # }
```
