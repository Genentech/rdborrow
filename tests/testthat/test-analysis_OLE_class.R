test_that("setup_analysis_OLE returns valid object", {
  obj <- setup_analysis_OLE(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    method_OLE_obj = suppressWarnings(setup_method_DID(method_name = "IPW")),
    T_cross = 2
  )
  expect_s4_class(obj, "analysis_OLE_obj")
  expect_identical(obj@T_cross, 2)
  expect_identical(obj@method_obj@method_name, "IPW")
  expect_identical(obj@alpha, 0.05)
})

test_that("setup_analysis_OLE inherits base validation", {
  expect_error(setup_analysis_OLE(
    data = list(),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_OLE_obj = suppressWarnings(setup_method_DID()),
    T_cross = 2
  ))
  expect_error(setup_analysis_OLE(
    data = SyntheticData,
    trial_status_col_name = "not_a_col",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_OLE_obj = suppressWarnings(setup_method_DID()),
    T_cross = 2
  ))
})

test_that("setup_analysis_OLE validates method type", {
  expect_error(setup_analysis_OLE(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_OLE_obj = suppressWarnings(setup_method_weighting()),
    T_cross = 2
  ))
})

test_that("setup_analysis_OLE validates T_cross", {
  expect_error(setup_analysis_OLE(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_OLE_obj = suppressWarnings(setup_method_DID()),
    T_cross = -1
  ))
})

test_that("show method prints without error", {
  obj <- setup_analysis_OLE(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    method_OLE_obj = suppressWarnings(setup_method_DID(method_name = "IPW")),
    T_cross = 2
  )
  expect_output(show(obj), "analysis_OLE_obj")
  expect_output(show(obj), "T_cross: 2")
})
