test_that("SCM returns expected structure", {
  res <- rdborrow:::SCM(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc",
    lambda.min = 0,
    lambda.max = 1e-3,
    nlambda = 2,
    parallel = "no"
  )
  expect_s3_class(res, "data.frame")
  expect_identical(nrow(res), 2L)
})

test_that("SCM produces finite estimates with valid CIs", {
  res <- rdborrow:::SCM(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc",
    lambda.min = 0,
    lambda.max = 1e-3,
    nlambda = 2,
    parallel = "no"
  )
  expect_all_true(is.finite(res$point_estimates))
  expect_all_true(res$lower_CI_boot < res$upper_CI_boot)
})

test_that("SCM estimates effects for OLE period only", {
  res <- rdborrow:::SCM(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc",
    lambda.min = 0,
    lambda.max = 1e-3,
    nlambda = 2,
    parallel = "no"
  )
  expect_identical(rownames(res), c("tau3", "tau4"))
})
