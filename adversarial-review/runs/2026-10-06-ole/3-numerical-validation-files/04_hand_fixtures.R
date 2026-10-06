source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# hand-checkable fixtures; expected values derived by hand in the report

# fixture F1: 2 treated, 2 controls, 4 externals, binary x, T1 = 2, T2 = 3
f1 <- data.frame(
  S  = c(1, 1, 1, 1, 0, 0, 0, 0),
  A  = c(1, 1, 0, 0, 0, 0, 0, 0),
  x  = c(0, 1, 0, 1, 0, 0, 0, 1),
  y1 = c(1, 2, 1, 3, 0, 2, 1, 4),
  y2 = c(2, 3, 1, 5, 1, 3, 1, 6),
  y3 = c(5, 8, 9, 9, 2, 4, 3, 9)
)
outs <- c("y1", "y2", "y3")
set.seed(1)
cat("F1 hand value, saturated models (all three DID): 7/6 =", 7 / 6, "\n")
fx <- paste(outs, "~ x")
cmp("F1 DID-EC-OR  ~x", pkg_fit(f1, did_ec_or(fx, fx, fx, bootstrap = 2), outs, "x", 2)$point_estimates, 7 / 6)
cmp("F1 DID-EC-IPW ~x", pkg_fit(f1, did_ec_ipw("S ~ x", bootstrap = 2), outs, "x", 2)$point_estimates, 7 / 6)
cmp("F1 DID-EC-AIPW ~x", pkg_fit(f1, did_ec_aipw("S ~ x", NULL, fx, bootstrap = 2), outs, "x", 2)$point_estimates, 7 / 6)
cat("F1 hand value, intercept-only models: 7/4 =", 7 / 4, "\n")
f0 <- paste(outs, "~ 1")
cmp("F1 DID-EC-OR  ~1", pkg_fit(f1, did_ec_or(f0, f0, f0, bootstrap = 2), outs, "x", 2)$point_estimates, 7 / 4)
cmp("F1 DID-EC-IPW ~1", pkg_fit(f1, did_ec_ipw("S ~ 1", bootstrap = 2), outs, "x", 2)$point_estimates, 7 / 4)
cmp("F1 DID-EC-AIPW ~1", pkg_fit(f1, did_ec_aipw("S ~ 1", NULL, f0, bootstrap = 2), outs, "x", 2)$point_estimates, 7 / 4)
cat("independent implementation on F1 (~x):",
  ind_did_or(f1, outs, 2, "x"), ind_did_ipw(f1, outs, 2, "x"), ind_did_aipw(f1, outs, 2, "x"), "\n")

# fixture F2: SCM closed form. z = (x, y1); z_a = (0,0), z_b = (4,4),
# control z_i = (3,3) = 0.25 z_a + 0.75 z_b. Eq 7 gives w_a = 0.25 - lambda/4
# (0 <= lambda <= 1). Y2: a = 10, b = 2, treated = 7.
# a third external z_c = (0, 40) is off the a-b line, so the solution is
# unique even at lambda = 0, and KKT shows w_c = 0 for every lambda >= 0
f2 <- data.frame(
  S = c(1, 1, 0, 0, 0), A = c(1, 0, 0, 0, 0),
  x = c(3, 3, 0, 4, 0), y1 = c(3, 3, 0, 4, 40), y2 = c(7, 0, 10, 2, 100)
)
for (lam in c(0, 0.4, 0.8, 1.5)) {
  wa <- max(0.25 - lam / 4, 0)
  expect <- 7 - (10 * wa + 2 * (1 - wa))
  p <- pkg_fit(f2, scm(lambda_min = lam, lambda_max = lam, nlambda = 1, bootstrap = 2), c("y1", "y2"), "x", 1)$point_estimates
  cmp(sprintf("F2 SCM lambda=%.1f (w_a=%.2f)", lam, wa), p, expect)
}

# with only two externals the LOOCV crashes (single remaining column drops
# to a vector)
f2b <- f2[1:4, ]
print(try(pkg_fit(f2b, scm(lambda_min = 0.4, lambda_max = 0.4, nlambda = 1, bootstrap = 2), c("y1", "y2"), "x", 1)))
