art <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole"
suppressMessages(pkgload::load_all(file.path(art, "4-test-strength-artifacts/handpkg"), quiet = TRUE))
source(file.path(art, "proposed-tests/helper-ole.R"))
df <- make_ole_data(n_trt = 5, n_ctrl = 8, n_ext = 25, n_time = 4)
method <- scm(lambda_min = 1e4, lambda_max = 1e4, nlambda = 1, bootstrap = 5)
set.seed(1)
res <- suppressWarnings(run_analysis(ole_analysis(df, method, T_cross = 2)))
print(res)
match_on <- c("x1", "x2", "y1", "y2")
ctrl <- as.matrix(df[df$S == 1 & df$A == 0, match_on])
ext <- df[df$S == 0, ]
nn <- apply(ctrl, 1, \(x) which.min(colSums((t(ext[, match_on]) - x)^2)))
print(nn)
print(colMeans(df[df$S == 1 & df$A == 1, c("y3", "y4")]) - colMeans(ext[nn, c("y3", "y4")]))
X10 <- t(as.matrix(df[df$S == 1 & df$A == 0, c("x1", "x2", "y1", "y2", "y3", "y4")]))
colnames(X10) <- NULL
X00 <- t(as.matrix(ext[, c("x1", "x2", "y1", "y2", "y3", "y4")]))
colnames(X00) <- NULL
for (i in 1:8) {
  f <- suppressWarnings(.scm_subject_sc(i, X10, X00, c("y3", "y4"), 1e4))
  cat(i, which.max(f[[1]]), round(max(f[[1]]), 4), "\n")
}
