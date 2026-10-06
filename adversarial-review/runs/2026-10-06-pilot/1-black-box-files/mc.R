source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
# DGP written before looking at results:
# trial n = 150 (100 treated, 50 control), external m = 100.
# X_int ~ N(0, 1) x2; X_ext ~ N(0.5, 1) x2 -> log density ratio linear, so
# logistic PS "S ~ x1 + x2" is correctly specified. Outcomes linear in X with
# same model in trial and external (Assumptions 1, 4 hold; B = 0).
# true effects: 1 at t1, 0.5 at t2. Expected: 95% normal CIs cover ~0.95
# (MCSE ~ 0.007 at 1000 reps) and mean sandwich SE ~ empirical SD.
set.seed(20261006)
R <- 1000
specs <- list(
  list(effect = 1, model_form_x = c("1" = 0, "x1" = 1, "x2" = -0.5), noise_mean = 0, noise_sd = 1),
  list(effect = 0.5, model_form_x = c("1" = 0, "x1" = 0.8, "x2" = 0.3), noise_mean = 0, noise_sd = 1)
)
truth <- c(1, 0.5)
cfgs <- list(
  ipw_opt = ec_ipw("S ~ x1 + x2"),
  ipw_w1 = ec_ipw("S ~ x1 + x2", weight = 1),
  aipw_opt = ec_aipw("S ~ x1 + x2", c("y1 ~ x1 + x2", "y2 ~ x1 + x2")),
  aipw_w1 = ec_aipw("S ~ x1 + x2", c("y1 ~ x1 + x2", "y2 ~ x1 + x2"), weight = 1)
)
out <- lapply(names(cfgs), \(n) matrix(NA, R, 6))
names(out) <- names(cfgs)
for (r in seq_len(R)) {
  X_int <- data.frame(x1 = rnorm(150), x2 = rnorm(150))
  X_ext <- data.frame(x1 = rnorm(100, 0.5), x2 = rnorm(100, 0.5))
  dat <- simulate_trial(X_int, X_ext, num_treated = 100, OLE_flag = FALSE, T_cross = 2, outcome_model_specs = specs)
  if (r == 1) { print(head(dat)); print(table(dat$S, dat$A)) }
  for (n in names(cfgs)) {
    res <- run_analysis(mk(cfgs[[n]], data = dat, covs = c("x1", "x2")))$results
    out[[n]][r, ] <- c(res$point_estimates, res$standard_deviation,
      as.numeric(res$lower_CI_normal <= truth & truth <= res$upper_CI_normal))
  }
}
for (n in names(out)) {
  o <- out[[n]]
  cov <- colMeans(o[, 5:6])
  cat(sprintf("%-9s bias t1 %+.4f (MCSE %.4f) t2 %+.4f | emp SD %.4f %.4f | mean SE %.4f %.4f | coverage %.3f %.3f (MCSE %.3f)\n",
    n, mean(o[, 1]) - 1, sd(o[, 1]) / sqrt(R), mean(o[, 2]) - 0.5, sd(o[, 1]), sd(o[, 2]),
    mean(o[, 3]), mean(o[, 4]), cov[1], cov[2], sqrt(0.95 * 0.05 / R)))
}
