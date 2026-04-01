# Regression tests for the OLE Analysis Workflow vignette.
# These lock in the exact numerical outputs produced by the current codebase
# on the built-in SyntheticData, so any code change that alters results is caught.
#
# All OLE methods require bootstrap for inference. Point estimates are
# deterministic (seed-independent); bootstrap CIs are tested with set.seed(42).
#
# Reference: vignettes/OLE_analysis_workflow.Rmd

# ---------- helpers shared across all test blocks ----------------------------
common_args_ole <- list(
  data                  = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name    = "A",
  outcome_col_name      = c("y1", "y2", "y3", "y4"),
  covariates_col_name   = c("x1", "x2", "x3", "x4", "x5"),
  T_cross               = 2
)

model_form_mu_ole <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)

bootstrap_obj_ole <- setup_bootstrap(replicates = 50, bootstrap_CI_type = "perc")

tol <- 1e-6

# =============================================================================
# Section 1.1  DID – IPW
# =============================================================================
test_that("OLE DID-IPW point estimates match vignette", {
  method_obj <- setup_method_DID(
    method_name    = "IPW",
    bootstrap_flag = TRUE,
    bootstrap_obj  = bootstrap_obj_ole,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5"
  )

  analysis_obj <- do.call(
    setup_analysis_OLE,
    c(common_args_ole, list(method_OLE_obj = method_obj))
  )

  set.seed(42)
  res <- run_analysis(analysis_obj)

  # Return structure
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)
  expect_true(all(c("point_estimates", "lower_CI_boot", "upper_CI_boot") %in% names(res)))

  # Point estimates (deterministic, seed-independent)
  expect_equal(res$point_estimates[1], 2.0759256334, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.3894380397, tolerance = tol)

  # Bootstrap CIs (seed=42, replicates=50)
  expect_equal(res$lower_CI_boot[1], -0.1985438132, tolerance = tol)
  expect_equal(res$lower_CI_boot[2],  1.7688904174, tolerance = tol)
  expect_equal(res$upper_CI_boot[1],  4.0048311338, tolerance = tol)
  expect_equal(res$upper_CI_boot[2],  8.2132873144, tolerance = tol)
})

# =============================================================================
# Section 1.2  DID – AIPW
# =============================================================================
test_that("OLE DID-AIPW point estimates match vignette", {
  method_obj <- setup_method_DID(
    method_name      = "AIPW",
    bootstrap_flag   = TRUE,
    bootstrap_obj    = bootstrap_obj_ole,
    model_form_piS   = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA   = "A ~ x1 + x2 + x3 + x4 + x5",
    model_form_mu0_ext = model_form_mu_ole
  )

  analysis_obj <- do.call(
    setup_analysis_OLE,
    c(common_args_ole, list(method_OLE_obj = method_obj))
  )

  set.seed(42)
  res <- run_analysis(analysis_obj)

  # Point estimates (deterministic)
  expect_equal(res$point_estimates[1], 2.0417274627, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.0361177594, tolerance = tol)

  # Bootstrap CIs (seed=42, replicates=50)
  expect_equal(res$lower_CI_boot[1], -0.2867417425, tolerance = tol)
  expect_equal(res$lower_CI_boot[2],  1.8145638636, tolerance = tol)
  expect_equal(res$upper_CI_boot[1],  4.0728301932, tolerance = tol)
  expect_equal(res$upper_CI_boot[2],  8.6316113430, tolerance = tol)
})

# =============================================================================
# Section 1.3  DID – OR (Outcome Regression)
# =============================================================================
test_that("OLE DID-OR point estimates match vignette", {
  method_obj <- setup_method_DID(
    method_name        = "OR",
    bootstrap_flag     = TRUE,
    bootstrap_obj      = bootstrap_obj_ole,
    model_form_mu0_ext = model_form_mu_ole,
    model_form_mu0_rct = model_form_mu_ole,
    model_form_mu1_rct = model_form_mu_ole
  )

  analysis_obj <- do.call(
    setup_analysis_OLE,
    c(common_args_ole, list(method_OLE_obj = method_obj))
  )

  set.seed(42)
  res <- run_analysis(analysis_obj)

  # Point estimates (deterministic)
  expect_equal(res$point_estimates[1], 1.5689465845, tolerance = tol)
  expect_equal(res$point_estimates[2], 4.4078336543, tolerance = tol)

  # Bootstrap CIs (seed=42, replicates=50)
  expect_equal(res$lower_CI_boot[1], -0.5122539446, tolerance = tol)
  expect_equal(res$lower_CI_boot[2],  2.7815366451, tolerance = tol)
  expect_equal(res$upper_CI_boot[1],  3.1261896871, tolerance = tol)
  expect_equal(res$upper_CI_boot[2],  7.9430452413, tolerance = tol)
})

# =============================================================================
# Section 2  SCM – Synthetic Control Method
# =============================================================================
test_that("OLE SCM point estimates match vignette", {
  skip_on_cran() # SCM cross-validation is computationally expensive (~3 min)

  bootstrap_obj_scm <- setup_bootstrap(replicates = 5, bootstrap_CI_type = "perc")

  method_obj <- setup_method_SCM(
    method_name    = "SCM",
    bootstrap_flag = TRUE,
    bootstrap_obj  = bootstrap_obj_scm,
    lambda.min     = 0,
    lambda.max     = 1e-3,
    nlambda        = 10,
    parallel       = "no",
    ncpus          = 1
  )

  analysis_obj <- do.call(
    setup_analysis_OLE,
    c(common_args_ole, list(method_OLE_obj = method_obj))
  )

  # few bootstrap replicates triggers "extreme order statistics" warnings ----
  set.seed(42)
  res <- suppressWarnings(run_analysis(analysis_obj))

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)

  # point estimates (deterministic, seed-independent) ----
  expect_equal(res$point_estimates[1], 2.1340818140, tolerance = tol)
  expect_equal(res$point_estimates[2], 3.9507833419, tolerance = tol)
})
