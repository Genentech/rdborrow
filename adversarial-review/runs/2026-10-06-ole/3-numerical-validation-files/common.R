.libPaths(c("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib", .libPaths()))
suppressPackageStartupMessages(library(rdborrow))
N3 <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3"
source(file.path(dirname(N3), "3-independent-implementation.R"))
pkg_fit <- function(d, method, outs, covs, Tc) {
  a <- setup_analysis_OLE(
    data = d, trial_status_col_name = "S", treatment_col_name = "A",
    outcome_col_name = outs, covariates_col_name = covs, T_cross = Tc,
    method_OLE_obj = method
  )
  suppressWarnings(run_analysis(a))
}
fml <- function(outs, covs) paste(outs, "~", paste(covs, collapse = " + "))
cmp <- function(lbl, pkg, ind) {
  cat(sprintf(
    "%-28s pkg = %s | ind = %s | max|diff| = %.2e\n", lbl,
    paste(sprintf("%.8f", pkg), collapse = ", "),
    paste(sprintf("%.8f", ind), collapse = ", "), max(abs(pkg - ind))
  ))
}
