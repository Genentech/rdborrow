source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
options(digits = 10)

pkg <- function(method, data, ycols, covs) {
  estimate(method,
    data = data, outcomes = ycols, treatment = "A",
    trial_status = "S", covariates = covs
  )
}

cat("== hand fixture ==\n")
hf <- hand_fixture()
for (w in list(NULL, 0, 0.5)) {
  r <- pkg(ec_ipw("S ~ x", weight = w), hf, c("y1", "y2"), "x")
  f <- ind_ec(hf, c("y1", "y2"), ind_design(hf, "x"), w = w)
  cat(sprintf(
    "w=%s pkg_w=%.10f ind_w=%.10f pkg_tau=%s ind_tau=%s\n",
    format(w), r$borrow_weight, f$w,
    paste(format(r$results$point_estimates), collapse = ","),
    paste(format(f$tau), collapse = ",")
  ))
}
cat("hand-expected: w_opt", hand_expected$w_opt, "tau_opt", hand_expected$tau_opt, "\n")
f <- ind_ec(hf, c("y1", "y2"), ind_design(hf, "x"))
cat("ind W00 ext:", f$W00[hf$S == 0], "\n")

cat("\n== SyntheticData ==\n")
d <- SyntheticData
covs <- c("x1", "x2", "x3", "x4", "x5")
ycols <- c("y1", "y2", "y3", "y4")
ps_f <- "S ~ x1 + x2 + x3 + x4 + x5"
out_f <- paste0(ycols, " ~ x1 + x2 + x3 + x4 + x5")
Xps <- ind_design(d, covs)

res <- list()
for (meth in c("ipw", "aipw")) {
  for (w in list(NULL, 0, 0.3, 1)) {
    m <- if (meth == "ipw") ec_ipw(ps_f, weight = w) else ec_aipw(ps_f, out_f, weight = w)
    r <- pkg(m, d, ycols, covs)
    f <- ind_ec(d, ycols, Xps, Xps, aipw = meth == "aipw", w = w)
    sw <- ind_sandwich(f, d, ycols, Xps, Xps, aipw = meth == "aipw")
    lab <- sprintf("%s w=%s", meth, if (is.null(w)) "opt" else w)
    cat(sprintf(
      "%-12s w pkg=%.8f ind=%.8f | max|dtau|=%.2e | max rel dSE(full)=%.2e | SE paper-Eq13/16 / pkg: %s\n",
      lab, r$borrow_weight, f$w,
      max(abs(r$results$point_estimates - f$tau)),
      max(abs(r$results$standard_deviation / sw$se_full - 1)),
      paste(sprintf("%.4f", sw$se_paper / r$results$standard_deviation), collapse = " ")
    ))
    if (meth == "ipw" && identical(w, 0)) {
      dm <- ind_dim(d, ycols)
      cat(sprintf(
        "   w=0 vs trial-only DIM: max|dtau|=%.2e max rel dSE=%.2e\n",
        max(abs(dm$tau - r$results$point_estimates)),
        max(abs(dm$se / r$results$standard_deviation - 1))
      ))
    }
    cat("   pkg SE:", sprintf("%.6f", r$results$standard_deviation), "\n")
    cat("   ind SE:", sprintf("%.6f", sw$se_full), "\n")
    cat("   max |colMeans(psi)| at estimate:", sprintf("%.1e", max(abs(sw$psi_mean))), "\n")
  }
}
