covs <- c("x1", "x2", "x3", "x4", "x5")
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
of <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")

test_that("P1 ec_ipw(weight = 0) SE matches the closed-form Hajek variance", {
  d <- unbalanced_data()
  res <- run_primary(d, ec_ipw(ps, weight = 0))$results
  trt <- d[d$S == 1 & d$A == 1, c("y1", "y2")]
  ctl <- d[d$S == 1 & d$A == 0, c("y1", "y2")]
  ml_var <- function(y) colMeans(sweep(y, 2, colMeans(y))^2)
  expected <- sqrt(ml_var(trt) / nrow(trt) + ml_var(ctl) / nrow(ctl))
  expect_equal(res$standard_deviation, unname(expected), tolerance = 1e-8)
})

test_that("P2 optimal weight matches Eq 11 on unbalanced arms", {
  d <- unbalanced_data()
  expected <- independent_opt_weight(d, covs)
  expect_equal(run_primary(d, ec_ipw(ps))$borrow_weight, expected, tolerance = 1e-8)
  expect_equal(
    run_primary(d, ec_aipw(ps, of))$borrow_weight, expected,
    tolerance = 1e-8
  )
})

test_that("P3 ec_ipw() sandwich SE matches an independent M-estimator", {
  d <- unbalanced_data()
  for (w in list(NULL, 0.3, 1)) {
    res <- run_primary(d, ec_ipw(ps, weight = w))
    ref <- independent_ec(d, c("y1", "y2"), covs, res$borrow_weight)
    expect_lt(ref$max_ee, 1e-8)
    expect_equal(res$results$point_estimates, ref$tau, tolerance = 1e-8)
    expect_equal(res$results$standard_deviation, ref$sd, tolerance = 1e-6)
  }
})

test_that("P4 ec_aipw() sandwich SE matches an independent M-estimator", {
  d <- unbalanced_data()
  for (w in list(NULL, 0, 0.3, 1)) {
    res <- run_primary(d, ec_aipw(ps, of, weight = w))
    ref <- independent_ec(d, c("y1", "y2"), covs, res$borrow_weight, augment = TRUE)
    expect_lt(ref$max_ee, 1e-8)
    expect_equal(res$results$point_estimates, ref$tau, tolerance = 1e-8)
    expect_equal(res$results$standard_deviation, ref$sd, tolerance = 1e-6)
  }
})

test_that("P5 normal CIs use alpha for both methods", {
  for (method in list(ec_ipw(ps), ec_aipw(ps, of))) {
    res <- run_primary(SyntheticData, method, alpha = 0.2)$results
    expect_equal(
      res$upper_CI_normal - res$point_estimates,
      qnorm(0.9) * res$standard_deviation
    )
    expect_equal(
      res$point_estimates - res$lower_CI_normal,
      qnorm(0.9) * res$standard_deviation
    )
  }
})

test_that("P6 bootstrap CIs use alpha", {
  for (method in list(ec_ipw(ps, bootstrap = 50), ec_aipw(ps, of, bootstrap = 50))) {
    set.seed(1)
    wide <- run_primary(SyntheticData, method, alpha = 0.05)$results
    set.seed(1)
    narrow <- run_primary(SyntheticData, method, alpha = 0.5)$results
    expect_all_true(narrow$lower_CI_boot > wide$lower_CI_boot)
    expect_all_true(narrow$upper_CI_boot < wide$upper_CI_boot)
  }
})

test_that("P7 basic and norm bootstrap CIs have their defining relations", {
  boot_ci <- function(type) {
    set.seed(7)
    run_primary(
      SyntheticData,
      ec_ipw(ps, bootstrap = 50, bootstrap_ci_type = type)
    )$results
  }
  perc <- boot_ci("perc")
  basic <- boot_ci("basic")
  norm <- boot_ci("norm")
  tau <- perc$point_estimates
  expect_equal(basic$lower_CI_boot, 2 * tau - perc$upper_CI_boot)
  expect_equal(basic$upper_CI_boot, 2 * tau - perc$lower_CI_boot)
  expect_equal(
    norm$upper_CI_boot - norm$lower_CI_boot,
    2 * qnorm(0.975) * norm$standard_deviation
  )
})

test_that("P17 .run_bootstrap() norm CI is the bias-corrected normal interval", {
  d <- SyntheticData
  stat <- function(data, indices) mean(data$y1[indices])
  set.seed(11)
  out <- .run_bootstrap(d, stat,
    n_estimates = 1, bootstrap = 200,
    bootstrap_ci_type = "norm", alpha = 0.1
  )
  set.seed(11)
  b <- boot::boot(d, stat, R = 200, strata = as.integer(interaction(d$S, d$A)))
  centre <- 2 * b$t0 - mean(b$t)
  half <- qnorm(0.95) * sd(b$t)
  expect_equal(c(out$lower_ci, out$upper_ci), centre + c(-half, half))
  expect_equal(out$sd_boot, sd(b$t))
})

test_that("P8 .run_bootstrap() keeps the S x A group sizes in every replicate", {
  d <- SyntheticData
  stat <- function(data, indices) {
    c(mean(data$y1[indices]), sum(data$S[indices]), sum(data$A[indices]))
  }
  set.seed(3)
  out <- .run_bootstrap(d, stat,
    n_estimates = 1, bootstrap = 30,
    bootstrap_ci_type = "perc", alpha = 0.05
  )
  expect_equal(out$sd_boot[2:3], c(0, 0))
})

test_that("P9 results do not depend on the trial-status and treatment column names", {
  d <- SyntheticData
  d2 <- d
  names(d2)[names(d2) == "S"] <- "trial"
  names(d2)[names(d2) == "A"] <- "trt"
  for (method in list(ec_ipw(ps), ec_aipw(ps, of))) {
    expect_equal(
      run_primary(d2, method, trial = "trial", trt = "trt"),
      run_primary(d, method)
    )
  }
})

test_that("P10 ec_ipw(weight = 0) never touches external outcomes", {
  d <- SyntheticData
  d_na <- d
  d_na[d_na$S == 0, c("y1", "y2")] <- NA
  expect_equal(
    run_primary(d_na, ec_ipw(ps, weight = 0)),
    run_primary(d, ec_ipw(ps, weight = 0))
  )
})

test_that("P11 a single outcome reproduces the first row of a two-outcome fit", {
  methods <- list(
    list(ec_ipw(ps, weight = 0), ec_ipw(ps, weight = 0)),
    list(ec_aipw(ps, of[1]), ec_aipw(ps, of))
  )
  for (m in methods) {
    one <- run_primary(SyntheticData, m[[1]], outcomes = "y1")
    two <- run_primary(SyntheticData, m[[2]])
    expect_equal(one$results, two$results[1, ])
  }
})

test_that("P12 unused covariate columns do not change the fit", {
  fit <- function(cv) {
    run_analysis(setup_analysis_primary(
      data = SyntheticData,
      trial_status_col_name = "S",
      treatment_col_name = "A",
      outcome_col_name = c("y1", "y2"),
      covariates_col_name = cv,
      method_weighting_obj = ec_ipw("S ~ x1")
    ))
  }
  expect_equal(fit("x1"), fit(c("x1", "x2")))
})

test_that("P14 bootstrap_ci_type resolves to perc only when bootstrap is set", {
  expect_identical(ec_aipw(ps, of, bootstrap = 50)@bootstrap_ci_type, "perc")
  expect_null(ec_aipw(ps, of)@bootstrap_ci_type)
  expect_identical(ec_ipw(ps, bootstrap = 50)@bootstrap_ci_type, "perc")
  expect_null(ec_ipw(ps)@bootstrap_ci_type)
  expect_identical(ec_aipw(ps, of)@method_name, "EC-AIPW")
  expect_identical(ec_ipw(ps)@method_name, "EC-IPW")
})

test_that("P15 ec_aipw() validates outcome_formula and bootstrap_ci_type", {
  expect_error(ec_aipw(ps, character(0)))
  expect_error(ec_aipw(ps, of, bootstrap = 50, bootstrap_ci_type = "stud"))
  for (type in c("perc", "bca", "norm", "basic")) {
    expect_s4_class(
      ec_aipw(ps, of, bootstrap = 50, bootstrap_ci_type = type),
      "ec_aipw_method"
    )
  }
})

test_that("P16 quiet controls progress messages for both methods", {
  for (method in list(ec_ipw(ps, bootstrap = 50), ec_aipw(ps, of, bootstrap = 50))) {
    analysis <- setup_analysis_primary(
      data = SyntheticData,
      trial_status_col_name = "S",
      treatment_col_name = "A",
      outcome_col_name = c("y1", "y2"),
      covariates_col_name = covs,
      method_weighting_obj = method
    )
    expect_silent(run_analysis(analysis))
    out <- capture.output(res <- run_analysis(analysis, quiet = FALSE))
    expect_identical(
      out,
      c(
        paste0("Running ", method@method_name, " estimator..."),
        "Running bootstrap inference..."
      )
    )
  }
})

test_that("P13 result rows are named tau1..tauT for every inference path", {
  methods <- list(
    ec_ipw(ps), ec_ipw(ps, bootstrap = 2),
    ec_aipw(ps, of), ec_aipw(ps, of, bootstrap = 2)
  )
  for (method in methods) {
    set.seed(1)
    expect_identical(
      rownames(run_primary(SyntheticData, method)$results),
      c("tau1", "tau2")
    )
  }
})
