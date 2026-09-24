test_that("ps_fit function reproduces the built-in propensity path", {
  set.seed(42)
  built_in <- run_analysis(ec_primary(ec_ipw(ec_ps, bootstrap = 100)))
  set.seed(42)
  supplied <- run_analysis(
    ec_primary(ec_ipw(ps_fit = att_weights, bootstrap = 100))
  )

  expect_equal(
    supplied$results$point_estimates,
    built_in$results$point_estimates
  )
  expect_equal(supplied$borrow_weight, built_in$borrow_weight)
})

test_that("ps_fit weights are scale invariant", {
  scaled <- function(d) att_weights(d) * 7

  set.seed(42)
  a <- run_analysis(ec_primary(ec_ipw(ps_fit = att_weights, bootstrap = 100)))
  set.seed(42)
  b <- run_analysis(ec_primary(ec_ipw(ps_fit = scaled, bootstrap = 100)))

  expect_equal(b$results$point_estimates, a$results$point_estimates)
})

test_that("ps_fit accepts a WeightIt-style object and refits per resample", {
  obj <- fake_weightit(S ~ x1 + x2 + x3 + x4 + x5, data = SyntheticData)
  ec_refit_count$n <- 0L

  # few replicates keep the refit count small; the CI is not under test here
  set.seed(42)
  res <- suppressWarnings(
    run_analysis(ec_primary(ec_ipw(ps_fit = obj, bootstrap = 20)))
  )

  # one point estimate, one boot t0, then one per replicate
  expect_identical(ec_refit_count$n, 22L)
  expect_all_true(is.finite(res$results$point_estimates))
})

test_that("ps_fit object with an unresolvable call gives an actionable error", {
  wrapper <- function(formula, data) fake_weightit(formula, data)
  obj <- wrapper(S ~ x1 + x2 + x3 + x4 + x5, data = SyntheticData)

  expect_error(
    run_analysis(ec_primary(ec_ipw(ps_fit = obj, bootstrap = 10))),
    "Pass a function of the data instead"
  )
})

test_that("ps_fit works for ec_aipw", {
  of <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")

  set.seed(42)
  built_in <- run_analysis(
    ec_primary(ec_aipw(ec_ps, outcome_formula = of, bootstrap = 100))
  )
  set.seed(42)
  supplied <- run_analysis(
    ec_primary(ec_aipw(
      outcome_formula = of, ps_fit = att_weights,
      bootstrap = 100
    ))
  )

  expect_equal(
    supplied$results$point_estimates,
    built_in$results$point_estimates
  )
})

test_that("ps_fit requires bootstrap inference", {
  expect_error(
    ec_ipw(ps_fit = att_weights),
    "requires bootstrap"
  )
})

test_that("ps_formula and ps_fit are mutually exclusive", {
  expect_error(ec_ipw(), "either ps_formula or ps_fit")
  expect_error(
    ec_ipw(ec_ps, ps_fit = att_weights, bootstrap = 50),
    "not both"
  )
})

test_that("ps_fit rejects objects it cannot use", {
  expect_error(ec_ipw(ps_fit = "S ~ x1", bootstrap = 50), "must be a function")
  expect_error(ec_ipw(ps_fit = 1:10, bootstrap = 50), "must be a function")
})

test_that("ps_fit validates the weights it produces", {
  wrong_length <- function(d) rep(1, 5)
  has_na <- function(d) {
    w <- att_weights(d)
    w[1] <- NA_real_
    w
  }
  negative <- function(d) att_weights(d) - 1
  zero_ext <- function(d) as.numeric(d$S)

  expect_error(
    run_analysis(ec_primary(ec_ipw(ps_fit = wrong_length, bootstrap = 10))),
    "one weight per subject"
  )
  expect_error(
    run_analysis(ec_primary(ec_ipw(ps_fit = has_na, bootstrap = 10))),
    "missing or non-finite"
  )
  expect_error(
    run_analysis(ec_primary(ec_ipw(ps_fit = negative, bootstrap = 10))),
    "negative weights"
  )
  expect_error(
    run_analysis(ec_primary(ec_ipw(ps_fit = zero_ext, bootstrap = 10))),
    "zero total weight"
  )
})
