# OLE Analysis Workflow

## OLE phase

### 1 DID methods

#### 1.1 IPW

``` r
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

method_DID_obj <- setup_method_DID(
  method_name = "IPW",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5"
)

analysis_OLE_obj <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method_DID_obj
)

res <- run_analysis(analysis_OLE_obj)
```

#### 1.2 AIPW

``` r
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

model_form_mu <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)

method_DID_obj <- setup_method_DID(
  method_name = "AIPW",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5",
  model_form_mu0_ext = model_form_mu
)

analysis_OLE_obj <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method_DID_obj
)

res <- run_analysis(analysis_OLE_obj)
```

#### 1.3 OR

``` r
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

model_form_mu <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)

method_DID_obj <- setup_method_DID(
  method_name = "OR",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_mu0_ext = model_form_mu,
  model_form_mu0_rct = model_form_mu,
  model_form_mu1_rct = model_form_mu
)

analysis_OLE_obj <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method_DID_obj
)

res <- run_analysis(analysis_OLE_obj)
res
```

    ##      point_estimates lower_CI_boot upper_CI_boot
    ## tau3        1.568947      -1.06647      4.138741
    ## tau4        4.407834       1.91722      7.107674

### 2 SCM method: with parallel computing

``` r
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

method_SCM_obj <- setup_method_SCM(
  method_name = "SCM",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  lambda.min = 0,
  lambda.max = 1e-3,
  nlambda = 10,
  parallel = "no",
  ncpus = 1
)

analysis_OLE_obj <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method_SCM_obj
)

run_analysis(analysis_OLE_obj)
```

    ## Running the synthetic control method...
    ## Performing cross validation for tuning parameter selection...

    ## ℹ In a future CVXR release, `solve()` will return the optimal value directly
    ##   (like `psolve()`).
    ## ℹ The `$getValue()`/`$getDualValue()` interface will be removed.
    ## ℹ New API: `psolve(prob)`, then `value(x)`, `dual_value(constr)`,
    ##   `status(prob)`.
    ## This message is displayed once per session.

    ## Warning: `getValue()` is deprecated.
    ## ℹ Use `value(x)` after solving instead.
    ## This warning is displayed once per session.

    ## Constructing pseudo controls for internal data...
    ## Performing bootstrap inference with SCM estimates...

    ## Warning: Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.

    ## Warning: Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.

    ## time elapsed for bootstrap:  9.41

    ##      point_estimates lower_CI_boot upper_CI_boot
    ## tau3        2.134082     0.6776431      4.008635
    ## tau4        3.950783     1.3126432      6.895732

### 3 SCM method: without parallel computing

``` r
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

method_SCM_obj <- setup_method_SCM(
  method_name = "SCM",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  lambda.min = 0,
  lambda.max = 1e-3,
  nlambda = 10,
  parallel = "no"
)

analysis_OLE_obj <- setup_analysis_OLE(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2,
  method_OLE_obj = method_SCM_obj
)

run_analysis(analysis_OLE_obj)
```

    ## Running the synthetic control method...
    ## Performing cross validation for tuning parameter selection...
    ## Constructing pseudo controls for internal data...
    ## Performing bootstrap inference with SCM estimates...

    ## Warning: Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.
    ## Solution may be inaccurate. Try another solver, adjusting the solver settings,
    ## or solve with `verbose = TRUE` for more information.

    ## time elapsed for bootstrap:  9.72

    ##      point_estimates lower_CI_boot upper_CI_boot
    ## tau3        2.134082     0.5584951      3.910489
    ## tau4        3.950783     1.1203356      7.356058
