# is the scm bootstrap distribution centred on the point estimate?
# compare with did_ec_or on the same data. seed 2024 for the bootstrap.
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
yc <- ycols()
covs <- c("x1", "x2", "x3")

centre <- function(d, label, B = 100, lambda = 0.01, T_cross = 2) {
  df <- ns$.build_analysis_df(d, yc, "A", "S", covs)
  strata <- as.integer(interaction(df$S, df$A, drop = TRUE))
  set.seed(2024)
  b <- boot::boot(df, function(data, i) {
    ns$.scm_boot_statistic(data, i, yc, covs, T_cross, lambda)
  }, R = B, strata = strata)
  set.seed(2024)
  bo <- boot::boot(df, function(data, i) {
    f <- forms()
    ns$.did_ec_or_boot_statistic(data, i, yc, f, f, f, T_cross)
  }, R = B, strata = strata)
  for (j in seq_along(b$t0)) {
    cat(sprintf("%-28s tau%d SCM: t0 %.3f, boot mean %.3f, frac(t* > t0) %.2f, perc CI (%.3f, %.3f) | OR: t0 %.3f, boot mean %.3f, frac %.2f\n",
                label, T_cross + j, b$t0[j], mean(b$t[, j]), mean(b$t[, j] > b$t0[j]),
                quantile(b$t[, j], 0.025), quantile(b$t[, j], 0.975),
                bo$t0[j], mean(bo$t[, j]), mean(bo$t[, j] > bo$t0[j])))
  }
}

centre(make_ole(n1 = 30, n0 = 15, m = 25, seed = 7), "seed 7, m = 25")
centre(make_ole(n1 = 40, n0 = 20, m = 40, seed = 8), "seed 8, m = 40")
centre(make_ole(n1 = 40, n0 = 20, m = 40, seed = 9, ec_shift = 1), "seed 9, m = 40, shift 1")
sd <- SyntheticData
names(sd)[names(sd) %in% c("x1", "x2", "x3")] <- c("x1", "x2", "x3")
