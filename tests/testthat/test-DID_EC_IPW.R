test_that("DID_EC_IPW returns expected structure", {
  res <- rdborrow:::DID_EC_IPW(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5",
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc"
  )
  expect_s3_class(res, "data.frame")
  expect_identical(nrow(res), 2L)
  expect_named(res, c("point_estimates", "lower_CI_boot", "upper_CI_boot"))
})

test_that("DID_EC_IPW produces finite estimates with valid CIs", {
  res <- rdborrow:::DID_EC_IPW(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5",
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc"
  )
  expect_all_true(is.finite(res$point_estimates))
  expect_all_true(res$lower_CI_boot < res$upper_CI_boot)
})

test_that("DID_EC_IPW estimates effects for OLE period only", {
  res <- rdborrow:::DID_EC_IPW(
    data = SyntheticData,
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
    model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5",
    Bootstrap = TRUE,
    R = 50,
    bootstrap_CI_type = "perc"
  )
  expect_identical(rownames(res), c("tau3", "tau4"))
})
