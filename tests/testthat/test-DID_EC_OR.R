# -- return structure -----------------------------------------------------------

test_that("DID_EC_OR returns expected structure", {
  model_form_mu <- c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5",
    "y3 ~ x1 + x2 + x3 + x4 + x5",
    "y4 ~ x1 + x2 + x3 + x4 + x5"
  )
  res <- DID_EC_OR(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    model_form_mu0_ext = model_form_mu,
    model_form_mu0_rct = model_form_mu,
    model_form_mu1_rct = model_form_mu,
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc"
  )
  expect_s3_class(res, "data.frame")
  expect_identical(nrow(res), 2L)
})

# -- estimates are finite and CIs are valid ------------------------------------

test_that("DID_EC_OR produces finite estimates with valid CIs", {
  model_form_mu <- c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5",
    "y3 ~ x1 + x2 + x3 + x4 + x5",
    "y4 ~ x1 + x2 + x3 + x4 + x5"
  )
  res <- DID_EC_OR(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    model_form_mu0_ext = model_form_mu,
    model_form_mu0_rct = model_form_mu,
    model_form_mu1_rct = model_form_mu,
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc"
  )
  expect_all_true(is.finite(res$point_estimates))
  expect_all_true(res$lower_CI_boot < res$upper_CI_boot)
})

# -- OLE time points only ------------------------------------------------------

test_that("DID_EC_OR estimates effects for OLE period only", {
  model_form_mu <- c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5",
    "y3 ~ x1 + x2 + x3 + x4 + x5",
    "y4 ~ x1 + x2 + x3 + x4 + x5"
  )
  res <- DID_EC_OR(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    model_form_mu0_ext = model_form_mu,
    model_form_mu0_rct = model_form_mu,
    model_form_mu1_rct = model_form_mu,
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc"
  )
  expect_identical(rownames(res), c("tau3", "tau4"))
})
