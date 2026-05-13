test_that("EC_IPW_OPT returns expected structure", {
  res <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = FALSE,
    wt = 0
  )
  expect_type(res, "list")
  expect_named(res, c("results", "borrow_weight"))
  expect_s3_class(res$results, "data.frame")
  expect_identical(nrow(res$results), 2L)
  expect_named(res$results, c(
    "point_estimates", "standard_deviation",
    "lower_CI_normal", "upper_CI_normal"
  ))
})

test_that("EC_IPW_OPT with w=0 uses only trial data", {
  res <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = FALSE,
    wt = 0
  )
  expect_identical(res$borrow_weight, 0)
  expect_all_true(is.finite(res$results$point_estimates))
  expect_all_true(res$results$standard_deviation > 0)
  expect_all_true(res$results$lower_CI_normal < res$results$upper_CI_normal)
})

test_that("EC_IPW_OPT with optimal weight borrows from external controls", {
  res <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = TRUE
  )
  expect_gt(res$borrow_weight, 0)
  expect_lt(res$borrow_weight, 1)
  expect_all_true(is.finite(res$results$point_estimates))
  expect_all_true(res$results$standard_deviation > 0)
})

test_that("EC_IPW_OPT with fixed weight uses the specified weight", {
  res <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = FALSE,
    wt = 0.3
  )
  expect_equal(res$borrow_weight, 0.3)
})

test_that("EC_IPW_OPT normal CIs contain the point estimates", {
  res <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = TRUE
  )
  expect_all_true(res$results$point_estimates >= res$results$lower_CI_normal)
  expect_all_true(res$results$point_estimates <= res$results$upper_CI_normal)
})

test_that("EC_IPW_OPT optimal weight produces smaller or equal SE than w=0", {
  res_no <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = FALSE,
    wt = 0
  )
  res_opt <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = TRUE
  )
  expect_all_true(
    res_opt$results$standard_deviation <= res_no$results$standard_deviation
  )
})

test_that("EC_IPW_OPT works with a single outcome", {
  res <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = "y1",
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = TRUE
  )
  expect_identical(nrow(res$results), 1L)
  expect_gt(res$borrow_weight, 0)
})

test_that("EC_IPW_OPT bootstrap returns boot CIs", {
  res <- rdborrow:::EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = TRUE,
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc"
  )
  expect_named(res$results, c(
    "point_estimates", "standard_deviation",
    "lower_CI_boot", "upper_CI_boot"
  ))
  expect_all_true(res$results$lower_CI_boot < res$results$upper_CI_boot)
})
