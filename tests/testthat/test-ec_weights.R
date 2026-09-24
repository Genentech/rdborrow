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

test_that("ps_fit accepts a real WeightIt object, however the call was written", {
  skip_if_not_installed("WeightIt")

  set.seed(42)
  built_in <- run_analysis(ec_primary(ec_ipw(ec_ps, bootstrap = 100)))

  # bare call, as written after library(WeightIt)
  bare <- suppressWarnings(WeightIt::weightit(
    S ~ x1 + x2 + x3 + x4 + x5,
    data = SyntheticData, method = "glm", estimand = "ATT", focal = "1"
  ))
  set.seed(42)
  from_object <- suppressWarnings(
    run_analysis(ec_primary(ec_ipw(ps_fit = bare, bootstrap = 100)))
  )

  # ATT weights are the density ratio the estimator already uses, so the
  # point estimate must match the internal propensity path
  expect_equal(
    from_object$results$point_estimates,
    built_in$results$point_estimates
  )
})

test_that("WeightIt ATT weights equal the internal density ratio", {
  skip_if_not_installed("WeightIt")

  model <- glm(
    S ~ x1 + x2 + x3 + x4 + x5,
    data = SyntheticData, family = "binomial"
  )
  p <- unname(predict(model, newdata = SyntheticData, type = "response"))
  odds <- p / (1 - p)

  w <- unname(suppressWarnings(WeightIt::weightit(
    S ~ x1 + x2 + x3 + x4 + x5,
    data = SyntheticData, method = "glm", estimand = "ATT", focal = "1"
  ))$weights)

  external <- SyntheticData$S == 0
  expect_equal(w[external], odds[external])
  expect_all_equal(w[!external], 1)
})

test_that("ps_fit accepts a real MatchIt object", {
  skip_if_not_installed("MatchIt")

  m <- MatchIt::matchit(
    S ~ x1 + x2 + x3 + x4 + x5,
    data = SyntheticData, method = "subclass", estimand = "ATT"
  )

  set.seed(42)
  res <- suppressWarnings(
    run_analysis(ec_primary(ec_ipw(ps_fit = m, bootstrap = 50)))
  )

  expect_all_true(is.finite(res$results$point_estimates))
  expect_all_true(is.finite(res$results$lower_CI_boot))
})

test_that("ps_fit works for the DID methods", {
  skip_if_not_installed("WeightIt")

  covs <- c("x1", "x2", "x3", "x4", "x5")
  outcomes <- c("y1", "y2", "y3", "y4")
  trt <- "A ~ x1 + x2 + x3 + x4 + x5"
  of <- paste0(outcomes, " ~ x1 + x2 + x3 + x4 + x5")

  ole <- function(method) {
    setup_analysis_OLE(
      data = SyntheticData,
      trial_status_col_name = "S",
      treatment_col_name = "A",
      outcome_col_name = outcomes,
      covariates_col_name = covs,
      T_cross = 2,
      method_OLE_obj = method
    )
  }

  w <- suppressWarnings(WeightIt::weightit(
    S ~ x1 + x2 + x3 + x4 + x5,
    data = SyntheticData, method = "glm", estimand = "ATT", focal = "1"
  ))

  set.seed(42)
  ipw_formula <- run_analysis(
    ole(did_ec_ipw(ec_ps, trt_formula = trt, bootstrap = 50))
  )
  set.seed(42)
  ipw_supplied <- run_analysis(
    ole(did_ec_ipw(ps_fit = w, trt_formula = trt, bootstrap = 50))
  )
  expect_equal(ipw_supplied$point_estimates, ipw_formula$point_estimates)

  set.seed(42)
  aipw_formula <- run_analysis(
    ole(did_ec_aipw(ec_ps,
      trt_formula = trt, outcome_formula = of,
      bootstrap = 50
    ))
  )
  set.seed(42)
  aipw_supplied <- run_analysis(
    ole(did_ec_aipw(
      ps_fit = w, trt_formula = trt, outcome_formula = of,
      bootstrap = 50
    ))
  )
  expect_equal(aipw_supplied$point_estimates, aipw_formula$point_estimates)
})

test_that("DID constructors reject ps_formula and ps_fit together", {
  expect_error(did_ec_ipw(ec_ps, ps_fit = att_weights), "not both")
  expect_error(
    did_ec_aipw(ec_ps, ps_fit = att_weights, outcome_formula = "y1 ~ x1"),
    "not both"
  )
})
