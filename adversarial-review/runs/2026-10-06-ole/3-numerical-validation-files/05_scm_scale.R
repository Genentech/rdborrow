source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# SCM (Eq 7) matches on raw (unstandardized) z = (X, Y_I). A change of
# units of one covariate changes the estimate. DID estimators are
# invariant to such changes (linear/logistic models are affine-equivariant).
d <- SyntheticData
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
cat("SDs of matching variables among externals:\n")
print(round(sapply(d[d$S == 0, c(covs, outs[1:2])], sd), 2))
ec <- d[d$S == 0, c(covs, outs[1:2])]
ctl <- d[d$S == 1 & d$A == 0, c(covs, outs[1:2])]
# average share of squared distance ||z_i - z_j||^2 from each variable
sh <- Reduce(`+`, lapply(seq_len(nrow(ctl)), function(i) {
  dd <- sweep(as.matrix(ec), 2, unlist(ctl[i, ]))^2
  colSums(dd) / sum(dd)
})) / nrow(ctl)
cat("mean share of squared distance by variable:\n")
print(round(sh, 3))

variants <- list(
  original = d,
  x5_div_100 = transform(d, x5 = x5 / 100),
  x4_times_12 = transform(d, x4 = x4 * 12)
)
f <- fml(outs, covs)
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
for (nm in names(variants)) {
  dv <- variants[[nm]]
  set.seed(1)
  s <- pkg_fit(dv, scm(lambda_min = 0.1, lambda_max = 0.1, nlambda = 1, bootstrap = 2), outs, covs, 2)$point_estimates
  o <- pkg_fit(dv, did_ec_or(f, f, f, bootstrap = 2), outs, covs, 2)$point_estimates
  a <- pkg_fit(dv, did_ec_aipw(ps, NULL, f, bootstrap = 2), outs, covs, 2)$point_estimates
  cat(sprintf("%-12s SCM(lambda=0.1): %s | DID-EC-OR: %s | DID-EC-AIPW: %s\n", nm,
    paste(sprintf("%.4f", s), collapse = ", "), paste(sprintf("%.4f", o), collapse = ", "),
    paste(sprintf("%.4f", a), collapse = ", ")))
}
# standardized matching (each z variable divided by its external-control SD),
# independent implementation, LOOCV over a grid
grid <- c(0, 0.001, 0.01, 0.1, 1)
dz <- d
for (v in c(covs, outs[1:2])) {
  s <- sd(d[d$S == 0, v])
  dz[[v]] <- d[[v]] / s
}
cv_raw <- ind_scm_lambda(d, outs, 2, covs, grid)
cv_std <- ind_scm_lambda(dz, outs, 2, covs, grid)
cat("independent, raw z: lambda", cv_raw$lambda, "tau", ind_scm(d, outs, 2, covs, cv_raw$lambda)$tau, "\n")
cat("independent, standardized z: lambda", cv_std$lambda, "tau", ind_scm(dz, outs, 2, covs, cv_std$lambda)$tau, "\n")
cat("note: Period II outcomes y3, y4 are rescaled too in dz only if listed; they are not, so tau is on the original scale\n")
