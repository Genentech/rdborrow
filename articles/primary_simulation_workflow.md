# Simulation Workflow for Primary Analysis

## Primary analysis

This vignette demonstrates Monte Carlo simulation for evaluating the
EC-IPW and EC-AIPW weighting estimators proposed in [Zhou et
al. (2024)](https://doi.org/10.1093/jrsssa/qnae075) for the primary
(placebo-controlled) phase.

### 1 Simulate a list of datasets for primary analysis

#### 1.1 Create basic setup

``` r

# Initialize an empty data list
set.seed(2023)

data_matrix_list_null <- list()
data_matrix_list_alt <- list()
ntrial <- 500

# Specify the significance level alpha
alpha <- 0.05

# Specify the true effect size at the end of the study
true_effect <- 0
alt_effect <- 2.0 # tune this

# Specify column names
covariates_col_name <- c("x1", "x2", "x3", "x4", "x5")
outcome_col_name <- c("y1", "y2")
treatment_col_name <- "A"
trial_status_col_name <- "S"
```

#### 1.2 Generate simulation data list for null hypothesis

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
  # model_form_x_t3 = setNames(c(5.0, 1.9, 1.4, -1.3, -0.4, -0.15), varnames) # 1.6*A, sigma = 4.0
  # model_form_x_t4 = setNames(c(1.2, 1.0, 2.0, -0.5, -0.4, -0.10), varnames) # 2.5*A, sigma = 5.0

  outcome_model_specs <- list(
    list(
      effect = 0, model_form_x = model_form_x_t1, # from data: true_effect = 1.5
      noise_mean = 0, noise_sd = 4
    ), # model form for the first time point, given by model_form1
    list(
      effect = true_effect, model_form_x = model_form_x_t2, # from data: true_effect = 1.8
      noise_mean = 0, noise_sd = 4
    ) # model form for the second time point, given by model_form2
  )

  # =========== generate trial data ============
  Data <- simulate_trial(X_int,
    X_ext,
    num_treated = 100,
    OLE_flag = FALSE,
    T_cross = 2,
    outcome_model_specs
  )

  data_matrix_list_null[[trial_iter]] <- Data
}


head(data_matrix_list_null[[1]])
#>   x1 x2 x3 x4       x5 A S         y1         y2
#> 1  0  0  0  2 37.56031 1 1  3.0752036  7.4562185
#> 2  1  1  0 15 32.11467 0 1  0.3814777  1.4237345
#> 3  1  1  0  5 29.65879 1 1 -2.1309058  4.8196265
#> 4  1  1  0 14 48.56377 1 1 -0.7990459 -3.6642685
#> 5  1  1  1 21 15.37401 1 1  1.7543228 -0.5165716
#> 6  1  1  1 13 23.47198 1 1 -2.1335935 -4.0533044
```

#### 1.3 Generate simulation data list for alternative hypothesis

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
  # model_form_x_t3 = setNames(c(5.0, 1.9, 1.4, -1.3, -0.4, -0.15), varnames) # 1.6*A, sigma = 4.0
  # model_form_x_t4 = setNames(c(1.2, 1.0, 2.0, -0.5, -0.4, -0.10), varnames) # 2.5*A, sigma = 5.0

  outcome_model_specs <- list(
    list(
      effect = 0, model_form_x = model_form_x_t1, # from data: true_effect = 1.5
      noise_mean = 0, noise_sd = 4
    ), # model form for the first time point, given by model_form1
    list(
      effect = alt_effect, model_form_x = model_form_x_t2, # from data: true_effect = 1.8
      noise_mean = 0, noise_sd = 4
    ) # model form for the second time point, given by model_form2
  )

  # =========== generate trial data ============
  Data <- simulate_trial(X_int,
    X_ext,
    num_treated = 100,
    OLE_flag = FALSE,
    T_cross = 2,
    outcome_model_specs
  )

  data_matrix_list_alt[[trial_iter]] <- Data
}

head(data_matrix_list_alt[[1]])
#>   x1 x2 x3 x4       x5 A S        y1        y2
#> 1  1  1  0  9 34.26100 1 1 5.0618055  1.541674
#> 2  1  1  0  3 38.96407 0 1 1.5177566  1.929797
#> 3  1  1  0  9 47.73282 0 1 0.9979992  3.777971
#> 4  1  1  0  6 45.96887 1 1 1.4548124 -9.007860
#> 5  1  1  0 14 34.36397 0 1 5.3379200  2.835806
#> 6  1  1  0  3 52.98654 1 1 4.5813799  3.205442
```

### 2 Parametric inference

``` r

method_IPW_optimal_weight <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5"
)

method_AIPW_optimal_weight <- ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)

method_IPW_zero_weight <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  weight = 0
)

method_AIPW_zero_weight <- ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  ),
  weight = 0
)

method_obj_list <- list(
  method_IPW_optimal_weight,
  method_AIPW_optimal_weight,
  method_IPW_zero_weight,
  method_AIPW_zero_weight
)
```

``` r

# create a simulation object for primary analysis
simulation_primary_obj <- setup_simulation_primary(
  data_matrix_list_null = data_matrix_list_null, # two scenarios
  data_matrix_list_alt = data_matrix_list_alt,
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  outcome_col_name = outcome_col_name,
  covariates_col_name = covariates_col_name,
  method_obj_list = method_obj_list,
  true_effect = true_effect,
  alt_effect = alt_effect,
  alpha = alpha,
  method_description = c(
    "IPW, optimal weight",
    "AIPW, optimal weight",
    "IPW, zero weight",
    "AIPW, zero weight"
  )
)
```

``` r

simulation_report <- run_simulation(simulation_primary_obj, quiet = TRUE)
```

``` r

simulation_report # Type I error and Power
#>     method_description          bias  variance       mse coverage type_I_error
#> 1  IPW, optimal weight -0.0541718304 0.4845047 0.4874393    0.946        0.054
#> 2 AIPW, optimal weight  0.0011470217 0.3140481 0.3140494    0.946        0.054
#> 3     IPW, zero weight -0.0007803934 0.5317429 0.5317435    0.956        0.044
#> 4    AIPW, zero weight -0.0005666468 0.3353926 0.3353929    0.946        0.054
#>   power
#> 1 0.784
#> 2 0.954
#> 3 0.786
#> 4 0.944
```

### 3 Bootstrap inference

``` r

method_IPW_optimal_weight <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

method_AIPW_optimal_weight <- ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5 + y1"
  ),
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

method_IPW_zero_weight <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  weight = 0,
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

method_AIPW_zero_weight <- ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5 + y1"
  ),
  weight = 0,
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

method_obj_list <- list(
  method_IPW_optimal_weight,
  method_AIPW_optimal_weight,
  method_IPW_zero_weight,
  method_AIPW_zero_weight
)
```

``` r

# create a simulation object for primary analysis
simulation_primary_obj <- setup_simulation_primary(
  data_matrix_list_null = data_matrix_list_null,
  data_matrix_list_alt = data_matrix_list_alt,
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  outcome_col_name = outcome_col_name,
  covariates_col_name = covariates_col_name,
  method_obj_list = method_obj_list,
  true_effect = true_effect,
  alt_effect = alt_effect,
  alpha = alpha,
  method_description = c(
    "IPW, optimal weight, bootstrap",
    "AIPW, optimal weight, bootstrap",
    "IPW, zero weight, bootstrap",
    "AIPW, zero weight, bootstrap"
  )
)
```

``` r

simulation_report_bs <- run_simulation(simulation_primary_obj, quiet = TRUE)
```

``` r

simulation_report_bs
#>                method_description          bias  variance       mse coverage
#> 1  IPW, optimal weight, bootstrap -0.0541718304 0.4845047 0.4874393    0.944
#> 2 AIPW, optimal weight, bootstrap  0.0032679422 0.3159685 0.3159792    0.952
#> 3     IPW, zero weight, bootstrap -0.0007803934 0.5317429 0.5317435    0.954
#> 4    AIPW, zero weight, bootstrap  0.0014500246 0.3367785 0.3367806    0.944
#>   type_I_error power
#> 1        0.056 0.750
#> 2        0.048 0.910
#> 3        0.046 0.722
#> 4        0.056 0.890
```

## References

- Zhou X, Zhu J, Drake C, Pang H (2024). “Causal estimators for
  incorporating external controls in randomized trials with longitudinal
  outcomes.” *Journal of the Royal Statistical Society Series A:
  Statistics in Society*. doi:
  [10.1093/jrsssa/qnae075](https://doi.org/10.1093/jrsssa/qnae075).
- Shi L, Pang H, Chen C, Zhu J (2025). “rdborrow: an R package for
  causal inference incorporating external controls in randomized
  controlled trials with longitudinal outcomes.” *Journal of
  Biopharmaceutical Statistics*, 35(6), 1043-1066. doi:
  [10.1080/10543406.2025.2489283](https://doi.org/10.1080/10543406.2025.2489283).
