dir <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3"
summ <- function(file, truth_fun) {
  x <- readRDS(file.path(dir, file))
  x$truth <- truth_fun(x)
  key <- interaction(x$meth, x$wn, x$t, drop = TRUE, lex.order = TRUE)
  out <- do.call(rbind, lapply(split(x, key), \(g) {
    R <- nrow(g)
    err <- g$tau - g$truth
    cov <- mean(g$lo <= g$truth & g$truth <= g$hi)
    z <- qnorm(0.975)
    cov_paper <- mean(abs(g$tau - g$truth) <= z * g$se_paper)
    data.frame(
      meth = g$meth[1], w = g$wn[1], t = g$t[1], R = R,
      mean_w = round(mean(g$w), 3),
      bias = round(mean(err), 4), mcse_bias = round(sd(err) / sqrt(R), 4),
      emp_sd = round(sd(g$tau), 4),
      se_ratio = round(mean(g$se) / sd(g$tau), 3),
      cover = round(cov, 3), mcse_cov = round(sqrt(cov * (1 - cov) / R), 3),
      cover_eq13_16 = round(cov_paper, 3),
      se_ratio_eq13_16 = round(mean(g$se_paper) / sd(g$tau), 3),
      max_dtau_ind = signif(max(abs(g$tau - g$tau_ind)), 2),
      max_rel_dse_ind = signif(max(abs(g$se / g$se_full - 1)), 2),
      max_dim0 = if (all(is.na(g$dim0))) NA else signif(max(g$dim0, na.rm = TRUE), 2)
    )
  }))
  rownames(out) <- NULL
  out
}
options(width = 250)
tau_true <- function(x) ifelse(x$t == 1, 1, 2)
for (f in c("mcA_N300.rds", "mcA_N1200.rds")) {
  if (file.exists(file.path(dir, f))) {
    cat("\n####", f, "\n")
    print(summ(f, tau_true))
  }
}
if (file.exists(file.path(dir, "mcB_N300.rds"))) {
  cat("\n#### mcB_N300.rds (expected bias = 0.5 * mean(w))\n")
  s <- summ("mcB_N300.rds", tau_true)
  s$expected_bias <- 0.5 * s$mean_w
  s$z_bias_vs_expected <- round((s$bias - s$expected_bias) / s$mcse_bias, 2)
  print(s[, c("meth", "w", "t", "R", "mean_w", "bias", "mcse_bias", "expected_bias", "z_bias_vs_expected", "cover")])
}
if (file.exists(file.path(dir, "mcboot_N300.rds"))) {
  cat("\n#### mcboot_N300.rds (percentile bootstrap, B = 199)\n")
  s <- summ("mcboot_N300.rds", tau_true)
  print(s[, c("meth", "w", "t", "R", "mean_w", "bias", "mcse_bias", "emp_sd", "se_ratio", "cover", "mcse_cov")])
}
