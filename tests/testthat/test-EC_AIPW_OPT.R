# -- return structure -----------------------------------------------------------

test_that("EC_AIPW_OPT returns expected structure", {
  res <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    ),
    optimal_weight_flag = FALSE,
    wt = 0
  )
  expect_type(res, "list")
  expect_named(res, c("results", "borrow_weight"))
  expect_s3_class(res$results, "data.frame")
  expect_identical(nrow(res$results), 2L)
})

# -- w = 0: within-trial only --------------------------------------------------

test_that("EC_AIPW_OPT with w=0 uses only trial data", {
  res <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    ),
    optimal_weight_flag = FALSE,
    wt = 0
  )
  expect_identical(res$borrow_weight, 0)
  expect_all_true(is.finite(res$results$point_estimates))
  expect_all_true(res$results$standard_deviation > 0)
})

# -- optimal weight ------------------------------------------------------------

test_that("EC_AIPW_OPT with optimal weight borrows from external controls", {
  res <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    ),
    optimal_weight_flag = TRUE
  )
  expect_gt(res$borrow_weight, 0)
  expect_lt(res$borrow_weight, 1)
  expect_all_true(is.finite(res$results$point_estimates))
})

# -- fixed weight --------------------------------------------------------------

test_that("EC_AIPW_OPT with fixed weight uses the specified weight", {
  res <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    ),
    optimal_weight_flag = FALSE,
    wt = 0.3
  )
  expect_equal(res$borrow_weight, 0.3)
})

# -- CIs contain point estimate ------------------------------------------------

test_that("EC_AIPW_OPT normal CIs contain the point estimates", {
  res <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    ),
    optimal_weight_flag = TRUE
  )
  expect_all_true(res$results$point_estimates >= res$results$lower_CI_normal)
  expect_all_true(res$results$point_estimates <= res$results$upper_CI_normal)
})

# -- AIPW borrowing should reduce SE vs no borrowing ---------------------------

test_that("EC_AIPW_OPT optimal weight produces smaller SE than w=0", {
  res_no_borrow <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    ),
    optimal_weight_flag = FALSE,
    wt = 0
  )
  res_borrow <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    ),
    optimal_weight_flag = TRUE
  )
  expect_all_true(
    res_borrow$results$standard_deviation <= res_no_borrow$results$standard_deviation
  )
})

# -- single time point ---------------------------------------------------------

test_that("EC_AIPW_OPT works with a single outcome", {
  res <- EC_AIPW_OPT(
    data = SyntheticData,
    outcome_col_name = "y1",
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = "y1 ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = TRUE
  )
  expect_identical(nrow(res$results), 1L)
})
