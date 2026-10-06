source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# lambda = 0 (the default lambda_min) makes Eq 7 non-unique when a trial
# control lies in the convex hull of the externals. The package estimate
# then depends on the row order of the data.
d <- SyntheticData
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
set.seed(7)
perm <- c(which(d$S == 1), sample(which(d$S == 0)))
dp <- d[perm, ]
for (lam in c(0, 0.1)) {
  m <- scm(lambda_min = lam, lambda_max = lam, nlambda = 1, bootstrap = 2)
  set.seed(1)
  p1 <- pkg_fit(d, m, outs, covs, 2)$point_estimates
  set.seed(1)
  p2 <- pkg_fit(dp, m, outs, covs, 2)$point_estimates
  cat(sprintf("lambda = %.1f: original order %s | externals permuted %s | diff %.2e\n",
    lam, paste(sprintf("%.5f", p1), collapse = ", "),
    paste(sprintf("%.5f", p2), collapse = ", "), max(abs(p1 - p2))))
}
# LOOCV sum of squared errors at lambda 0 and 0.1 for both solvers
X00 <- t(as.matrix(d[d$S == 0, c(covs, outs)]))
colnames(X00) <- NULL
pkg_sse <- function(lam, ec) {
  lt <- outs[3:4]
  keep <- !(rownames(ec) %in% lt)
  s <- 0
  for (k in seq_len(ncol(ec))) {
    w <- as.vector(suppressWarnings(rdborrow:::.scm_subject_sc(
      1, ec[, k, drop = FALSE], ec[, -k], lt, lam
    ))[[1]])
    s <- s + sum((ec[lt, k] - ec[lt, -k] %*% w)^2)
  }
  s
}
cat("package-path (ECOS) LOOCV SSE: lambda 0 =", pkg_sse(0, X00), " lambda 0.1 =", pkg_sse(0.1, X00), "\n")
ind <- ind_scm_lambda(d, outs, 2, covs, c(0, 0.1))
cat("independent (OSQP) LOOCV SSE:  lambda 0 =", ind$sse[1], " lambda 0.1 =", ind$sse[2], "\n")
X00p <- t(as.matrix(dp[dp$S == 0, c(covs, outs)]))
colnames(X00p) <- NULL
cat("package-path LOOCV SSE, externals permuted: lambda 0 =", pkg_sse(0, X00p), "\n")
cat("package LOOCV choice, original:", suppressWarnings(rdborrow:::.scm_lambdacv(X00, outs[3:4], 0, 0.1, 2)),
  " permuted:", suppressWarnings(rdborrow:::.scm_lambdacv(X00p, outs[3:4], 0, 0.1, 2)), "\n")
