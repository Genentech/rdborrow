source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")

test_that("ec_ipw()/ec_aipw() SEs equal an independent finite-difference sandwich", {
  covs <- c("x1", "x2", "x3", "x4", "x5")
  ys <- c("y1", "y2")
  X <- ind_design(SyntheticData, covs)
  for (aipw in c(FALSE, TRUE)) {
    for (w in list(NULL, 0, 0.3, 1)) {
      m <- if (aipw) {
        ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", paste(ys, "~ x1 + x2 + x3 + x4 + x5"), weight = w)
      } else {
        ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", weight = w)
      }
      r <- estimate(m, data = SyntheticData, outcomes = ys, treatment = "A",
        trial_status = "S", covariates = covs)
      f <- ind_ec(SyntheticData, ys, X, X, aipw = aipw, w = w)
      s <- ind_sandwich(f, SyntheticData, ys, X, X, aipw = aipw)
      expect_equal(r$results$point_estimates, unname(f$tau), tolerance = 1e-8)
      expect_equal(r$results$standard_deviation, unname(s$se_full), tolerance = 1e-6)
    }
  }
})

test_that("ec_ipw() optimal weight is Eq 11 (independent closed form)", {
  p <- fitted(glm(S ~ x1 + x2 + x3 + x4 + x5, binomial, SyntheticData))
  w00 <- (p / (1 - p))[SyntheticData$S == 0]
  ess <- sum(w00)^2 / sum(w00^2)
  n10 <- sum(SyntheticData$S == 1 & SyntheticData$A == 0)
  r <- estimate(ec_ipw("S ~ x1 + x2 + x3 + x4 + x5"), data = SyntheticData,
    outcomes = "y1", treatment = "A", trial_status = "S",
    covariates = c("x1", "x2", "x3", "x4", "x5"))
  expect_equal(r$borrow_weight, ess / (n10 + ess), tolerance = 1e-10)
})
