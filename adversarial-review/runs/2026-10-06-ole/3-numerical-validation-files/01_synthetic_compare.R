source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
d <- SyntheticData
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
Tc <- 2
f <- fml(outs, covs)
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
tr <- "A ~ x1 + x2 + x3 + x4 + x5"
set.seed(1)
for (tc in 1:3) {
  cat("---- T_cross =", tc, "\n")
  cmp("DID-EC-OR", pkg_fit(d, did_ec_or(f, f, f, bootstrap = 2), outs, covs, tc)$point_estimates,
    ind_did_or(d, outs, tc, covs))
  cmp("DID-EC-IPW (marginal piA)", pkg_fit(d, did_ec_ipw(ps, bootstrap = 2), outs, covs, tc)$point_estimates,
    ind_did_ipw(d, outs, tc, covs))
  cmp("DID-EC-IPW (trt model)", pkg_fit(d, did_ec_ipw(ps, tr, bootstrap = 2), outs, covs, tc)$point_estimates,
    ind_did_ipw(d, outs, tc, covs, trt_covs = covs))
  cmp("DID-EC-AIPW (marginal piA)", pkg_fit(d, did_ec_aipw(ps, NULL, f, bootstrap = 2), outs, covs, tc)$point_estimates,
    ind_did_aipw(d, outs, tc, covs))
  cmp("DID-EC-AIPW (trt model)", pkg_fit(d, did_ec_aipw(ps, tr, f, bootstrap = 2), outs, covs, tc)$point_estimates,
    ind_did_aipw(d, outs, tc, covs, trt_covs = covs))
}
cat("---- SCM, T_cross = 2, fixed lambda\n")
for (lam in c(0.1, 0.001, 0)) {
  t0 <- Sys.time()
  p <- pkg_fit(d, scm(lambda_min = lam, lambda_max = lam, nlambda = 1, bootstrap = 2), outs, covs, Tc)$point_estimates
  i <- ind_scm(d, outs, Tc, covs, lam)$tau
  cmp(paste0("SCM lambda=", lam), p, i)
  cat("  time", format(Sys.time() - t0), "\n")
}
