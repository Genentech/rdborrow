source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# which lambda does LOOCV pick on SyntheticData, package vs independent,
# and what warnings does the package solver path raise?
d <- SyntheticData
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
Tc <- 2
X00 <- t(as.matrix(d[d$S == 0, c(covs, outs)]))
colnames(X00) <- NULL
w <- NULL
lam_pkg <- withCallingHandlers(
  rdborrow:::.scm_lambdacv(X00, outs[3:4], 0, 0.1, 2),
  warning = function(cond) {
    w <<- c(w, conditionMessage(cond))
    invokeRestart("muffleWarning")
  }
)
cat("package LOOCV on default grid {0, 0.1}:", lam_pkg, "\n")
print(table(w))
grid <- c(0, 1e-3, 0.01, 0.1, 1)
ind <- ind_scm_lambda(d, outs, Tc, covs, grid)
cat("independent LOOCV SSE over grid", grid, ":\n")
print(ind$sse)
cat("independent choice:", ind$lambda, "\n")
lam_pkg5 <- suppressWarnings(rdborrow:::.scm_lambdacv(X00, outs[3:4], 0, 1, 5))
cat("package LOOCV on seq(0, 1, length.out = 5):", lam_pkg5, "\n")
ind5 <- ind_scm_lambda(d, outs, Tc, covs, seq(0, 1, length.out = 5))
cat("independent LOOCV on same grid:", ind5$lambda, " SSE:", ind5$sse, "\n")
