source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
pe <- function(m, ...) {
  rr <- w(run_analysis(mk(m, ...)))
  if (!is.null(rr)) print(round(c(rr$results$point_estimates, se = rr$results$standard_deviation, bw = rr$borrow_weight), 6))
}
cat("## alpha 0/1 with bootstrap\n")
set.seed(1); pe(ec_ipw(F5, bootstrap = 50), alpha = 0)
set.seed(1); pe(ec_ipw(F5, bootstrap = 50), alpha = 1)
cat("\n## ps_formula variants (ipw)\n")
for (f in c(F5, "anything ~ x1 + x2 + x3 + x4 + x5", "~ x1 + x2 + x3 + x4 + x5",
            "y1 ~ x1 + x2 + x3 + x4 + x5", "A ~ x1 + x2 + x3 + x4 + x5",
            "S ~ 1", "S ~ x1", "S ~ x1 + x2 + x3 + x4 + x5 + x9", "S ~ .",
            "S ~ x1 + x2 + x3 + x4 + x5 + y1", "S ~ x1 + A", "S ~ x1 + T_cross",
            "S ~ x1 + log(x5)", "cbind(S, 1 - S) ~ x1", "S ~ x1 ~ x2", "not a formula", "")) {
  cat("--- ps_formula =", deparse(f), ": ")
  m <- w(ec_ipw(f))
  if (!is.null(m)) pe(m)
}
cat("\n## formula object rather than string\n")
w(ec_ipw(S ~ x1 + x2))
w(ec_ipw(ps_formula = c("S ~ x1", "S ~ x2")))
cat("\n## covariates listed but not in formula / in formula but not listed\n")
pe(ec_ipw("S ~ x1 + x2"))
pe(ec_ipw("S ~ x1 + x2"), covs = c("x1", "x2"))
pe(ec_ipw(F5), covs = c("x1", "x2"))
pe(ec_ipw(F5), covs = character(0))
pe(ec_ipw(F5), covs = c("x1", "x2", "x3", "x4", "x5", "y3"))
pe(ec_ipw(F5), covs = c("x1", "nope"))
cat("\n## AIPW: outcome model covariates not listed\n")
pe(ec_aipw("S ~ x1 + x2", O5), covs = c("x1", "x2"))
pe(ec_aipw(F5, c("y1 ~ x1", "y2 ~ x1")), covs = c("x1"))
pe(ec_aipw(F5, c("y1 ~ x1 + y3", "y2 ~ x1 + y3")))
