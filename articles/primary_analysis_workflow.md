# Primary Analysis Workflow

## Primary analysis

This vignette demonstrates the primary analysis workflow using the
EC-IPW and EC-AIPW weighting estimators proposed in [Zhou et
al. (2024)](https://doi.org/10.1093/jrsssa/qnae075) for incorporating
external controls in randomized trials with longitudinal outcomes.

### 1 Load data

``` r

head(SyntheticData)
```

    ##   x1 x2 x3 x4       x5 A S T_cross         y1         y2         y3        y4
    ## 1  1  1  1  9 54.59836 1 1       2  3.4512377 -0.7642287 -2.4713591  3.935466
    ## 2  0  1  0  8 33.08006 1 1       2  0.4518106  6.3516296  4.5231869 -0.198674
    ## 3  1  1  1  7 48.51653 0 1       2  3.0532714 -2.0453190  5.9064870 -1.374919
    ## 4  1  1  1 15 31.68766 1 1       2 -9.1183948  0.2304339  4.7858172  8.490757
    ## 5  1  1  1 12 29.98495 0 1       2 -1.4270057  1.5878794  3.7006101  9.449632
    ## 6  1  1  0  7 46.08991 0 1       2 -2.6967072 -0.6130288  0.7482786 -2.413717

### 2 EC-IPW

#### 2.1 No borrowing (weight = 0)

``` r

method <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  weight = 0
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

run_analysis(analysis)
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_normal upper_CI_normal
    ## tau1     -0.02808704          0.5367987      -1.0801931        1.024019
    ## tau2      0.40959558          0.5625763      -0.6930338        1.512225
    ## 
    ## $borrow_weight
    ## [1] 0

#### 2.2 Optimal weight (data-adaptive)

``` r

method <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

run_analysis(analysis)
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_normal upper_CI_normal
    ## tau1      -0.1971969          0.5134018       -1.203446        0.809052
    ## tau2       0.4697209          0.5410007       -0.590621        1.530063
    ## 
    ## $borrow_weight
    ## [1] 0.1475196

#### 2.3 Bootstrap inference

``` r

method <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

run_analysis(analysis)
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_boot upper_CI_boot
    ## tau1      -0.1971969          0.4959412    -1.2142174     0.8434478
    ## tau2       0.4697209          0.5292954    -0.6256452     1.7990102
    ## 
    ## $borrow_weight
    ## [1] 0.1475196

### 3 EC-AIPW

EC-AIPW augments the IPW estimator with an outcome regression model,
making it doubly robust: consistent if either the propensity score model
or the outcome model is correctly specified.

#### 3.1 No borrowing (weight = 0)

``` r

method <- ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  ),
  weight = 0
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

run_analysis(analysis)
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_normal upper_CI_normal
    ## tau1      -0.4361151          0.5552065      -1.5242998       0.6520696
    ## tau2       0.4422248          0.5701633      -0.6752748       1.5597244
    ## 
    ## $borrow_weight
    ## [1] 0

#### 3.2 Optimal weight (data-adaptive)

``` r

method <- ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

run_analysis(analysis)
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_normal upper_CI_normal
    ## tau1      -0.5463256          0.5305614       -1.586207       0.4935556
    ## tau2       0.5401750          0.5543275       -0.546287       1.6266369
    ## 
    ## $borrow_weight
    ## [1] 0.1475196

#### 3.3 Bootstrap inference

``` r

method <- ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  ),
  bootstrap = 50,
  bootstrap_ci_type = "perc"
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

run_analysis(analysis)
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_boot upper_CI_boot
    ## tau1      -0.5463256           0.565138     -1.617718     0.8547375
    ## tau2       0.5401750           0.594804     -0.880384     1.5808952
    ## 
    ## $borrow_weight
    ## [1] 0.1475196

### 4 Notes

1.  When there are missing values in the data, preprocess the dataset
    (deletion, imputation, etc.) to obtain a complete dataset before
    applying the package.

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
