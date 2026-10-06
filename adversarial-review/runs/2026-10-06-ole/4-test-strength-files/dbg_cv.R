suppressMessages(pkgload::load_all("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/4-test-strength-artifacts/handpkg", quiet = TRUE))
vars <- c(paste0("x", 1:5), paste0("y", 1:4))
X00 <- unname(t(as.matrix(SyntheticData[SyntheticData$S == 0, vars][1:12, ])))
rownames(X00) <- vars
ole <- c("y3", "y4")
grid <- seq(0, 0.1, length.out = 5)
loocv_mse <- function(lambda) {
  pred <- vapply(seq_len(ncol(X00)), \(j) {
    fit <- .scm_subject_sc(1, X00[, j, drop = FALSE], X00[, -j], ole, lambda)
    as.vector(fit[[2]])
  }, numeric(2))
  mean((X00[ole, ] - pred)^2)
}
print(suppressWarnings(vapply(grid, loocv_mse, numeric(1))))
print(suppressWarnings(.scm_lambdacv(X00, ole, 0, 0.1, nlambda = 5)))
# what X10 rownames look like inside .scm_subject_sc with one column
x <- X00[, 1, drop = FALSE]
print(dim(x)); print(rownames(x))
