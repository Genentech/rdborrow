# OLE Analysis Workflow

## OLE phase

This vignette demonstrates the open-label extension (OLE) phase analysis
workflow using the difference-in-differences (DID) and synthetic control
method (SCM) estimators proposed in [Zhou et
al. (2024)](https://doi.org/10.1080/10543406.2024.2444222) for
estimating long-term treatment effects when the control group switches
to treatment.

The `SyntheticData` dataset has outcomes `y1`, `y2`, `y3`, `y4` measured
at four time points, and `T_cross = 2`. This means `y1` and `y2` are
from the placebo-controlled phase (Period I) and `y3` and `y4` are from
the open-label extension (Period II). `T_cross` is the last column index
of Period I in `outcome_col_name`.

``` r

head(SyntheticData[, c("A", "S", "y1", "y2", "y3", "y4")])
```

    ##   A S         y1         y2         y3        y4
    ## 1 1 1  3.4512377 -0.7642287 -2.4713591  3.935466
    ## 2 1 1  0.4518106  6.3516296  4.5231869 -0.198674
    ## 3 0 1  3.0532714 -2.0453190  5.9064870 -1.374919
    ## 4 1 1 -9.1183948  0.2304339  4.7858172  8.490757
    ## 5 0 1 -1.4270057  1.5878794  3.7006101  9.449632
    ## 6 0 1 -2.6967072 -0.6130288  0.7482786 -2.413717

### 1 DID methods

#### 1.1 DID-EC-IPW

``` r

method <- did_ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
  bootstrap = 50
)

analysis <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method
)

run_analysis(analysis)
```

    ##      point_estimates lower_CI_boot upper_CI_boot
    ## tau3        2.075926     0.1198765      4.230701
    ## tau4        4.389438     0.8192601      7.040613

#### 1.2 DID-EC-AIPW

``` r

model_forms <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)

method <- did_ec_aipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = model_forms,
  bootstrap = 50
)

analysis <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method
)

run_analysis(analysis)
```

    ##      point_estimates lower_CI_boot upper_CI_boot
    ## tau3        2.041727    -1.3020727      4.372254
    ## tau4        4.036118     0.6559398      7.388494

#### 1.3 DID-EC-OR

``` r

model_forms <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)

method <- did_ec_or(
  outcome_formula_ext = model_forms,
  outcome_formula_rct_ctrl = model_forms,
  outcome_formula_rct_trt = model_forms,
  bootstrap = 50
)

analysis <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method
)

run_analysis(analysis)
```

    ##      point_estimates lower_CI_boot upper_CI_boot
    ## tau3        1.568947      -1.06647      4.138741
    ## tau4        4.407834       1.91722      7.107674

### 2 Synthetic control method

``` r

method <- scm(
  lambda_min = 0,
  lambda_max = 1e-3,
  nlambda = 2,
  bootstrap = 10,
  bootstrap_ci_type = "perc"
)

analysis <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method
)

run_analysis(analysis)
```

    ##      point_estimates lower_CI_boot upper_CI_boot
    ## tau3        2.064756      1.518103      2.677024
    ## tau4        3.943234      1.931972      7.565861

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
