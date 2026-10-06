# scm edge cases
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
yc <- ycols()
covs <- c("x1", "x2", "x3")
d <- make_ole(n1 = 30, n0 = 15, m = 25, seed = 7)

sc_weights <- function(d, lambda, i = 1, T_cross = 2, covs = c("x1", "x2", "x3")) {
  df <- ns$.build_analysis_df(d, yc, "A", "S", covs)
  X10 <- t(as.matrix(df[df$S == 1 & df$A == 0, c(covs, yc)]))
  X00 <- t(as.matrix(df[df$S == 0, c(covs, yc)]))
  colnames(X10) <- NULL
  colnames(X00) <- NULL
  ns$.scm_subject_sc(i, X10, X00, yc[(T_cross + 1):4], lambda)
}

cat("=== T1 exact twin: first trial control copied into the EC pool\n")
dt <- d
ctrl1 <- which(dt$S == 1 & dt$A == 0)[1]
twin <- dt[ctrl1, ]
twin$S <- 0
twin$y3 <- 100
twin$y4 <- 200
dt <- rbind(dt, twin)
for (lam in c(0, 0.01)) {
  r <- sc_weights(dt, lam)
  w <- as.vector(r[[1]])
  cat(sprintf("lambda=%s: weight on twin %.6f, synthetic y3,y4 = %s\n",
              lam, w[length(w)], paste(round(r[[2]], 4), collapse = ", ")))
}

cat("\n=== L1 large-magnitude covariate: x1 * 10^k (solver status and weights)\n")
for (k in c(0, 2, 4, 6, 8)) {
  d2 <- d
  d2$x1 <- d2$x1 * 10^k
  ws <- character()
  r <- tryCatch(withCallingHandlers(sc_weights(d2, 0.01), warning = function(w) {
    ws <<- c(ws, conditionMessage(w))
    invokeRestart("muffleWarning")
  }), error = function(e) e)
  if (inherits(r, "error")) {
    cat(sprintf("k=%d: ERROR %s\n", k, conditionMessage(r)))
    next
  }
  w <- as.vector(r[[1]])
  est <- suppressWarnings(pe(d2, "scm", lambda = 0.01))
  cat(sprintf("k=%d: sum(w)-1 = %.2g, min(w) = %.2g, tau = %s, warnings: %s\n",
              k, sum(w) - 1, min(w), paste(round(est, 3), collapse = ", "),
              paste(unique(ws), collapse = " | ")))
}

cat("\n=== FAC factor covariate in scm()\n")
df2 <- d
df2$x2 <- factor(df2$x2)
show_try(fit(df2, m_scm(2), covs = covs))

cat("\n=== TINY EC arm m = 1, 2, 3\n")
for (m in 1:3) {
  cat("-- m =", m, "\n")
  dd <- make_ole(n1 = 10, n0 = 5, m = m, seed = 8)
  show_try(fit(dd, m_scm(2, lambda_min = 0, lambda_max = 0.1, nlambda = 2)))
}

cat("\n=== TINY trial control arm n0 = 1\n")
dd <- make_ole(n1 = 10, n0 = 1, m = 10, seed = 9)
show_try(fit(dd, m_scm(3)))

cat("\n=== NA in an EC covariate\n")
dm <- d
dm$x1[which(dm$S == 0)[1]] <- NA
show_try(fit(dm, m_scm(3)))
cat("=== NA in a trial-control period-II outcome (unused cell)\n")
dm <- d
dm$y4[which(dm$S == 1 & dm$A == 0)[1]] <- NA
show_try(fit(dm, m_scm(3)))
cat("=== NA in a treated period-I outcome (unused cell)\n")
dm <- d
dm$y1[which(dm$A == 1)[1]] <- NA
show_try(fit(dm, m_scm(3)))

cat("\n=== T_cross = 1 and 3\n")
show_try(fit(d, m_scm(3), T_cross = 1))
show_try(fit(d, m_scm(3), T_cross = 3))

cat("\n=== bootstrap = 2, each CI type\n")
for (ty in c("perc", "basic", "norm", "bca")) {
  cat("--", ty, "\n")
  show_try(fit(d, m_scm(2, bootstrap_ci_type = ty)))
}
