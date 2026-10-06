source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
ns <- asNamespace("rdborrow")
cat("binomial linkinv at eta = -29, -31, -60, -500:", format(binomial()$linkinv(c(-29, -31, -60, -500)), digits = 3), "\n\n")
cat("shift = amount added to external x5 (trial x5 ~ 8..84). Columns: shift, n glm warnings, borrow_weight, tau1, SE1, ESS of ext weights, range of ext eta\n")
for (shift in c(0, 10, 20, 30, 40, 60, 80, 100, 200)) {
  d <- SyntheticData
  d$x5[d$S == 0] <- d$x5[d$S == 0] + shift
  nw <- 0
  r <- withCallingHandlers(ra(ec_ipw("S ~ x5"), d, x = "x5"),
    warning = function(w) { nw <<- nw + 1; invokeRestart("muffleWarning") })
  df <- ns$.build_analysis_df(d, c("y1", "y2"), "A", "S", "x5")
  wt <- suppressWarnings(ns$.ec_weights(df, "S ~ x5", df$S))
  w_ext <- wt$w00[df$S == 0]
  eta <- predict(wt$ps_model)[df$S == 0]
  cat(sprintf("%5g %2d  %.4f  %8.4f  %7.4f  ESS=%6.1f  eta in [%.1f, %.1f]\n", shift, nw, r$borrow_weight,
    r$results$point_estimates[1], r$results$standard_deviation[1], sum(w_ext)^2 / sum(w_ext^2), min(eta), max(eta)))
}
cat("\nReference: weight implied by perfectly comparable externals (all W00 equal): (1/n0)/(1/n0 + 1/m) =",
  (1 / 100) / (1 / 100 + 1 / 100), "\n")
cat("\n== shift 200 with ec_aipw\n")
d <- SyntheticData; d$x5[d$S == 0] <- d$x5[d$S == 0] + 200
try_show(ra(ec_aipw("S ~ x5", c("y1 ~ x5", "y2 ~ x5")), d, x = "x5"))
cat("\n== shift 200 with externals' outcomes + 20 (gross bias), EC-IPW optimal\n")
d$y1[d$S == 0] <- d$y1[d$S == 0] + 20
try_show(ra(ec_ipw("S ~ x5"), d, x = "x5"))
