tol <- 1e-6

test_that("DID-EC-IPW point estimates and bootstrap CIs", {
  bootstrap_obj <- setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")
  method <- setup_method_DID(
    method_name = "IPW",
    bootstrap_flag = TRUE,
    bootstrap_obj = bootstrap_obj,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5"
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
  expect_equal(res$point_estimates[1], 2.0759256334, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.3894380397, tolerance = tol)
})
