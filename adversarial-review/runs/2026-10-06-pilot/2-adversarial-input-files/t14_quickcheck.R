source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
suppressMessages(library(quickcheck))
library(testthat)
set.seed(20261006)

make_data <- function(seed, n_int, n_ext, frac_trt, shift) {
  set.seed(seed)
  X_int <- data.frame(x1 = rnorm(n_int), x2 = rbinom(n_int, 1, 0.5))
  X_ext <- data.frame(x1 = rnorm(n_ext, shift), x2 = rbinom(n_ext, 1, 0.4))
  specs <- list(
    list(effect = 1, model_form_x = c("1" = 2, "x1" = 0.5, "x2" = -0.3), noise_mean = 0, noise_sd = 1),
    list(effect = 0.5, model_form_x = c("1" = 1, "x1" = 0.2, "x2" = 0.1), noise_mean = 0, noise_sd = 1)
  )
  n_trt <- max(2, min(n_int - 2, round(frac_trt * n_int)))
  simulate_trial(X_int, X_ext, num_treated = n_trt, OLE_flag = FALSE, T_cross = 2, outcome_model_specs = specs)
}
run_m <- function(m, d) {
  r <- suppressWarnings(run_analysis(setup_analysis_primary(d, "S", "A", c("y1", "y2"), c("x1", "x2"), m)))
  r
}
gen <- list(
  seed = integer_bounded(1L, 1e6L, len = 1),
  n_int = integer_bounded(8L, 60L, len = 1),
  n_ext = integer_bounded(5L, 80L, len = 1),
  frac_trt = double_bounded(0.3, 0.8, len = 1),
  shift = double_bounded(-1, 1, len = 1),
  w = double_bounded(0, 1, len = 1)
)
methods_for <- function(w) list(
  ipw_opt = ec_ipw("S ~ x1 + x2"), ipw_w = ec_ipw("S ~ x1 + x2", weight = w),
  ipw_0 = ec_ipw("S ~ x1 + x2", weight = 0),
  aipw_opt = ec_aipw("S ~ x1 + x2", c("y1 ~ x1 + x2", "y2 ~ x1 + x2")),
  aipw_w = ec_aipw("S ~ x1 + x2", c("y1 ~ x1 + x2", "y2 ~ x1 + x2"), weight = w)
)
M <- function(r) as.matrix(r$results)
fails <- list()
prop <- function(name, f) {
  res <- tryCatch({
    do.call(for_all, c(gen, list(property = f, tests = 60L)))
    "held"
  }, error = function(e) paste("FAILED:", conditionMessage(e)))
  cat(sprintf("%-45s %s\n", name, substr(res, 1, 900)))
}
cat("names of simulated data:", names(make_data(1, 10, 10, 0.5, 0)), "\n")

prop("row permutation", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  p <- sample(nrow(d))
  for (m in methods_for(w)) expect_equal(M(run_m(m, d[p, ])), M(run_m(m, d)), tolerance = 1e-8)
})
prop("outcome shift +c: results unchanged", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  d2 <- d; d2$y1 <- d2$y1 + 37; d2$y2 <- d2$y2 - 11
  for (m in methods_for(w)) expect_equal(M(run_m(m, d2))[, 1:2], M(run_m(m, d))[, 1:2], tolerance = 1e-8)
})
prop("outcome scale c=-3: tau*c, SE*|c|", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  d2 <- d; d2$y1 <- -3 * d2$y1; d2$y2 <- -3 * d2$y2
  for (m in methods_for(w)) {
    a <- run_m(m, d2)$results; b <- run_m(m, d)$results
    expect_equal(a$point_estimates, -3 * b$point_estimates, tolerance = 1e-8)
    expect_equal(a$standard_deviation, 3 * b$standard_deviation, tolerance = 1e-8)
  }
})
prop("EC-IPW w=0 ignores external rows", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  m <- ec_ipw("S ~ x1 + x2", weight = 0)
  expect_equal(M(run_m(m, d[d$S == 1, ])), M(run_m(m, d)))
})
prop("duplicate all rows: tau same, SE/sqrt2", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  for (m in methods_for(w)) {
    a <- run_m(m, rbind(d, d)); b <- run_m(m, d)
    expect_equal(a$results$point_estimates, b$results$point_estimates, tolerance = 1e-8)
    expect_equal(a$results$standard_deviation * sqrt(2), b$results$standard_deviation, tolerance = 1e-8)
    expect_equal(a$borrow_weight, b$borrow_weight, tolerance = 1e-10)
  }
})
prop("tau affine in w (IPW, AIPW)", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  t <- function(m) run_m(m, d)$results$point_estimates
  o <- c("y1 ~ x1 + x2", "y2 ~ x1 + x2")
  expect_equal(t(ec_ipw("S ~ x1 + x2", weight = w)),
    (1 - w) * t(ec_ipw("S ~ x1 + x2", weight = 0)) + w * t(ec_ipw("S ~ x1 + x2", weight = 1)), tolerance = 1e-8)
  expect_equal(t(ec_aipw("S ~ x1 + x2", o, weight = w)),
    (1 - w) * t(ec_aipw("S ~ x1 + x2", o, weight = 0)) + w * t(ec_aipw("S ~ x1 + x2", o, weight = 1)), tolerance = 1e-8)
})
prop("borrow weight in [0,1], outcome-free", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  d2 <- d; d2$y1 <- rnorm(nrow(d)); d2$y2 <- rnorm(nrow(d))
  b1 <- run_m(ec_ipw("S ~ x1 + x2"), d)$borrow_weight
  b2 <- run_m(ec_aipw("S ~ x1 + x2", c("y1 ~ x1 + x2", "y2 ~ x1 + x2")), d2)$borrow_weight
  expect_gte(b1, 0); expect_lte(b1, 1); expect_equal(b1, b2)
})
prop("SE finite and positive", function(seed, n_int, n_ext, frac_trt, shift, w) {
  d <- make_data(seed, n_int, n_ext, frac_trt, shift)
  for (m in methods_for(w)) {
    s <- run_m(m, d)$results$standard_deviation
    expect_true(all(is.finite(s) & s > 0))
  }
})
