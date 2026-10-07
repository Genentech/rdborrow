test_that("setup_method returns default object", {
  obj <- setup_method()
  expect_s4_class(obj, "method_obj")
  expect_identical(obj@method_name, "")
})

test_that("setup_method accepts valid arguments", {
  obj <- setup_method(method_name = "AIPW")
  expect_identical(obj@method_name, "AIPW")
})

test_that("setup_method validates method_name", {
  expect_error(setup_method(method_name = 123))
  expect_error(setup_method(method_name = NA))
  expect_error(setup_method(method_name = c("a", "b")))
})

test_that("all bootstrap CI types return finite bounds", {
  covs <- c("x1", "x2", "x3", "x4", "x5")
  ps <- "S ~ x1 + x2 + x3 + x4 + x5"

  for (ci_type in c("perc", "norm", "basic", "bca")) {
    method <- ec_ipw(ps, bootstrap = 100, bootstrap_ci_type = ci_type)
    analysis <- setup_analysis_primary(
      data = SyntheticData,
      trial_status_col_name = "S",
      treatment_col_name = "A",
      outcome_col_name = c("y1", "y2"),
      covariates_col_name = covs,
      method_weighting_obj = method
    )

    set.seed(42)
    res <- run_analysis(analysis)$results

    expect_all_true(is.finite(res$lower_CI_boot))
    expect_all_true(is.finite(res$upper_CI_boot))
    expect_all_true(res$lower_CI_boot < res$upper_CI_boot)
  }
})

test_that("constructors reject fewer than two bootstrap replicates", {
  f <- "y1 ~ x1"
  constructors <- list(
    \(b) ec_ipw("S ~ x1", bootstrap = b),
    \(b) ec_aipw("S ~ x1", outcome_formula = f, bootstrap = b),
    \(b) did_ec_ipw("S ~ x1", bootstrap = b),
    \(b) did_ec_aipw("S ~ x1", outcome_formula = f, bootstrap = b),
    \(b) did_ec_or(f, f, f, bootstrap = b),
    \(b) scm(bootstrap = b)
  )

  for (make in constructors) {
    expect_error(make(1), "bootstrap")
    expect_s4_class(make(2), "method_obj")
  }
})

test_that("bootstrap_ci_type rejects studentized intervals", {
  expect_error(
    ec_ipw("S ~ x1", bootstrap = 100, bootstrap_ci_type = "stud")
  )
})

test_that("bootstrap_ci_type without bootstrap is an error", {
  expect_error(
    ec_ipw("S ~ x1", bootstrap_ci_type = "bca"),
    "bootstrap_ci_type.*needs.*bootstrap"
  )
  expect_error(
    ec_aipw("S ~ x1", "y1 ~ x1", bootstrap_ci_type = "norm"),
    "bootstrap_ci_type.*needs.*bootstrap"
  )
  expect_null(ec_ipw("S ~ x1")@bootstrap_ci_type)
  expect_identical(ec_ipw("S ~ x1", bootstrap = 2)@bootstrap_ci_type, "perc")
})

test_that(".match_outcome_formulas orders formulas by their left-hand side", {
  outs <- c("y1", "y2", "y3")
  f <- c("y3 ~ x1", "y1 ~ x1", "y2 ~ x2")
  expect_identical(
    .match_outcome_formulas(f, outs, "outcome_formula"),
    c("y1 ~ x1", "y2 ~ x2", "y3 ~ x1")
  )
  expect_identical(
    .match_outcome_formulas("`week 12` ~ x1", "week 12", "f"),
    "`week 12` ~ x1"
  )
  expect_error(
    .match_outcome_formulas(c("y1 ~ x1", "z ~ x1", "y3 ~ x1"), outs, "f"),
    "f.*z"
  )
  expect_error(
    .match_outcome_formulas(c("y1 ~ x1", "y1 ~ x2", "y3 ~ x1"), outs, "f"),
    "f.*y1"
  )
  expect_error(
    .match_outcome_formulas(c("y1 ~ x1", "y2 ~ x1"), outs, "f"),
    "f.*y3"
  )
})

test_that(".match_outcome_formulas rejects transformed and missing outcomes", {
  outs <- c("y1", "y2")
  expect_error(
    .match_outcome_formulas(c("y1 ~ x1", "log(y2) ~ x1"), outs, "f"),
    "f.*outcome name.*log\\(y2\\)"
  )
  expect_error(
    .match_outcome_formulas(c("I(2 * y1) ~ x1", "y2 ~ x1"), outs, "f"),
    "outcome name"
  )
  expect_error(
    .match_outcome_formulas(c("~ x1", "y2 ~ x1"), outs, "f"),
    "f.*left-hand side"
  )
  expect_error(
    .match_outcome_formulas(c("~ y1", "y2 ~ x1"), outs, "f"),
    "f.*left-hand side"
  )
})
