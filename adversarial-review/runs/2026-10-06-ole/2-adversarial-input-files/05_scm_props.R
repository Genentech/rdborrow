# scm properties (point estimate for a fixed lambda, through .scm_boot_statistic
# with identity indices, which is the same computation estimate() uses)
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")

d <- make_ole(n1 = 30, n0 = 15, m = 25, seed = 7)
yc <- ycols()
covs <- c("x1", "x2", "x3")

weights_for <- function(d, lambda, T_cross = 2, covs = c("x1", "x2", "x3")) {
  df <- ns$.build_analysis_df(d, yc, "A", "S", covs)
  X10 <- t(as.matrix(df[df$S == 1 & df$A == 0, c(covs, yc)]))
  X00 <- t(as.matrix(df[df$S == 0, c(covs, yc)]))
  colnames(X10) <- NULL
  colnames(X00) <- NULL
  sapply(seq_len(ncol(X10)), \(i) {
    as.vector(ns$.scm_subject_sc(i, X10, X00, yc[(T_cross + 1):4], lambda)[[1]])
  })
}

cat("=== W1 weights nonnegative and sum to one\n")
for (lam in c(0, 0.01, 1)) {
  W <- weights_for(d, lam)
  cat(sprintf("lambda=%-5s min weight %.3g, max |colsum - 1| %.3g, max nonzero per control %d\n",
              lam, min(W), max(abs(colSums(W) - 1)), max(colSums(W > 1e-6))))
}

check <- function(label, d2, lambda, expected, tol = 1e-5) {
  got <- pe(d2, "scm", lambda = lambda)
  dev <- max(abs(got - expected))
  cat(sprintf("%-58s lambda=%-5s max|dev| = %.3g %s\n", label, lambda, dev,
              if (dev < tol) "HOLDS" else "FAILS"))
  invisible(got)
}

for (lam in c(0, 0.01)) {
  base <- pe(d, "scm", lambda = lam)
  cat(sprintf("\nbase lambda=%s: %s (true 1.5, 2)\n", lam, paste(round(base, 4), collapse = ", ")))
  set.seed(11)
  check("S1 permute rows", d[sample(nrow(d)), ], lam, base)
  set.seed(12)
  ec <- which(d$S == 0)
  check("S1b permute external-control rows only", d[c(which(d$S == 1), sample(ec)), ], lam, base)
  d2 <- d; d2[yc] <- d2[yc] + 100
  check("S2 +100 to every outcome", d2, lam, base)
  d2 <- d; d2[c(covs, yc)] <- d2[c(covs, yc)] * 3
  check("S3 covariates and outcomes * 3 -> tau * 3", d2, lam, 3 * base)
  d2 <- d; d2[d2$S == 0, yc[3:4]] <- sweep(as.matrix(d2[d2$S == 0, yc[3:4]]), 2, c(1, 3), "+")
  check("S4 EC period II + (1, 3) -> tau - (1, 3)", d2, lam, base - c(1, 3))
  d2 <- d; set.seed(13); d2[d2$A == 1, yc[1:2]] <- rnorm(60, 50, 10)
  check("S5 scramble treated-arm period I (unused)", d2, lam, base)
  d2 <- d; set.seed(14); d2[d2$S == 1 & d2$A == 0, yc[3:4]] <- rnorm(30, -50, 10)
  check("S6 scramble trial-control period II (unused)", d2, lam, base)
  d2 <- d; d2[yc] <- d2[yc] * 3
  check("S7 outcomes only * 3 (not promised; Eq. 7 is unscaled)", d2, lam, 3 * base)
  d2 <- d; d2$x1 <- d2$x1 * 1000
  check("S8 x1 in other units (* 1000) (not promised)", d2, lam, base)
}
