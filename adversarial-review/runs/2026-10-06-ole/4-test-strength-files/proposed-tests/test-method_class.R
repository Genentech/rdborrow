test_that(".run_bootstrap resamples within (S, A) strata", {
  df <- make_ole_data(n_trt = 20, n_ctrl = 7, n_ext = 13, n_time = 3)
  counts <- function(data, indices) {
    d <- data[indices, ]
    c(mean(d$y1), sum(d$S == 1 & d$A == 1), sum(d$S == 1 & d$A == 0), sum(d$S == 0))
  }
  set.seed(1)
  res <- suppressWarnings(.run_bootstrap(df, counts, 1, 30, "perc", 0.05))
  expect_gt(res$sd_boot[1], 0)
  expect_equal(res$sd_boot[2:4], c(0, 0, 0))
})

test_that(".run_bootstrap returns boot.ci intervals at level 1 - alpha", {
  df <- make_ole_data(n_time = 3)
  stat <- function(data, indices) mean(data$y3[indices])
  set.seed(7)
  res <- .run_bootstrap(df, stat, 1, 99, "perc", alpha = 0.2)
  set.seed(7)
  b <- boot::boot(df, stat, R = 99, strata = as.integer(interaction(df$S, df$A, drop = TRUE)))
  ci <- boot::boot.ci(b, conf = 0.8, type = "perc")$percent[4:5]
  expect_equal(c(res$lower_ci, res$upper_ci), ci)
})

test_that("OLE constructors accept every supported CI type and reject others", {
  f <- "y1 ~ x1"
  constructors <- list(
    \(type) did_ec_ipw("S ~ x1", bootstrap_ci_type = type),
    \(type) did_ec_aipw("S ~ x1", outcome_formula = f, bootstrap_ci_type = type),
    \(type) did_ec_or(f, f, f, bootstrap_ci_type = type),
    \(type) scm(bootstrap_ci_type = type)
  )
  for (make in constructors) {
    for (type in c("perc", "bca", "norm", "basic")) {
      expect_identical(make(type)@bootstrap_ci_type, type)
    }
    expect_error(make("stud"))
  }
})
