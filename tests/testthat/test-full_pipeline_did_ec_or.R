tol <- 1e-6

test_that("DID-EC-OR point estimates and bootstrap CIs", {
  bootstrap_obj <- setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")
  model_forms <- c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5",
    "y3 ~ x1 + x2 + x3 + x4 + x5",
    "y4 ~ x1 + x2 + x3 + x4 + x5"
  )
  method <- suppressWarnings(setup_method_DID(
    method_name = "OR",
    bootstrap_flag = TRUE,
    bootstrap_obj = bootstrap_obj,
    model_form_mu0_ext = model_forms,
    model_form_mu0_rct = model_forms,
    model_form_mu1_rct = model_forms
  ))
  analysis <- setup_analysis_OLE(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    method_OLE_obj = method
  )

  set.seed(42)
  res <- run_analysis(analysis)

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)
  expect_equal(res$point_estimates[1], 1.5689465845, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.4078336543, tolerance = tol)
})

# new API----

test_that("did_ec_or() matches old API", {
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

  set.seed(42)
  res <- run_analysis(analysis)

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)
  expect_equal(res$point_estimates[1], 1.5689465845, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.4078336543, tolerance = tol)
})
