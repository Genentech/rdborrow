# Primary Analysis Workflow

## Primary analysis

### 1 load and visualize data

``` r
# load the simulated dataset
head(SyntheticData)
```

    ##   x1 x2 x3 x4       x5 A S T_cross         y1         y2         y3        y4
    ## 1  1  1  1  9 54.59836 1 1       2  3.4512377 -0.7642287 -2.4713591  3.935466
    ## 2  0  1  0  8 33.08006 1 1       2  0.4518106  6.3516296  4.5231869 -0.198674
    ## 3  1  1  1  7 48.51653 0 1       2  3.0532714 -2.0453190  5.9064870 -1.374919
    ## 4  1  1  1 15 31.68766 1 1       2 -9.1183948  0.2304339  4.7858172  8.490757
    ## 5  1  1  1 12 29.98495 0 1       2 -1.4270057  1.5878794  3.7006101  9.449632
    ## 6  1  1  0  7 46.08991 0 1       2 -2.6967072 -0.6130288  0.7482786 -2.413717

### 2 Estimation and inference:

#### 2.1 Inverse probability weighting (IPW)

1.  IPW with zero weight (wt = 0):

``` r
# test: within trial
## Data argument + column names (coxph, glm)
method_weighting_obj <- setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = FALSE,
  wt = 0,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)

res <- run_analysis(analysis_primary_obj)
res
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_normal upper_CI_normal
    ## tau1     -0.02808704          0.5367987      -1.0801931        1.024019
    ## tau2      0.40959558          0.5625763      -0.6930338        1.512225
    ## 
    ## $borrow_weight
    ## [1] 0

2.  IPW with data-adaptive weight:

``` r
# test: within trial
method_weighting_obj <- setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = TRUE,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)

res <- run_analysis(analysis_primary_obj)

res$borrow_weight
```

    ## [1] 0.1475196

``` r
res$results
```

    ##      point_estimates standard_deviation lower_CI_normal upper_CI_normal
    ## tau1      -0.1971969          0.5134018       -1.203446        0.809052
    ## tau2       0.4697209          0.5410007       -0.590621        1.530063

#### 2.2 Augmented inverse probability weighting (AIPW)

The second approach is AIPW, which also accommodates two external
borrowing strategies.

1.  AIPW with zero weight (wt = 0):

``` r
# test: AIPW with 0 weight, should be same as IPW with 0 weight
method_weighting_obj <- setup_method_weighting(
  method_name = "AIPW",
  optimal_weight_flag = FALSE,
  wt = 0,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_mu0_ext = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)

res <- run_analysis(analysis_primary_obj)
```

2.  AIPW with data adaptive weight:

``` r
# test: AIPW with given weight
# bootstrap as part of the method and analysis
method_weighting_obj <- setup_method_weighting(
  method_name = "AIPW",
  optimal_weight_flag = TRUE,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_mu0_ext = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)

res <- run_analysis(analysis_primary_obj)
```

### 3 Bootstrap inference

In this section we present Bootstrap inference results. We report
Bootstrap confidence intervals with adjusted quantile ranges.

1.  IPW with bootstrap CI

``` r
# test: within trial
## Data argument + column names (coxph, glm)
## having a bootstrap_flag outside the class
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

method_weighting_obj <- setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = TRUE,
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  wt = 0,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)

res <- run_analysis(analysis_primary_obj)
res
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_boot upper_CI_boot
    ## tau1      -0.1971969          0.5134018    -1.1788096     0.8804926
    ## tau2       0.4697209          0.5410007    -0.6244215     1.8038458
    ## 
    ## $borrow_weight
    ## [1] 0.1475196

2.  AIPW with bootstrap CI

``` r
# test: with optimal weight
## Data argument + column names (coxph, glm)
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

method_weighting_obj <- setup_method_weighting(
  method_name = "AIPW",
  optimal_weight_flag = TRUE,
  wt = 0,
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_mu0_ext = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)

analysis_primary_obj <- setup_analysis_primary(
  data = SyntheticData,
  trial_status = "S",
  treatment = "A",
  outcome = c("y1", "y2"),
  covariates = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method_weighting_obj
)


res <- run_analysis(analysis_primary_obj)

## best to just do the last one, but also have options
## time dependent way of effects and modeling
```

### 4 Notes

1.  When there are missing values in the data, the suggestion we have
    for now is to preprocess the dataset (such as deletion, imputing,
    etc.) to obtain a dataset without missingness, then apply the
    package. For general methodology development regarding missing
    values, we save it for future research work.
