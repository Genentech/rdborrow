# standalone reproducers on SyntheticData (bootstrap seed 1)
.libPaths(c(
  "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib",
  .libPaths()
))
suppressPackageStartupMessages(library(rdborrow))
outs <- c("y1", "y2", "y3", "y4")
covs <- c("x1", "x2", "x3", "x4", "x5")
run <- function(data, method, B_seed = 1) {
  a <- setup_analysis_OLE(data, "S", "A", outs, covs, method, T_cross = 2)
  set.seed(B_seed)
  suppressWarnings(run_analysis(a))
}
f <- paste0(outs, " ~ x1 + x2 + x3 + x4 + x5")

cat("=== F2 one missing x5 in one external control, B = 200\n")
d <- SyntheticData
d$x5[which(d$S == 0)[1]] <- NA
print(run(d, did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 200)))
cat("did_ec_or, complete data vs one NA (no warning):\n")
print(run(SyntheticData, did_ec_or(f, f, f, bootstrap = 20))$point_estimates)
print(run(d, did_ec_or(f, f, f, bootstrap = 20))$point_estimates)

cat("\n=== F3 scm, x5 in other units (x 10)\n")
m <- scm(lambda_min = 0.01, lambda_max = 0.01, nlambda = 1, bootstrap = 2)
print(run(SyntheticData, m)$point_estimates)
d10 <- SyntheticData
d10$x5 <- d10$x5 * 10
print(run(d10, m)$point_estimates)
