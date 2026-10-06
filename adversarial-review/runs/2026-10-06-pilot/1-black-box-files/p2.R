source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
cat("## visibility of setup_analysis_primary\n")
print(withVisible(mk(ec_ipw(F5)))$visible)
print(withVisible(run_analysis(mk(ec_ipw(F5))))$visible)
cat("\n## bootstrap arg contract\n")
for (b in list(0, 1, 2, 2.5, -5, "100", NA, TRUE, 1e6 + 0.5, 3L)) {
  cat("--- bootstrap =", deparse(b), ": ")
  m <- w(ec_ipw(F5, bootstrap = b))
  if (!is.null(m)) cat("constructed, ci_type =", deparse(m@bootstrap_ci_type), "\n")
}
cat("\n## ci type without bootstrap\n")
m <- w(ec_ipw(F5, bootstrap_ci_type = "bca"))
if (!is.null(m)) {
  cat("constructed; slot ci type =", m@bootstrap_ci_type, "\n")
  print(w(run_analysis(mk(m))))
}
m <- w(ec_aipw(F5, O5, bootstrap_ci_type = "norm"))
if (!is.null(m)) cat("aipw constructed; slot ci type =", m@bootstrap_ci_type, "\n")
cat("\n## invalid ci types\n")
for (ty in list("stud", "percentile", "PERC", c("perc", "bca"), NA, 1)) {
  cat("--- type =", deparse(ty), ": ")
  m <- w(ec_ipw(F5, bootstrap = 20, bootstrap_ci_type = ty))
  if (!is.null(m)) cat("constructed\n")
}
cat("\n## every ci type, both methods\n")
for (ty in c("perc", "bca", "norm", "basic")) {
  for (meth in c("ipw", "aipw")) {
    for (B in c(30, 400)) {
      m <- if (meth == "ipw") ec_ipw(F5, bootstrap = B, bootstrap_ci_type = ty) else
        ec_aipw(F5, O5, bootstrap = B, bootstrap_ci_type = ty)
      set.seed(11)
      cat("--- ", meth, ty, "B =", B, "\n")
      rr <- w(run_analysis(mk(m)))
      if (!is.null(rr)) print(rr$results)
    }
  }
}
