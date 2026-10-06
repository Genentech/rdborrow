source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
cat("## alpha contract\n")
for (al in list(0, 1, -0.1, 1.5, NA, "0.05", c(0.05, 0.1), 0.5, 0.999, 1e-10)) {
  cat("--- alpha =", deparse(al), ": ")
  a <- w(mk(ec_ipw(F5), alpha = al))
  if (!is.null(a)) {
    rr <- w(run_analysis(a))
    if (!is.null(rr)) print(rr$results[1, ])
  }
}
cat("\n## alpha applied to normal CI\n")
for (al in c(0.05, 0.2)) {
  rr <- run_analysis(mk(ec_ipw(F5), alpha = al))$results
  print(cbind(rr, implied_z = (rr$upper_CI_normal - rr$point_estimates) / rr$standard_deviation, qnorm_target = qnorm(1 - al / 2)))
}
cat("\n## alpha applied to bootstrap CI (same seed)\n")
for (ty in c("perc", "norm", "basic", "bca")) {
  for (al in c(0.05, 0.5)) {
    set.seed(3)
    rr <- run_analysis(mk(ec_ipw(F5, bootstrap = 200, bootstrap_ci_type = ty), alpha = al))$results
    cat(ty, "alpha", al, ": width", round(rr$upper_CI_boot - rr$lower_CI_boot, 4), "\n")
  }
}
