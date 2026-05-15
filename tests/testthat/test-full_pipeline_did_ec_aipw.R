tol <- 1e-6

test_that("DID-EC-AIPW point estimates and bootstrap CIs", {
  bootstrap_obj <- setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")
  method <- setup_method_DID(
    method_name = "AIPW",
    bootstrap_flag = TRUE,
    bootstrap_obj = bootstrap_obj,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5",
      "y3 ~ x1 + x2 + x3 + x4 + x5",
      "y4 ~ x1 + x2 + x3 + x4 + x5"
    )
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
  expect_equal(res$point_estimates[1], 2.0417274627, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.0361177594, tolerance = tol)
})

# new API----

test_that("did_ec_aipw() matches old API", {
  method <- did_ec_aipw(
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
    outcome_formula = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5",
      "y3 ~ x1 + x2 + x3 + x4 + x5",
      "y4 ~ x1 + x2 + x3 + x4 + x5"
    ),
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
  expect_equal(res$point_estimates[1], 2.0417274627, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.0361177594, tolerance = tol)
})
