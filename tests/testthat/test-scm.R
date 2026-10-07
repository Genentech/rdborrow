test_that(".scm_subject_sc returns convex weights and their predictions", {
  skip_if_not_installed("ECOSolveR")
  outs <- paste0("y", 1:4)
  vars <- c(paste0("x", 1:5), outs)
  ext <- SyntheticData[SyntheticData$S == 0, vars][1:15, ]
  ctrl <- SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 0, vars][1:3, ]
  X00 <- unname(t(as.matrix(rbind(ext, ctrl[1, ]))))
  X10 <- unname(t(as.matrix(ctrl)))
  rownames(X00) <- rownames(X10) <- vars

  fit <- suppressWarnings(
    .scm_subject_sc(2, X10, X00, c("y3", "y4"), lambda = 0.1)
  )
  w <- as.vector(fit[[1]])
  expect_all_true(w > -1e-6)
  expect_equal(sum(w), 1, tolerance = 1e-6)
  expect_equal(as.vector(fit[[2]]), as.vector(X00[c("y3", "y4"), ] %*% w))

  exact <- suppressWarnings(
    .scm_subject_sc(1, X10, X00, c("y3", "y4"), lambda = 0.1)
  )
  expect_equal(as.vector(exact[[1]])[16], 1, tolerance = 1e-4)
})

test_that(".scm_lambdacv searches a real lambda path", {
  skip_if_not_installed("ECOSolveR")
  outs <- paste0("y", 1:4)
  vars <- c(paste0("x", 1:5), outs)
  X00 <- unname(t(as.matrix(SyntheticData[SyntheticData$S == 0, vars][1:12, ])))
  rownames(X00) <- vars

  lambda <- suppressWarnings(.scm_lambdacv(
    X00, c("y3", "y4"),
    lambda_min = 0, lambda_max = 0.2, nlambda = 3
  ))

  expect_length(lambda, 1)
  expect_contains(c(0, 0.1, 0.2), lambda)
})

test_that("scm() runs end to end on a small data set", {
  skip_if_not_installed("ECOSolveR")
  d <- rbind(
    SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 1, ][1:10, ],
    SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 0, ][1:10, ],
    SyntheticData[SyntheticData$S == 0, ][1:15, ]
  )
  analysis <- setup_analysis_OLE(
    data = d,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = c("y1", "y2", "y3", "y4"),
    covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
    T_cross = 2,
    method_OLE_obj = scm(bootstrap = 5)
  )

  set.seed(1)
  res <- suppressWarnings(run_analysis(analysis))

  expect_identical(rownames(res), c("tau3", "tau4"))
  expect_all_true(is.finite(unlist(res)))
})

test_that("the scm bootstrap statistic equals the estimate on the original sample", {
  skip_if_not_installed("ECOSolveR")
  outs <- c("y1", "y2", "y3", "y4")
  covs <- c("x1", "x2", "x3", "x4", "x5")
  d <- rbind(
    SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 1, ][1:10, ],
    SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 0, ][1:10, ],
    SyntheticData[SyntheticData$S == 0, ][1:15, ]
  )
  method <- scm(lambda_min = 0.05, lambda_max = 0.05, nlambda = 1, bootstrap = 2)
  set.seed(1)
  res <- suppressWarnings(estimate(
    method,
    data = d, outcomes = outs, treatment = "A", trial_status = "S",
    covariates = covs, T_cross = 2
  ))
  df <- .build_analysis_df(d, outs, "A", "S", covs)
  boot_pe <- .scm_boot_statistic(
    df, seq_len(nrow(df)),
    outcomes = outs, covariates = covs, T_cross = 2, lambda = 0.05
  )
  expect_equal(unname(boot_pe), res$point_estimates)
})

test_that("scm() runs with two external controls and rejects one", {
  skip_if_not_installed("ECOSolveR")
  fit <- function(n_ext) {
    d <- rbind(
      SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 1, ][1:10, ],
      SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 0, ][1:10, ],
      SyntheticData[SyntheticData$S == 0, ][seq_len(n_ext), ]
    )
    analysis <- setup_analysis_OLE(
      d, "S", "A", c("y1", "y2", "y3", "y4"), c("x1", "x2", "x3", "x4", "x5"),
      scm(bootstrap = 2),
      T_cross = 2
    )
    set.seed(1)
    suppressWarnings(run_analysis(analysis))
  }
  expect_all_true(is.finite(fit(2)$point_estimates))
  expect_error(fit(1), "scm.*at least 2 external controls")
})

test_that("scm() names a covariate that is not numeric", {
  skip_if_not_installed("ECOSolveR")
  d <- rbind(
    SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 1, ][1:10, ],
    SyntheticData[SyntheticData$S == 1 & SyntheticData$A == 0, ][1:10, ],
    SyntheticData[SyntheticData$S == 0, ][1:15, ]
  )
  d$x1 <- factor(d$x1, levels = c(0, 1), labels = c("type II", "type III"))
  analysis <- setup_analysis_OLE(
    d, "S", "A", c("y1", "y2", "y3", "y4"), c("x1", "x2", "x3", "x4", "x5"),
    scm(bootstrap = 2),
    T_cross = 2
  )
  expect_error(run_analysis(analysis), "scm.*numeric.*x1")
})
