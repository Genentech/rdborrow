# Simulation Workflow for OLE Phase

## OLE study

This vignette demonstrates Monte Carlo simulation for evaluating the
difference-in-differences (DID) estimators proposed in [Zhou et
al. (2024)](https://doi.org/10.1080/10543406.2024.2444222) for the
open-label extension (OLE) phase.

The simulated data has four outcome columns (`y1`, `y2`, `y3`, `y4`) and
a crossover point `T_cross = 2`. This means:

- **`y1`, `y2`** (columns 1 to `T_cross`): placebo-controlled phase
  (Period I). Both RCT controls and external controls are untreated.
  These outcomes serve as negative controls for bias correction.
- **`y3`, `y4`** (columns `T_cross + 1` to end): open-label extension
  phase (Period II). RCT controls have switched to treatment; external
  controls remain untreated. Treatment effects are estimated here.

In other words, `T_cross` is the last index of the placebo-controlled
phase in `outcome_col_name`.

``` r

head(SyntheticData)
#>   x1 x2 x3 x4       x5 A S T_cross         y1         y2         y3        y4
#> 1  1  1  1  9 54.59836 1 1       2  3.4512377 -0.7642287 -2.4713591  3.935466
#> 2  0  1  0  8 33.08006 1 1       2  0.4518106  6.3516296  4.5231869 -0.198674
#> 3  1  1  1  7 48.51653 0 1       2  3.0532714 -2.0453190  5.9064870 -1.374919
#> 4  1  1  1 15 31.68766 1 1       2 -9.1183948  0.2304339  4.7858172  8.490757
#> 5  1  1  1 12 29.98495 0 1       2 -1.4270057  1.5878794  3.7006101  9.449632
#> 6  1  1  0  7 46.08991 0 1       2 -2.6967072 -0.6130288  0.7482786 -2.413717
```

### 1. Simulate a dataset for OLE study

``` r

# Initialize an empty data list
set.seed(2023)

data_matrix_list <- list()
ntrial <- 500

# Specify the significance level alpha
alpha <- 0.05

# Specify the true effect size at the end of the OLE study
true_effect_long <- 0

# Specify column names
covariates_col_name <- c("x1", "x2", "x3", "x4", "x5")
outcome_col_name <- c("y1", "y2", "y3", "y4")
treatment_col_name <- "A"
trial_status_col_name <- "S"
```

``` r

# Sequentially adding in datasets
for (trial_iter in 1:ntrial) {
  # simulate 300 sample
  normal <- copula::normalCopula(param = c(0.8), dim = 4, dispstr = "ar1")

  # ========== generate internal covariates =============
  X_int <- simulate_X_copula(
    n = 200,
    p = 4,
    cp = normal, # copula
    margins = c("binom", "binom", "binom", "exp"), # specify marginal distributions
    paramMargins = list(
      list(size = 1, prob = 0.7), # specify parameters for marginals
      list(size = 1, prob = 0.9),
      list(size = 1, prob = 0.3),
      list(rate = 1 / 10)
    )
  )

  X_int$x4 <- round(X_int$x4) + 1
  X_int$x5 <- 30 + 10 * X_int$x1 + (7) * X_int$x2 + (-6) * X_int$x3 + (-0.5) * X_int$x4 + rnorm(200, mean = 0, sd = 10)

  varnames <- c("1", paste0("x", 1:5))

  # ============ generate external covariates ==============
  X_ext <- simulate_X_copula(
    n = 100,
    p = 4,
    cp = normal, # copula
    margins = c("binom", "binom", "binom", "exp"), # specify marginal distributions
    paramMargins = list(
      list(size = 1, prob = 0.7), # specify parameters for marginals
      list(size = 1, prob = 0.9),
      list(size = 1, prob = 0.3),
      list(rate = 1 / 10)
    )
  )

  X_ext$x4 <- round(X_ext$x4) + 1
  X_ext$x5 <- 50 + 10 * X_ext$x1 + (2) * X_ext$x2 + (-1) * X_ext$x3 + (-0.3) * X_ext$x4 + rnorm(100, mean = 0, sd = 10)

  varnames <- c("1", paste0("x", 1:5))

  # ============ Specify outcome models ==============
  model_form_x_t1 <- setNames(c(10.0, 0.05, -1.5, -1.0, -0.2, -0.1), varnames) # 1.5*A, sigma = 4.0
  model_form_x_t2 <- setNames(c(6.0, 0.5, -0.5, -1.0, -0.3, -0.06), varnames) # 1.8*A, sigma = 4.0
  model_form_x_t3 <- setNames(c(5.0, 1.9, 1.4, -1.3, -0.4, -0.15), varnames) # 1.6*A, sigma = 4.0
  model_form_x_t4 <- setNames(c(1.2, 1.0, 2.0, -0.5, -0.4, -0.10), varnames) # 2.5*A, sigma = 5.0

  outcome_model_specs <- list(
    list(
      effect = 0, model_form_x = model_form_x_t1, # from data: true_effect = 1.5
      noise_mean = 0, noise_sd = 4
    ), # model form for the first time point, given by model_form_x_t1
    list(
      effect = 0, model_form_x = model_form_x_t2, # from data: true_effect = 1.8
      noise_mean = 0, noise_sd = 4
    ), # model form for the second time point, given by model_form_x_t2
    list(
      effect = 0, model_form_x = model_form_x_t3, # from data: true_effect = 1.6
      noise_mean = 0, noise_sd = 4
    ), # model form for the third time point, given by model_form_x_t3
    list(
      effect = true_effect_long, model_form_x = model_form_x_t4, # from data: true_effect = 2.5
      noise_mean = 0, noise_sd = 4
    ) # model form for the fourth time point, given by model_form_x_t4
  )

  # =========== generate trial data ============
  Data <- simulate_trial(X_int,
    X_ext,
    num_treated = 150,
    OLE_flag = TRUE,
    T_cross = 2,
    outcome_model_specs
  )


  data_matrix_list[[trial_iter]] <- Data
}
```

### 2 Bootstrap inference

``` r

model_form_mu <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)

method_IPW_DID <- did_ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

method_AIPW_DID <- did_ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = model_form_mu,
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

method_OR_DID <- did_ec_or(
  outcome_formula_ext = model_form_mu,
  outcome_formula_rct_ctrl = model_form_mu,
  outcome_formula_rct_trt = model_form_mu,
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

method_obj_list <- list(
  method_IPW_DID,
  method_AIPW_DID,
  method_OR_DID
)
```

``` r

# create a simulation object for primary analysis
simulation_OLE_obj <- setup_simulation_OLE(
  data_matrix_list = data_matrix_list, # two scenarios
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  outcome_col_name = outcome_col_name,
  covariates_col_name = covariates_col_name,
  method_obj_list = method_obj_list,
  true_effect = true_effect_long,
  T_cross = 2,
  alpha = alpha,
  method_description = c(
    "IPW, DID",
    "AIPW, DID",
    "OR, DID"
  )
)
```

``` r

simulation_report <- run_simulation(simulation_OLE_obj, quiet = TRUE)
```

``` r

simulation_report
#>   method_description         bias variance      mse coverage type_I_error
#> 1           IPW, DID -0.282537033 3.187900 3.267727    0.942        0.058
#> 2          AIPW, DID  0.001684041 3.328328 3.328331    0.942        0.058
#> 3            OR, DID  0.035746079 1.459605 1.460883    0.960        0.040
```

## References

- Zhou X, Pang H, Drake C, Burger HU, Zhu J (2024). “Estimating
  treatment effect in randomized trial after control to treatment
  crossover using external controls.” *Journal of Biopharmaceutical
  Statistics*. doi:
  [10.1080/10543406.2024.2444222](https://doi.org/10.1080/10543406.2024.2444222).
- Shi L, Pang H, Chen C, Zhu J (2025). “rdborrow: an R package for
  causal inference incorporating external controls in randomized
  controlled trials with longitudinal outcomes.” *Journal of
  Biopharmaceutical Statistics*, 35(6), 1043-1066. doi:
  [10.1080/10543406.2025.2489283](https://doi.org/10.1080/10543406.2025.2489283).
