test_that("scm() with a dominant penalty uses nearest-neighbour synthetic controls", {
  skip_if_not_installed("ECOSolveR")
  df <- make_ole_data(n_trt = 5, n_ctrl = 8, n_ext = 25, n_time = 4)
  method <- scm(lambda_min = 1e4, lambda_max = 1e4, nlambda = 1, bootstrap = 5)
  set.seed(1)
  res <- suppressWarnings(run_analysis(ole_analysis(df, method, T_cross = 2)))

  match_on <- c("x1", "x2", "y1", "y2")
  ctrl <- as.matrix(df[df$S == 1 & df$A == 0, match_on])
  ext <- df[df$S == 0, ]
  nn <- apply(ctrl, 1, \(x) which.min(colSums((t(ext[, match_on]) - x)^2)))
  expected <- colMeans(df[df$S == 1 & df$A == 1, c("y3", "y4")]) -
    colMeans(ext[nn, c("y3", "y4")])
  expect_equal(res$point_estimates, unname(expected), tolerance = 1e-5)
  expect_all_true(res$lower_CI_boot < res$upper_CI_boot)

  d <- .build_analysis_df(df, ole_outcomes(df), "A", "S", c("x1", "x2"))
  stat <- suppressWarnings(.scm_boot_statistic(
    d, seq_len(nrow(d)), ole_outcomes(df), c("x1", "x2"), 2, lambda = 1e4
  ))
  expect_equal(unname(stat), unname(expected), tolerance = 1e-5)
})

test_that("scm() confidence intervals honour alpha", {
  skip_on_cran()
  skip_if_not_installed("ECOSolveR")
  df <- make_ole_data(n_trt = 6, n_ctrl = 6, n_ext = 15, n_time = 4)
  method <- scm(lambda_min = 0.01, lambda_max = 0.01, nlambda = 1, bootstrap = 40)
  set.seed(3)
  wide <- suppressWarnings(run_analysis(ole_analysis(df, method, 2, alpha = 0.05)))
  set.seed(3)
  narrow <- suppressWarnings(run_analysis(ole_analysis(df, method, 2, alpha = 0.5)))
  expect_all_true(narrow$lower_CI_boot > wide$lower_CI_boot)
  expect_all_true(narrow$upper_CI_boot < wide$upper_CI_boot)
})

test_that(".scm_lambdacv picks the lambda with the smallest held-out error", {
  skip_if_not_installed("ECOSolveR")
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
  mse <- suppressWarnings(vapply(grid, loocv_mse, numeric(1)))

  lambda <- suppressWarnings(.scm_lambdacv(X00, ole, 0, 0.1, nlambda = 5))
  expect_equal(lambda, grid[which.min(mse)])
  expect_gt(max(mse) - min(mse), 1)
})
