# Regression tests for the Primary Analysis Workflow vignette.
# These lock in the exact numerical outputs produced by the current codebase
# on the built-in SyntheticData, so any code change that alters results is caught.
#
# Reference: vignettes/primary_analysis_workflow.Rmd

# ---------- helpers shared across all test blocks ----------------------------
common_args <- list(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name    = "A",
  outcome_col_name      = c("y1", "y2"),
  covariates_col_name   = c("x1", "x2", "x3", "x4", "x5")
)

tol <- 1e-6 # tolerance for floating-point comparison

# =============================================================================
# Section 2.1  IPW – zero weight (no borrowing)
# =============================================================================
test_that("Primary IPW zero-weight results match vignette", {
  method_obj <- setup_method_weighting(
    method_name        = "IPW",
    optimal_weight_flag = FALSE,
    wt                 = 0,
    model_form_piS     = "S ~ x1 + x2 + x3 + x4 + x5"
  )

  analysis_obj <- do.call(
    setup_analysis_primary,
    c(common_args, list(method_weighting_obj = method_obj))
  )

  res <- run_analysis(analysis_obj)

  # Return structure

  expect_type(res, "list")
  expect_named(res, c("results", "borrow_weight"))
  expect_s3_class(res$results, "data.frame")
  expect_equal(nrow(res$results), 2)

  # Point estimates (tau1, tau2)
  expect_equal(res$results$point_estimates[1], -0.0280870419, tolerance = tol)
  expect_equal(res$results$point_estimates[2],  0.4095955812, tolerance = tol)

  # Standard deviations
  expect_equal(res$results$standard_deviation[1], 0.5367986594, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5625763260, tolerance = tol)

  # Normal CIs
  expect_equal(res$results$lower_CI_normal[1], -1.0801930814, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[2], -0.6930337563, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[1],  1.0240189975, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[2],  1.5122249187, tolerance = tol)

  # Borrow weight
  expect_equal(res$borrow_weight, 0)
})

# =============================================================================
# Section 2.1  IPW – data-adaptive optimal weight
# =============================================================================
test_that("Primary IPW optimal-weight results match vignette", {
  method_obj <- setup_method_weighting(
    method_name        = "IPW",
    optimal_weight_flag = TRUE,
    model_form_piS     = "S ~ x1 + x2 + x3 + x4 + x5"
  )

  analysis_obj <- do.call(
    setup_analysis_primary,
    c(common_args, list(method_weighting_obj = method_obj))
  )

  res <- run_analysis(analysis_obj)

  # Point estimates
  expect_equal(res$results$point_estimates[1], -0.1971968926, tolerance = tol)
  expect_equal(res$results$point_estimates[2],  0.4697208867, tolerance = tol)

  # Standard deviations
  expect_equal(res$results$standard_deviation[1], 0.5134017502, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5410007056, tolerance = tol)

  # Normal CIs
  expect_equal(res$results$lower_CI_normal[1], -1.2034458325, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[2], -0.5906210120, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[1],  0.8090520473, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[2],  1.5300627854, tolerance = tol)

  # Borrow weight
  expect_equal(res$borrow_weight, 0.1475196487, tolerance = tol)
})

# =============================================================================
# Section 2.2  AIPW – zero weight (no borrowing)
# =============================================================================
test_that("Primary AIPW zero-weight results match vignette", {
  method_obj <- setup_method_weighting(
    method_name        = "AIPW",
    optimal_weight_flag = FALSE,
    wt                 = 0,
    model_form_piS     = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    )
  )

  analysis_obj <- do.call(
    setup_analysis_primary,
    c(common_args, list(method_weighting_obj = method_obj))
  )

  res <- run_analysis(analysis_obj)

  # Point estimates
  expect_equal(res$results$point_estimates[1], -0.4361151144, tolerance = tol)
  expect_equal(res$results$point_estimates[2],  0.4422248202, tolerance = tol)

  # Standard deviations
  expect_equal(res$results$standard_deviation[1], 0.5552064946, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5701633244, tolerance = tol)

  # Normal CIs
  expect_equal(res$results$lower_CI_normal[1], -1.5242998477, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[2], -0.6752747610, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[1],  0.6520696190, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[2],  1.5597244013, tolerance = tol)

  # Borrow weight
  expect_equal(res$borrow_weight, 0)
})

# =============================================================================
# Section 2.2  AIPW – data-adaptive optimal weight
# =============================================================================
test_that("Primary AIPW optimal-weight results match vignette", {
  method_obj <- setup_method_weighting(
    method_name        = "AIPW",
    optimal_weight_flag = TRUE,
    model_form_piS     = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    )
  )

  analysis_obj <- do.call(
    setup_analysis_primary,
    c(common_args, list(method_weighting_obj = method_obj))
  )

  res <- run_analysis(analysis_obj)

  # Point estimates
  expect_equal(res$results$point_estimates[1], -0.5463256250, tolerance = tol)
  expect_equal(res$results$point_estimates[2],  0.5401749583, tolerance = tol)

  # Standard deviations
  expect_equal(res$results$standard_deviation[1], 0.5305614087, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5543275065, tolerance = tol)

  # Normal CIs
  expect_equal(res$results$lower_CI_normal[1], -1.5862068777, tolerance = tol)
  expect_equal(res$results$lower_CI_normal[2], -0.5462869900, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[1],  0.4935556277, tolerance = tol)
  expect_equal(res$results$upper_CI_normal[2],  1.6266369066, tolerance = tol)

  # Borrow weight (same as IPW optimal since same propensity model)
  expect_equal(res$borrow_weight, 0.1475196487, tolerance = tol)
})

# =============================================================================
# Section 3  Bootstrap inference – point estimates remain identical
# =============================================================================
test_that("Primary IPW bootstrap point estimates match non-bootstrap", {
  bootstrap_obj <- setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")

  method_obj <- setup_method_weighting(
    method_name        = "IPW",
    optimal_weight_flag = TRUE,
    bootstrap_flag     = TRUE,
    bootstrap_obj      = bootstrap_obj,
    wt                 = 0,
    model_form_piS     = "S ~ x1 + x2 + x3 + x4 + x5"
  )

  analysis_obj <- do.call(
    setup_analysis_primary,
    c(common_args, list(method_weighting_obj = method_obj))
  )

  set.seed(42)
  res <- run_analysis(analysis_obj)

  # Point estimates must match the non-bootstrap run exactly
  expect_equal(res$results$point_estimates[1], -0.1971968926, tolerance = tol)
  expect_equal(res$results$point_estimates[2],  0.4697208867, tolerance = tol)

  # Standard deviations must match
  expect_equal(res$results$standard_deviation[1], 0.5134017502, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5410007056, tolerance = tol)

  # Borrow weight must match
  expect_equal(res$borrow_weight, 0.1475196487, tolerance = tol)

  # Bootstrap-specific columns exist
  expect_true("lower_CI_boot" %in% names(res$results))
  expect_true("upper_CI_boot" %in% names(res$results))
})

test_that("Primary AIPW bootstrap point estimates match non-bootstrap", {
  bootstrap_obj <- setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")

  method_obj <- setup_method_weighting(
    method_name        = "AIPW",
    optimal_weight_flag = TRUE,
    wt                 = 0,
    bootstrap_flag     = TRUE,
    bootstrap_obj      = bootstrap_obj,
    model_form_piS     = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = c(
      "y1 ~ x1 + x2 + x3 + x4 + x5",
      "y2 ~ x1 + x2 + x3 + x4 + x5"
    )
  )

  analysis_obj <- do.call(
    setup_analysis_primary,
    c(common_args, list(method_weighting_obj = method_obj))
  )

  set.seed(42)
  res <- run_analysis(analysis_obj)

  # Point estimates must match the non-bootstrap AIPW optimal run
  expect_equal(res$results$point_estimates[1], -0.5463256250, tolerance = tol)
  expect_equal(res$results$point_estimates[2],  0.5401749583, tolerance = tol)

  expect_equal(res$results$standard_deviation[1], 0.5305614087, tolerance = tol)
  expect_equal(res$results$standard_deviation[2], 0.5543275065, tolerance = tol)

  expect_equal(res$borrow_weight, 0.1475196487, tolerance = tol)
})
