# T_cross that is integer-valued only up to floating point
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
y <- c("y1", "y2", "y3", "y4")
m <- did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 200)
tc <- 0.6 / 0.2
cat("T_cross = 0.6 / 0.2 =", sprintf("%.17g", tc), "; checkmate::test_int:", checkmate::test_int(tc), "\n\n")
cat("## T_cross = 3L\n")
set.seed(1); print(ole(m, T_cross = 3L))
cat("\n## T_cross = 0.6 / 0.2\n")
set.seed(1); print(ole(m, T_cross = tc))
cat("\n## T_cross = 2L, for comparison\n")
set.seed(1); print(ole(m, T_cross = 2L))
cat("\n## T_cross = 2 + 1e-9 (CI of row 2 copied from row 1)\n")
set.seed(1); print(suppressWarnings(ole(m, T_cross = 2 + 1e-9)))
for (meth in list(
  did_ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", outcome_formula = f5(y), bootstrap = 200),
  did_ec_or(f5(y), f5(y), f5(y), bootstrap = 200)
)) {
  cat("\n##", meth@method_name, "T_cross = 3L vs 0.6 / 0.2\n")
  set.seed(1); print(suppressWarnings(ole(meth, T_cross = 3L)))
  set.seed(1); print(suppressWarnings(ole(meth, T_cross = tc)))
}
