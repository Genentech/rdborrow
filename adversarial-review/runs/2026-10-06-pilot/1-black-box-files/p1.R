source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
str(SyntheticData)
print(table(S = SyntheticData$S, A = SyntheticData$A))
cat("\n## print analysis object\n")
a <- mk(ec_ipw(F5))
print(class(a))
print(a)
show(a)
cat("isVirtualClass/ slots:\n")
print(slotNames(a))
cat("\n## quiet = FALSE\n")
r <- run_analysis(a, quiet = FALSE)
cat("\n## quiet = TRUE\n")
r <- run_analysis(a, quiet = TRUE)
str(r)
cat("\n## weight arg contract\n")
for (wt in list(-0.1, 1.1, NA, NA_real_, "0.5", c(0.2, 0.3), TRUE, 1L, 0L, Inf, 1e-12, 1 - 1e-12, 1)) {
  cat("--- weight =", deparse(wt), ": ")
  m <- w(ec_ipw(F5, weight = wt))
  if (!is.null(m)) {
    cat("constructed; ")
    rr <- w(run_analysis(mk(m)))
    if (!is.null(rr)) print(c(rr$results$point_estimates, rr$results$standard_deviation, bw = rr$borrow_weight))
  }
}
cat("\n## aipw weight contract\n")
for (wt in list(-0.1, 1.1, NA, c(0.2, 0.3), 1)) {
  cat("--- weight =", deparse(wt), ": ")
  m <- w(ec_aipw(F5, O5, weight = wt))
  if (!is.null(m)) cat("constructed\n")
}
