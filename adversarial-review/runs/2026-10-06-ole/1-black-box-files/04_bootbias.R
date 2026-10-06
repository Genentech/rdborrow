# implied bootstrap mean (2 * t0 - centre of the normal CI) for each DID method
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
y4 <- c("y1", "y2", "y3", "y4")
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
B <- 2000
ms <- list(
  ipw = did_ec_ipw(ps, bootstrap = B, bootstrap_ci_type = "norm"),
  aipw = did_ec_aipw(ps, outcome_formula = f5(y4), bootstrap = B, bootstrap_ci_type = "norm"),
  or = did_ec_or(f5(y4), f5(y4), f5(y4), bootstrap = B, bootstrap_ci_type = "norm")
)
for (m in names(ms)) {
  set.seed(42)
  r <- show(ole(ms[[m]]))
  ctr <- (r$lower_CI_boot + r$upper_CI_boot) / 2
  half <- (r$upper_CI_boot - r$lower_CI_boot) / 2
  cat("\n##", m, "\n")
  print(data.frame(t0 = r$point_estimates, boot_mean = 2 * r$point_estimates - ctr,
                   boot_bias = r$point_estimates - ctr, boot_se = half / qnorm(0.975),
                   row.names = rownames(r)))
}
