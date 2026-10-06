f5 <- "S ~ x1 + x2 + x3 + x4 + x5"
o5 <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
covs <- c("x1", "x2", "x3", "x4", "x5")
run_pa <- function(method, data = SyntheticData, S = "S", A = "A",
                   outcomes = c("y1", "y2"), covariates = covs, alpha = 0.05) {
  run_analysis(setup_analysis_primary(
    data, S, A, outcomes, covariates, method,
    alpha = alpha
  ))
}

test_that("F4: a trial status column not named S works", {
  d <- SyntheticData
  names(d)[names(d) == "S"] <- "in_trial"
  expected <- run_pa(ec_ipw(f5))
  expect_equal(run_pa(ec_ipw(f5), data = d, S = "in_trial"), expected)
  expect_equal(
    run_pa(ec_ipw("in_trial ~ x1 + x2 + x3 + x4 + x5"), data = d, S = "in_trial"),
    expected
  )
  expect_equal(
    run_pa(ec_aipw(f5, o5), data = d, S = "in_trial"),
    run_pa(ec_aipw(f5, o5))
  )
})

test_that("F3: a covariate or outcome named A does not collide with treatment", {
  d <- SyntheticData
  names(d)[names(d) == "A"] <- "arm"
  ref <- run_pa(ec_ipw(f5), data = d, A = "arm")
  dc <- d
  names(dc)[names(dc) == "x4"] <- "A"
  expect_equal(
    run_pa(ec_ipw("S ~ x1 + x2 + x3 + A + x5"),
      data = dc, A = "arm",
      covariates = c("x1", "x2", "x3", "A", "x5")
    ),
    ref
  )
  db <- d
  db$ybin <- as.numeric(db$y1 > 0)
  db$A <- db$ybin
  expect_equal(
    run_pa(ec_ipw(f5), data = db, A = "arm", outcomes = "A")$results,
    run_pa(ec_ipw(f5), data = db, A = "arm", outcomes = "ybin")$results
  )
})

test_that("F1: outcome_formula order must match outcome_col_name", {
  expect_error(run_pa(ec_aipw(f5, rev(o5))), "outcome_formula")
  expect_error(run_pa(ec_aipw(f5, o5[c(1, 1)])), "outcome_formula")
})

test_that("F2: ps_formula may only use covariates_col_name", {
  expect_equal(run_pa(ec_ipw("S ~ .")), run_pa(ec_ipw(f5)))
  expect_error(run_pa(ec_ipw("S ~ x1 + A")), "covariates_col_name")
  expect_error(run_pa(ec_ipw("S ~ x1 + y1")), "covariates_col_name")
})

test_that("F5: optimal borrow_weight does not depend on outcomes (documented)", {
  d <- SyntheticData
  d$y1[d$S == 0] <- d$y1[d$S == 0] + 50
  expect_equal(
    run_pa(ec_ipw(f5), data = d)$borrow_weight,
    run_pa(ec_ipw(f5))$borrow_weight
  )
})

test_that("F6: missing values are rejected", {
  d <- SyntheticData
  d$y1[1] <- NA
  expect_error(
    setup_analysis_primary(d, "S", "A", c("y1", "y2"), covs, ec_ipw(f5)),
    "missing"
  )
  d <- SyntheticData
  d$x4[2] <- NA
  expect_error(
    setup_analysis_primary(d, "S", "A", c("y1", "y2"), covs, ec_ipw(f5)),
    "missing"
  )
})

test_that("F7: external controls must be untreated", {
  d <- SyntheticData
  d$A[which(d$S == 0)[1]] <- 1
  expect_error(
    setup_analysis_primary(d, "S", "A", c("y1", "y2"), covs, ec_ipw(f5)),
    "external"
  )
})

test_that("F8: bootstrap_ci_type without bootstrap is not silently ignored", {
  expect_error(ec_ipw(f5, bootstrap_ci_type = "bca"), "bootstrap")
  expect_error(ec_aipw(f5, o5, bootstrap_ci_type = "norm"), "bootstrap")
})

test_that("F9: alpha must lie strictly between 0 and 1", {
  expect_error(
    setup_analysis_primary(SyntheticData, "S", "A", "y1", covs, ec_ipw(f5), alpha = 0),
    "alpha"
  )
  expect_error(
    setup_analysis_primary(SyntheticData, "S", "A", "y1", covs, ec_ipw(f5), alpha = 1),
    "alpha"
  )
})

test_that("F10: outcome_formula rejects NA", {
  expect_error(ec_aipw(f5, NA_character_), "outcome_formula")
})

test_that("F11: setup_analysis_primary() returns visibly", {
  expect_visible(setup_analysis_primary(SyntheticData, "S", "A", "y1", covs, ec_ipw(f5)))
})
