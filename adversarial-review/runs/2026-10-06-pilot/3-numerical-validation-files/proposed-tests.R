source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
library(testthat)

# proposed for tests/testthat/test-ec_ipw.R ----
test_that("ec_ipw() matches a hand-computed fixture (Eq 6, Eq 11, Theorem 1 W00)", {
  d <- data.frame(
    S = c(1, 1, 1, 1, 1, 0, 0, 0),
    A = c(1, 1, 1, 0, 0, 0, 0, 0),
    x = c(0, 1, 1, 0, 1, 0, 0, 1),
    y1 = c(5, 7, 9, 2, 4, 1, 3, 6)
  )
  fit <- function(w) {
    estimate(ec_ipw("S ~ x", weight = w),
      data = d, outcomes = "y1", treatment = "A", trial_status = "S", covariates = "x"
    )
  }
  opt <- fit(NULL)
  expect_equal(opt$borrow_weight, 25 / 47, tolerance = 1e-8)
  expect_equal(opt$results$point_estimates, 4 - 1.4 * 25 / 47, tolerance = 1e-8)
  expect_equal(fit(0)$results$point_estimates, 4)
  expect_equal(fit(0.5)$results$point_estimates, 3.3, tolerance = 1e-8)
})

test_that("ec_ipw() and ec_aipw() accept a trial status column not named S", {
  d <- SyntheticData
  names(d)[names(d) == "S"] <- "trial"
  covs <- c("x1", "x2", "x3", "x4", "x5")
  ref <- estimate(ec_ipw("S ~ x1 + x2 + x3 + x4 + x5"),
    data = SyntheticData, outcomes = "y1", treatment = "A",
    trial_status = "S", covariates = covs
  )
  res <- estimate(ec_ipw("trial ~ x1 + x2 + x3 + x4 + x5"),
    data = d, outcomes = "y1", treatment = "A",
    trial_status = "trial", covariates = covs
  )
  expect_equal(res, ref)
  res_aipw <- estimate(ec_aipw("trial ~ x1 + x2 + x3 + x4 + x5", "y1 ~ x1 + x2"),
    data = d, outcomes = "y1", treatment = "A",
    trial_status = "trial", covariates = covs
  )
  expect_equal(nrow(res_aipw$results), 1L)
})

# proposed for tests/testthat/test-ec_aipw.R ----
test_that("ec_aipw() matches outcome formulas to outcomes by left-hand side", {
  covs <- c("x1", "x2", "x3", "x4", "x5")
  f <- c("y1 ~ x1 + x2", "y2 ~ x3 + x4 + x5")
  fit <- function(of) {
    estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", of),
      data = SyntheticData, outcomes = c("y1", "y2"), treatment = "A",
      trial_status = "S", covariates = covs
    )
  }
  expect_equal(fit(rev(f)), fit(f))
})

test_that("ec_aipw() sandwich uses the outcome-model basis fitted on controls", {
  covs <- c("x1", "x2", "x3", "x4", "x5")
  ctrl <- SyntheticData$A == 0
  basis <- splines::ns(SyntheticData$x5[ctrl], df = 3)
  d <- SyntheticData
  b <- predict(basis, d$x5)
  d$b1 <- b[, 1]
  d$b2 <- b[, 2]
  d$b3 <- b[, 3]
  fit <- function(of, data, cv) {
    estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", of, weight = 0.4),
      data = data, outcomes = "y1", treatment = "A",
      trial_status = "S", covariates = cv
    )$results
  }
  ns_fit <- fit("y1 ~ splines::ns(x5, df = 3)", SyntheticData, covs)
  explicit <- fit("y1 ~ b1 + b2 + b3", d, c(covs, "b1", "b2", "b3"))
  expect_equal(ns_fit$point_estimates, explicit$point_estimates, tolerance = 1e-10)
  expect_equal(ns_fit$standard_deviation, explicit$standard_deviation, tolerance = 1e-10)
})
