source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# locate the failing LOOCV solve with x4 in days and report CVXR status
d <- SyntheticData
d$x4 <- d$x4 * 365.25
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
ec <- t(as.matrix(d[d$S == 0, c(covs, outs)]))
colnames(ec) <- NULL
lt <- outs[3:4]
keep <- !(rownames(ec) %in% lt)
bad <- NULL
for (lam in c(0, 0.1)) {
  for (k in seq_len(ncol(ec))) {
    x1 <- ec[keep, k]
    X0 <- ec[keep, -k]
    w <- CVXR::Variable(ncol(ec) - 1)
    obj <- sum((x1 - X0 %*% w)^2) + lam * sum(colSums((x1 - X0)^2) * w)
    prob <- CVXR::Problem(CVXR::Minimize(obj), list(sum(w) == 1, w >= 0))
    r <- suppressWarnings(try(CVXR::psolve(prob, solver = "ECOS"), silent = TRUE))
    st <- CVXR::status(prob)
    v <- CVXR::value(w)
    if (!identical(st, "optimal")) {
      bad <- rbind(bad, data.frame(lambda = lam, k = k, status = st, value_class = class(v)[1], value_na = anyNA(v)))
    }
  }
}
print(bad)
cat("independent OSQP on same data, lambda = 0.1, subject k:", if (!is.null(bad)) bad$k[1], "\n")
if (!is.null(bad)) {
  k <- bad$k[1]
  w <- ind_sc_weights(ec[keep, k], ec[keep, -k], bad$lambda[1])
  cat("sum w", sum(w), "objective", ind_sc_objective(w, ec[keep, k], ec[keep, -k], bad$lambda[1]), "\n")
}
