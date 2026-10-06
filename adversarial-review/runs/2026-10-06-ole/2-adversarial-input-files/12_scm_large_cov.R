# scm() with a realistic large-magnitude covariate (platelet count per uL)
# through the public API; seed 7 for the data, 2024 for the bootstrap
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
yc <- ycols()
d <- make_ole(n1 = 30, n0 = 15, m = 25, seed = 7)
set.seed(70)
d$x3 <- round(rnorm(nrow(d), 250000, 50000))

show_try(fit(d, m_scm(5)))

df <- ns$.build_analysis_df(d, yc, "A", "S", c("x1", "x2", "x3"))
X10 <- t(as.matrix(df[df$S == 1 & df$A == 0, c("x1", "x2", "x3", yc)]))
X00 <- t(as.matrix(df[df$S == 0, c("x1", "x2", "x3", yc)]))
colnames(X10) <- NULL
colnames(X00) <- NULL
W <- suppressWarnings(sapply(seq_len(ncol(X10)), \(i) {
  as.vector(ns$.scm_subject_sc(i, X10, X00, yc[3:4], 0.01)[[1]])
}))
cat(sprintf("min weight %.4f; controls with a weight < -1e-6: %d of %d; max |sum - 1| %.2g\n",
            min(W), sum(apply(W, 2, min) < -1e-6), ncol(W), max(abs(colSums(W) - 1))))
