test_that("setup_analysis returns valid object", {
  obj <- setup_analysis(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = c("y1", "y2"),
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    method_obj = setup_method(method_name = "AIPW")
  )
  expect_s4_class(obj, "analysis_obj")
  expect_identical(obj@trial_status_col_name, "S")
  expect_identical(obj@treatment_col_name, "A")
  expect_identical(obj@outcome_col_name, c("y1", "y2"))
  expect_identical(obj@covariates_col_name, c("x1", "x2", "x3", "x4", "x5"))
  expect_identical(obj@alpha, 0.05)
})

test_that("setup_analysis validates data", {
  expect_error(setup_analysis(
    data = list(),
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_obj = setup_method()
  ))
})

test_that("setup_analysis validates column names exist in data", {
  expect_error(setup_analysis(
    data = SyntheticData,
    trial_status_col_name = "not_a_col",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_obj = setup_method()
  ))
  expect_error(setup_analysis(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "not_a_col",
    covariates_col_name = "x1",
    method_obj = setup_method()
  ))
})

test_that("setup_analysis validates method_obj", {
  expect_error(setup_analysis(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_obj = list()
  ))
})

test_that("setup_analysis validates alpha", {
  expect_error(setup_analysis(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_obj = setup_method(),
    alpha = -0.1
  ))
  expect_error(setup_analysis(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = "y1",
    covariates_col_name = "x1",
    method_obj = setup_method(),
    alpha = 1.1
  ))
})

test_that("trial-status and treatment columns must be numeric or logical", {
  setup <- function(data) {
    setup_analysis_primary(
      data, "S", "A", c("y1", "y2"), c("x1", "x2"),
      ec_ipw("S ~ x1 + x2")
    )
  }
  as_factor <- function(col) {
    d <- SyntheticData
    d[[col]] <- factor(d[[col]], levels = c("1", "0"))
    d
  }
  as_logical <- SyntheticData
  as_logical$A <- as_logical$A == 1

  expect_error(setup(as_factor("A")), "A.*Must be of type .numeric.")
  expect_error(setup(as_factor("S")), "S.*Must be of type .numeric.")
  expect_error(
    setup_analysis_OLE(
      as_factor("A"), "S", "A", c("y1", "y2", "y3", "y4"), c("x1", "x2"),
      did_ec_ipw("S ~ x1", trt_formula = "A ~ x1", bootstrap = 2),
      T_cross = 2
    ),
    "A.*Must be of type .numeric."
  )
  expect_s4_class(setup(as_logical), "analysis_primary_obj")
})

test_that("estimate() also rejects a factor treatment column", {
  d <- SyntheticData
  d$A <- factor(d$A, levels = c("1", "0"))
  outs <- c("y1", "y2", "y3", "y4")
  call_estimate <- function(method, ...) {
    estimate(
      method,
      data = d, outcomes = outs, treatment = "A", trial_status = "S",
      covariates = c("x1", "x2"), ...
    )
  }
  expect_error(
    call_estimate(did_ec_ipw("S ~ x1", "A ~ x1 + x2", bootstrap = 2), T_cross = 2),
    "A.*Must be of type .numeric."
  )
  expect_error(
    call_estimate(
      did_ec_aipw("S ~ x1", "A ~ x1 + x2", paste(outs, "~ x1"), bootstrap = 2),
      T_cross = 2
    ),
    "A.*Must be of type .numeric."
  )
  expect_error(
    call_estimate(ec_ipw("S ~ x1")),
    "A.*Must be of type .numeric."
  )
})

test_that("show method prints without error", {
  obj <- setup_analysis(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = c("y1", "y2"),
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    method_obj = setup_method(method_name = "AIPW")
  )
  expect_output(show(obj), "analysis_obj")
  expect_output(show(obj), "300")
})
