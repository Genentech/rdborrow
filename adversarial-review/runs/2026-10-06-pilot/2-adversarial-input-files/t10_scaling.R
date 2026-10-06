source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
base <- ra(ec_aipw(ps5, of5))$results
cat("summary x4:", summary(SyntheticData$x4), "\nsummary x5:", summary(SyntheticData$x5), "\n")
for (s in c(10, 100, 1000, 1e4, 1e5)) {
  for (v in c("x5", "x4")) {
    d <- SyntheticData
    d[[v]] <- d[[v]] * s
    cat(sprintf("%s * %g: ", v, s))
    r <- tryCatch(ra(ec_aipw(ps5, of5), d), error = function(e) { cat("ERROR", conditionMessage(e), "\n"); NULL })
    if (!is.null(r)) cat("ok, max diff", format(max(abs(as.matrix(r$results) - as.matrix(base))), digits = 3), "\n")
  }
}
for (s in c(1e-2, 1e-3, 1e-4)) {
  d <- SyntheticData
  d$x4 <- d$x4 * s
  cat(sprintf("x4 * %g: ", s))
  r <- tryCatch(ra(ec_aipw(ps5, of5), d), error = function(e) { cat("ERROR", conditionMessage(e), "\n"); NULL })
  if (!is.null(r)) cat("ok, max diff", format(max(abs(as.matrix(r$results) - as.matrix(base))), digits = 3), "\n")
}
cat("\n== realistic: x5 in grams-like units (x5 * 1000), x4 in days (x4 * 365)\n")
d <- SyntheticData; d$x5 <- d$x5 * 1000; d$x4 <- d$x4 * 365
try_show(ra(ec_aipw(ps5, of5), d))
try_show(ra(ec_ipw(ps5), d))
cat("\n== kappa of the bread matrix, base vs x5*1000\n")
ns <- asNamespace("rdborrow")
for (s in c(1, 1000)) {
  d <- SyntheticData; d$x5 <- d$x5 * s
  df <- ns$.build_analysis_df(d, c("y1", "y2"), "A", "S", cov5)
  core <- ns$.ec_aipw_core(df, c("y1", "y2"), ps5, of5, NULL)
  trace(solve.default, quote(cat("  rcond(a) =", format(rcond(a), digits = 3), "\n")), print = FALSE)
  try(ns$.ec_aipw_se(df, core, 2, of5))
  untrace(solve.default)
}
