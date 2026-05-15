tol <- 1e-6

test_that("SCM runs and returns valid structure", {
  skip_on_cran()

  bootstrap_obj <- setup_bootstrap(replicates = 5, bootstrap_CI_type = "perc")
  method <- suppressWarnings(setup_method_SCM(
    method_name = "SCM",
    bootstrap_flag = TRUE,
    bootstrap_obj = bootstrap_obj,
    lambda.min = 0.0005,
    lambda.max = 0.0005,
    nlambda = 1,
    parallel = "no",
    ncpus = 1
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
  res <- suppressWarnings(run_analysis(analysis))

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)
  expect_named(res, c("point_estimates", "lower_CI_boot", "upper_CI_boot"))
  expect_all_true(is.finite(res$point_estimates))
  expect_all_true(res$lower_CI_boot <= res$upper_CI_boot)
})

# new API----

test_that("scm() matches old API structure", {
  skip_on_cran()

  method <- scm(
    lambda_min = 0.0005,
    lambda_max = 0.0005,
    nlambda = 1,
    bootstrap = 5,
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

  set.seed(42)
  res <- suppressWarnings(run_analysis(analysis))

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)
  expect_all_true(is.finite(res$point_estimates))
  expect_all_true(res$lower_CI_boot <= res$upper_CI_boot)
})
