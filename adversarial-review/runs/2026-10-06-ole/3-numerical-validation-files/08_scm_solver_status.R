source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# does the SCM path check the solver status? Probe with a badly scaled
# covariate (x5 in units 1e6 times smaller), which a user could pass.
d <- SyntheticData
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
X10 <- t(as.matrix(d[d$S == 1 & d$A == 0, c(covs, outs)]))
for (k in c(1e3, 1e5, 1e7)) {
  X00 <- t(as.matrix(d[d$S == 0, c(covs, outs)]))
  X10k <- X10
  X00["x5", ] <- X00["x5", ] * k
  X10k["x5", ] <- X10k["x5", ] * k
  colnames(X00) <- colnames(X10k) <- NULL
  ws <- character()
  fits <- withCallingHandlers(
    lapply(1:20, function(i) rdborrow:::.scm_subject_sc(i, X10k, X00, outs[3:4], 0.1)),
    warning = function(cond) {
      ws <<- c(ws, conditionMessage(cond))
      invokeRestart("muffleWarning")
    }
  )
  sums <- sapply(fits, \(f) sum(f[[1]]))
  mins <- sapply(fits, \(f) min(f[[1]]))
  nas <- sapply(fits, \(f) anyNA(f[[2]]))
  cat(sprintf("x5 * %.0e: sum(w) range [%.4f, %.4f], min w %.2e, NA preds %d, warnings %d\n",
    k, min(sums), max(sums), min(mins), sum(nas), length(ws)))
  if (length(ws)) print(head(unique(ws), 3))
}
