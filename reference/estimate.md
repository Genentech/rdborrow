# Run estimation for a method object

S4 generic that dispatches to the appropriate estimation logic based on
the method class. Each method subclass (e.g., `ec_ipw_method`,
`did_ec_ipw_method`) implements its own `estimate()` method containing
the full estimation pipeline.

## Usage

``` r
estimate(method, ...)

# S4 method for class 'ec_ipw_method'
estimate(
  method,
  data,
  outcomes,
  treatment,
  trial_status,
  covariates,
  alpha = 0.05,
  quiet = TRUE
)

# S4 method for class 'did_ec_ipw_method'
estimate(
  method,
  data,
  outcomes,
  treatment,
  trial_status,
  covariates,
  alpha = 0.05,
  quiet = TRUE,
  T_cross
)

# S4 method for class 'did_ec_aipw_method'
estimate(
  method,
  data,
  outcomes,
  treatment,
  trial_status,
  covariates,
  alpha = 0.05,
  quiet = TRUE,
  T_cross
)

# S4 method for class 'did_ec_or_method'
estimate(
  method,
  data,
  outcomes,
  treatment,
  trial_status,
  covariates,
  alpha = 0.05,
  quiet = TRUE,
  T_cross
)

# S4 method for class 'ec_aipw_method'
estimate(
  method,
  data,
  outcomes,
  treatment,
  trial_status,
  covariates,
  alpha = 0.05,
  quiet = TRUE
)

# S4 method for class 'scm_method'
estimate(
  method,
  data,
  outcomes,
  treatment,
  trial_status,
  covariates,
  alpha = 0.05,
  quiet = TRUE,
  T_cross
)
```

## Arguments

- method:

  An S4 method object (e.g., from
  [`ec_ipw`](https://genentech.github.io/rdborrow/reference/ec_ipw.md)).

- ...:

  Additional method-specific arguments.

- data:

  Data frame with all subjects (RCT + external controls).

- outcomes:

  Character vector of outcome column names.

- treatment:

  Name of the treatment column.

- trial_status:

  Name of the trial participation column.

- covariates:

  Character vector of covariate column names.

- alpha:

  Significance level (default 0.05).

- quiet:

  Logical. Suppress output (default TRUE).

- T_cross:

  Integer crossover time point (OLE methods only).

## Value

A list with estimation results.

## Examples

``` r
method <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
estimate(
  method,
  data = SyntheticData,
  outcomes = c("y1", "y2"),
  treatment = "A",
  trial_status = "S",
  covariates = c("x1", "x2", "x3", "x4", "x5")
)
#> $results
#>      point_estimates standard_deviation lower_CI_normal upper_CI_normal
#> tau1      -0.1971969          0.5134018       -1.203446        0.809052
#> tau2       0.4697209          0.5410007       -0.590621        1.530063
#> 
#> $borrow_weight
#> [1] 0.1475196
#> 
```
