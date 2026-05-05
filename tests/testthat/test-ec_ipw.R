# -- return structure -----------------------------------------------------------

test_that("ec_ipw returns expected structure", {
  res <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = 0
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

# -- weight = 0: within-trial only (Hajek estimator) ---------------------------

test_that("ec_ipw with weight=0 uses only trial data", {
  res <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = 0
  )
  expect_identical(res$borrow_weight, 0)
  expect_all_true(is.finite(res$results$point_estimates))
  expect_all_true(res$results$standard_deviation > 0)
  expect_all_true(res$results$lower_CI_normal < res$results$upper_CI_normal)
})

# -- weight = "optimal" --------------------------------------------------------

test_that("ec_ipw with weight='optimal' borrows from external controls", {
  res <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = "optimal"
  )
  expect_gt(res$borrow_weight, 0)
  expect_lt(res$borrow_weight, 1)
  expect_all_true(is.finite(res$results$point_estimates))
  expect_all_true(res$results$standard_deviation > 0)
})

# -- fixed weight --------------------------------------------------------------

test_that("ec_ipw with fixed weight uses the specified weight", {
  res <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = 0.3
  )
  expect_equal(res$borrow_weight, 0.3)
})

# -- CIs contain point estimate ------------------------------------------------

test_that("ec_ipw normal CIs contain the point estimates", {
  res <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = "optimal"
  )
  expect_all_true(res$results$point_estimates >= res$results$lower_CI_normal)
  expect_all_true(res$results$point_estimates <= res$results$upper_CI_normal)
})

# -- borrowing should reduce SE ------------------------------------------------

test_that("ec_ipw optimal weight produces smaller or equal SE than weight=0", {
  res_no_borrow <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = 0
  )
  res_borrow <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = "optimal"
  )
  expect_all_true(
    res_borrow$results$standard_deviation <= res_no_borrow$results$standard_deviation
  )
})

# -- single time point ---------------------------------------------------------

test_that("ec_ipw works with a single outcome", {
  res <- ec_ipw(
    data = SyntheticData,
    outcomes = "y1",
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = "optimal"
  )
  expect_identical(nrow(res$results), 1L)
  expect_gt(res$borrow_weight, 0)
})

# -- matches EC_IPW_OPT output exactly -----------------------------------------

test_that("ec_ipw produces identical results to EC_IPW_OPT", {
  res_new <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = "optimal"
  )
  res_old <- suppressWarnings(EC_IPW_OPT(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    optimal_weight_flag = TRUE
  ))
  expect_identical(res_new$results$point_estimates, res_old$results$point_estimates)
  expect_identical(res_new$results$standard_deviation, res_old$results$standard_deviation)
  expect_identical(res_new$borrow_weight, res_old$borrow_weight)
})

# -- bootstrap inference -------------------------------------------------------

test_that("ec_ipw bootstrap returns boot CIs", {
  res <- ec_ipw(
    data = SyntheticData,
    outcomes = c("y1", "y2"),
    treatment = "A",
    trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"),
    ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
    weight = "optimal",
    bootstrap = setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")
  )
  expect_named(res$results, c(
    "point_estimates", "standard_deviation",
    "lower_CI_boot", "upper_CI_boot"
  ))
  expect_all_true(res$results$lower_CI_boot < res$results$upper_CI_boot)
})

# -- known treatment effect ----------------------------------------------------

test_that("ec_ipw estimates are close to truth with large n and no effect", {
  set.seed(42)
  n_rct <- 500
  n_ext <- 500
  X <- data.frame(x1 = rnorm(n_rct + n_ext))
  S <- c(rep(1, n_rct), rep(0, n_ext))
  A <- c(rbinom(n_rct, 1, 0.5), rep(0, n_ext))
  Y <- data.frame(y1 = rnorm(n_rct + n_ext))
  sim_data <- data.frame(X, S = S, A = A, Y)

  res <- ec_ipw(
    data = sim_data,
    outcomes = "y1",
    treatment = "A",
    trial_status = "S",
    covariates = "x1",
    ps_formula = "S ~ x1",
    weight = 0
  )
  expect_lt(abs(res$results$point_estimates), 0.5)
})
