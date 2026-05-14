tol <- 1e-6

test_that("EC-AIPW zero weight (no borrowing)", {
  method <- setup_method_weighting(
    method_name = "AIPW",
    optimal_weight_flag = FALSE,
    wt = 0,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
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
  res <- run_analysis(analysis)

  expect_equal(res$borrow_weight, 0)
  expect_equal(res$results$point_estimates[1], -0.4361151144, tolerance = tol)
  expect_equal(res$results$point_estimates[2], 0.4422248202, tolerance = tol)
  expect_equal(res$results$standard_deviation[1], 0.5552064946, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5701633244, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[1], -1.5242998477, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[2], -0.6752747610, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[1], 0.6520696190, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[2], 1.5597244013, tolerance = tol)
})

test_that("EC-AIPW optimal weight", {
  method <- setup_method_weighting(
    method_name = "AIPW",
    optimal_weight_flag = TRUE,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
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
  res <- run_analysis(analysis)

  expect_equal(res$borrow_weight, 0.1475196487, tolerance = tol)
  expect_equal(res$results$point_estimates[1], -0.5463256250, tolerance = tol)
  expect_equal(res$results$point_estimates[2], 0.5401749583, tolerance = tol)
  expect_equal(res$results$standard_deviation[1], 0.5305614087, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5543275065, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[1], -1.5862068777, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[2], -0.5462869900, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[1], 0.4935556277, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[2], 1.6266369066, tolerance = tol)
})

test_that("EC-AIPW fixed weight 0.3", {
  method <- setup_method_weighting(
    method_name = "AIPW",
    optimal_weight_flag = FALSE,
    wt = 0.3,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
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
  res <- run_analysis(analysis)

  expect_equal(res$borrow_weight, 0.3)
  expect_equal(res$results$point_estimates[1], -0.6602422289, tolerance = tol)
  expect_equal(res$results$point_estimates[2], 0.6414189052, tolerance = tol)
  expect_equal(res$results$standard_deviation[1], 0.5263737407, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5832105340, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[1], -1.6919158032, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[2], -0.5016527368, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[1], 0.3714313453, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[2], 1.7844905472, tolerance = tol)
})

test_that("EC-AIPW bootstrap preserves point estimates", {
  bootstrap_obj <- setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")
  method <- setup_method_weighting(
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
  analysis <- setup_analysis_primary(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = c("y1", "y2"),
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    method_weighting_obj = method
  )

  set.seed(42)
  res <- run_analysis(analysis)

  expect_equal(res$results$point_estimates[1], -0.5463256250, tolerance = tol)
  expect_equal(res$results$point_estimates[2], 0.5401749583, tolerance = tol)
  expect_equal(res$results$standard_deviation[1], 0.5305614087, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5543275065, tolerance = tol)
  expect_equal(res$borrow_weight, 0.1475196487, tolerance = tol)
  expect_named(
    res$results,
    c("point_estimates", "standard_deviation", "lower_CI_boot", "upper_CI_boot")
  )
})
