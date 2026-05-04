# Simulate outcomes from additive linear models

Generates longitudinal outcomes from a structural causal model of the
form \`Y_t = A \* effect + X phase (\`t \<= T_cross\`), treatment
assignment \`A\` is used directly. In the OLE phase (\`t \> T_cross\`),
all RCT patients are assumed to receive treatment (effect multiplied by
1 instead of \`A\`).

## Usage

``` r
simulate_outcome_from_model(X, A, outcome_model_specs, OLE_flag, T_cross)
```

## Arguments

- X:

  Data frame of covariates.

- A:

  Numeric vector of treatment indicators (same length as \`nrow(X)\`).

- outcome_model_specs:

  List of lists, one per time point. See Details above.

- OLE_flag:

  Logical. If \`TRUE\`, time points after \`T_cross\` use the OLE model
  (all patients treated).

- T_cross:

  Positive integer. The crossover time point separating the primary and
  OLE phases. Only used when \`OLE_flag = TRUE\`.

## Value

A data frame with \`n\` rows and one column per time point (\`y1\`,
\`y2\`, ...).

## Details

Each element of \`outcome_model_specs\` is a list with:

- \`effect\`:

  Numeric scalar. Treatment effect for this time point.

- \`model_form_x\`:

  Named numeric vector of covariate coefficients. Names must include
  \`"1"\` (intercept) and match column names in \`X\`.

- \`noise_mean\`:

  Numeric scalar. Mean of the normal noise.

- \`noise_sd\`:

  Numeric scalar. SD of the normal noise.

## Examples

``` r
X <- data.frame(x1 = rnorm(20), x2 = rnorm(20))
A <- rbinom(20, 1, 0.5)
specs <- list(
  list(
    effect = 1.5,
    model_form_x = c("1" = 2.0, "x1" = 0.5, "x2" = -0.3),
    noise_mean = 0, noise_sd = 1
  ),
  list(
    effect = 0,
    model_form_x = c("1" = 1.0, "x1" = 0.2, "x2" = 0.1),
    noise_mean = 0, noise_sd = 1
  )
)
Y <- simulate_outcome_from_model(X, A, specs, OLE_flag = FALSE, T_cross = 2)
```
