suppressMessages(pkgload::load_all("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/4-test-strength-artifacts/handpkg", quiet = TRUE))
outs <- paste0("y", 1:4)
vars <- c(paste0("x", 1:5), outs)
print(summary(SyntheticData[, vars]))
X00 <- unname(t(as.matrix(SyntheticData[SyntheticData$S == 0, vars][1:12, ])))
rownames(X00) <- vars
mse <- function(lam) {
  y <- sapply(1:12, function(j) {
    as.vector(suppressWarnings(.scm_subject_sc(1, X00[, j, drop = FALSE], X00[, -j], c("y3", "y4"), lam))[[2]])
  })
  mean((X00[c("y3", "y4"), ] - y)^2)
}
for (l in c(0, 0.001, 0.01, 0.1, 1, 10, 100)) cat(l, mse(l), "\n")
# large lambda: nearest neighbour check
X10 <- unname(t(as.matrix(SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 0, vars][1:3, ])))
rownames(X10) <- vars
Xall <- unname(t(as.matrix(SyntheticData[SyntheticData$S == 0, vars][1:30, ])))
rownames(Xall) <- vars
for (lam in c(10, 1e3, 1e6)) {
  fit <- suppressWarnings(.scm_subject_sc(2, X10, Xall, c("y3", "y4"), lam))
  m <- c(paste0("x", 1:5), "y1", "y2")
  nn <- which.min(colSums((Xall[m, ] - X10[m, 2])^2))
  cat(lam, "argmax w", which.max(fit[[1]]), "max w", max(fit[[1]]), "nn", nn, "\n")
}
