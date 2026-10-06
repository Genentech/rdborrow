# proposed regression tests; each should FAIL on 6185ba9 and pass once fixed.
# run: Rscript proposed_tests.R
.libPaths(c(
  "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib",
  .libPaths()
))
library(testthat)
suppressPackageStartupMessages(library(rdborrow))

outs <- c("y1", "y2", "y3", "y4")
covs <- c("x1", "x2", "x3", "x4", "x5")
ole <- function(data, method, T_cross = 2, outcomes = outs, covariates = covs,
                alpha = 0.05) {
  setup_analysis_OLE(
    data = data, trial_status_col_name = "S", treatment_col_name = "A",
    outcome_col_name = outcomes, covariates_col_name = covariates,
    method_OLE_obj = method, T_cross = T_cross, alpha = alpha
  )
}
pe <- function(analysis) {
  set.seed(1)
  suppressWarnings(run_analysis(analysis))$point_estimates
}

test_that("F1 a factor treatment column is rejected or matches 0/1 coding", {
  m <- did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5",
    trt_formula = "A ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2
  )
  d_f <- SyntheticData
  d_f$A <- factor(d_f$A, levels = c(1, 0))
  res <- tryCatch(pe(ole(d_f, m)), error = function(e) "error")
  if (!identical(res, "error")) expect_equal(res, pe(ole(SyntheticData, m)))
  else succeed()
})

test_that("F2 missing values in used columns are rejected by setup_analysis_OLE()", {
  d <- SyntheticData
  d$x1[d$S == 0][1] <- NA
  expect_error(ole(d, did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2)))
})

test_that("F2 .run_bootstrap() does not drop non-finite replicates silently", {
  d <- data.frame(S = rep(c(1, 0), each = 10), A = rep(c(1, 0, 0, 0), each = 5))
  stat <- function(data, i) if (1 %in% i) NA_real_ else mean(i)
  set.seed(1)
  expect_error(rdborrow:::.run_bootstrap(d, stat, 1, 50, "perc", 0.05))
})

test_that("F3-F4 scm() is unaffected by the units of a covariate", {
  d <- SyntheticData
  d_days <- d
  d_days$x4 <- d_days$x4 * 365
  m <- scm(lambda_min = 0.01, lambda_max = 0.01, nlambda = 1, bootstrap = 2)
  expect_equal(pe(ole(d_days, m)), pe(ole(d, m)), tolerance = 1e-4)
})

test_that("F6 non-syntactic outcome names work", {
  d <- SyntheticData
  names(d)[match(outs, names(d))] <- paste("week", c(26, 52, 78, 104))
  m <- did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2)
  expect_equal(
    unname(pe(ole(d, m, outcomes = paste("week", c(26, 52, 78, 104))))),
    unname(pe(ole(SyntheticData, m)))
  )
})

test_that("F7 setup_analysis_OLE() requires both trial arms and external controls", {
  m <- did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2)
  d <- SyntheticData
  d$A[d$S == 1] <- 1
  expect_error(ole(d, m), "control")
  expect_error(ole(SyntheticData[SyntheticData$S == 1, ], m), "external")
})

test_that("F8 scm() runs with two external controls", {
  set.seed(3)
  d <- SyntheticData[c(which(SyntheticData$S == 1)[1:40], which(SyntheticData$S == 0)[1:2]), ]
  m <- scm(lambda_min = 0, lambda_max = 0.1, nlambda = 2, bootstrap = 2)
  expect_no_error(suppressWarnings(run_analysis(ole(d, m))))
})

test_that("F5 estimate() validates T_cross", {
  expect_error(estimate(did_ec_or(paste0(outs, " ~ x1"), paste0(outs, " ~ x1"),
    paste0(outs, " ~ x1"), bootstrap = 2),
  data = SyntheticData, outcomes = outs, treatment = "A",
  trial_status = "S", covariates = covs, T_cross = 0
  ))
})

test_that("F9 alpha must lie strictly between 0 and 1", {
  m <- did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2)
  expect_error(ole(SyntheticData, m, alpha = 0))
  expect_error(ole(SyntheticData, m, alpha = 1))
})

test_that("#104 did_ec_or() matches formulas to outcomes by name", {
  f <- paste0(outs, " ~ x1 + x2 + x3 + x4 + x5")
  m1 <- did_ec_or(f, f, f, bootstrap = 2)
  m2 <- did_ec_or(rev(f), rev(f), rev(f), bootstrap = 2)
  expect_equal(pe(ole(SyntheticData, m2)), pe(ole(SyntheticData, m1)))
})
