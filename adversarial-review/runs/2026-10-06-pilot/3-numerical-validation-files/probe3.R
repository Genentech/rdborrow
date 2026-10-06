source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
d <- SyntheticData
covs <- c("x1", "x2", "x3", "x4", "x5")
ys <- c("y1", "y2", "y3", "y4")
Xps <- ind_design(d, covs)

cat("== Eq 11 weight vs sandwich-variance-minimizing weight (SyntheticData) ==\n")
grid <- seq(0, 1, by = 0.01)
for (aipw in c(FALSE, TRUE)) {
  se <- t(vapply(grid, \(w) {
    f <- ind_ec(d, ys, Xps, Xps, aipw = aipw, w = w)
    ind_sandwich(f, d, ys, Xps, Xps, aipw = aipw)$se_full
  }, numeric(4)))
  wopt <- ind_ec(d, ys, Xps, Xps, aipw = aipw)$w
  f_opt <- ind_ec(d, ys, Xps, Xps, aipw = aipw)
  se_opt <- ind_sandwich(f_opt, d, ys, Xps, Xps, aipw = aipw)$se_full
  cat(sprintf(
    "%s: Eq 11 w-hat = %.3f; argmin_w SE per outcome = %s; SE at w-hat / min SE = %s\n",
    if (aipw) "EC-AIPW" else "EC-IPW", wopt,
    paste(grid[apply(se, 2, which.min)], collapse = ", "),
    paste(sprintf("%.3f", se_opt / apply(se, 2, min)), collapse = ", ")
  ))
}

cat("\n== bootstrap: package vs boot::boot with independent statistic, same seed ==\n")
for (aipw in c(FALSE, TRUE)) {
  for (ci in c("perc", "basic", "norm")) {
    m <- if (aipw) {
      ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", paste0(ys[1:2], " ~ x1 + x2 + x3 + x4 + x5"), bootstrap = 99L, bootstrap_ci_type = ci)
    } else {
      ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 99L, bootstrap_ci_type = ci)
    }
    set.seed(42)
    r <- estimate(m, data = d, outcomes = ys[1:2], treatment = "A", trial_status = "S", covariates = covs)
    w_hat <- r$borrow_weight
    stat <- function(dd, i) {
      x <- dd[i, ]
      ind_ec(x, ys[1:2], ind_design(x, covs), ind_design(x, covs), aipw = aipw, w = w_hat)$tau
    }
    set.seed(42)
    b <- boot::boot(d, stat, R = 99, strata = 2 * d$S + d$A)
    lims <- t(vapply(1:2, \(k) {
      x <- boot::boot.ci(b, type = ci, index = k)
      v <- x[[switch(ci, perc = "percent", basic = "basic", norm = "normal")]]
      if (ci == "norm") v[2:3] else v[4:5]
    }, numeric(2)))
    cat(sprintf(
      "%s %-5s max|d lower|=%.1e max|d upper|=%.1e max|d sd|=%.1e\n",
      if (aipw) "aipw" else "ipw ", ci,
      max(abs(lims[, 1] - r$results$lower_CI_boot)),
      max(abs(lims[, 2] - r$results$upper_CI_boot)),
      max(abs(apply(b$t, 2, sd) - r$results$standard_deviation))
    ))
  }
}

cat("\n== bootstrap re-estimating w-hat in each resample vs holding it fixed ==\n")
stat_fixed <- function(dd, i, wt) {
  x <- dd[i, ]
  ind_ec(x, ys[1], ind_design(x, covs), w = wt)$tau
}
stat_reest <- function(dd, i) {
  x <- dd[i, ]
  ind_ec(x, ys[1], ind_design(x, covs))$tau
}
w_hat <- ind_ec(d, ys[1], Xps)$w
set.seed(5)
b1 <- boot::boot(d, stat_fixed, R = 2000, strata = 2 * d$S + d$A, wt = w_hat)
set.seed(5)
b2 <- boot::boot(d, stat_reest, R = 2000, strata = 2 * d$S + d$A)
cat(sprintf("EC-IPW y1: boot SD with w fixed = %.4f, with w re-estimated = %.4f\n", sd(b1$t), sd(b2$t)))
