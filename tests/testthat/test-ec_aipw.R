test_that("the ec_aipw() sandwich SE equals an independent c' Sigma c", {
  covs <- c("x1", "x2", "x3", "x4", "x5")
  outs <- c("y1", "y2")
  for (w in list(NULL, 0.3, 1)) {
    res <- run_analysis(setup_analysis_primary(
      SyntheticDataII, "S", "A", outs, covs,
      ec_aipw(
        "S ~ x1 + x2 + x3 + x4 + x5",
        paste(outs, "~ x1 + x2 + x3 + x4 + x5"),
        weight = w
      )
    ))
    ind <- independent_ec(
      SyntheticDataII, outs, covs,
      w = res$borrow_weight, augment = TRUE
    )
    expect_equal(res$results$point_estimates, ind$tau, tolerance = 1e-6)
    expect_equal(res$results$standard_deviation, ind$sd, tolerance = 1e-6)
  }
})
