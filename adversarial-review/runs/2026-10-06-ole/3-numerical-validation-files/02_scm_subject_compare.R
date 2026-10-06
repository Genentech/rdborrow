source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# per-subject comparison of the SC weights: package (.scm_subject_sc, the
# observed value) versus the independent OSQP solve (the expected value).
# Compare objective values to tell non-uniqueness from suboptimality.
d <- SyntheticData
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
Tc <- 2
X10 <- t(as.matrix(d[d$S == 1 & d$A == 0, c(covs, outs)]))
X00 <- t(as.matrix(d[d$S == 0, c(covs, outs)]))
colnames(X10) <- colnames(X00) <- NULL
lt <- outs[3:4]
zrows <- c(covs, outs[1:2])
for (lam in c(0.1, 0)) {
  res <- t(sapply(seq_len(ncol(X10)), function(i) {
    wp <- as.vector(suppressWarnings(rdborrow:::.scm_subject_sc(i, X10, X00, lt, lam))[[1]])
    wi <- ind_sc_weights(X10[zrows, i], X00[zrows, ], lam)
    c(
      obj_pkg = ind_sc_objective(wp, X10[zrows, i], X00[zrows, ], lam),
      obj_ind = ind_sc_objective(wi, X10[zrows, i], X00[zrows, ], lam),
      maxw = max(abs(wp - wi)),
      yhat = max(abs(X00[lt, ] %*% (wp - wi))),
      minw_pkg = min(wp), sumw_pkg = sum(wp),
      nnz_pkg = sum(wp > 1e-6), nnz_ind = sum(wi > 1e-6)
    )
  }))
  cat("lambda =", lam, "\n")
  print(summary(res))
  cat("max (obj_pkg - obj_ind):", max(res[, "obj_pkg"] - res[, "obj_ind"]),
    " max rel:", max((res[, "obj_pkg"] - res[, "obj_ind"]) / pmax(res[, "obj_ind"], 1e-8)), "\n")
  cat("subjects with |yhat diff| > 1e-3:", sum(res[, "yhat"] > 1e-3), "\n")
  cat("subjects with zero objective (z_i in hull):", sum(res[, "obj_ind"] < 1e-8), "\n")
}
