source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
d <- SyntheticData
pr <- function(m, ...) {
  rr <- w(run_analysis(mk(m, ...)))
  if (!is.null(rr)) {
    print(rr$results)
    cat("borrow_weight:", rr$borrow_weight, "\n")
  }
  invisible(rr)
}
O <- function(ys) paste(ys, "~ x1 + x2 + x3 + x4 + x5")
cat("## outcome counts\n")
for (ys in list("y1", "y2", c("y1", "y2", "y3"), c("y1", "y2", "y3", "y4"), c("y4", "y1"))) {
  cat("--- outcomes:", ys, "\n")
  pr(ec_ipw(F5), outcomes = ys)
  pr(ec_aipw(F5, O(ys)), outcomes = ys)
  set.seed(1); rb <- pr(ec_aipw(F5, O(ys), bootstrap = 30), outcomes = ys)
}
cat("\n## duplicate outcome names\n")
pr(ec_ipw(F5), outcomes = c("y1", "y1"))
cat("\n## missing values\n")
dn <- d; dn$y1[c(1, 3, 250)] <- NA
pr(ec_ipw(F5), data = dn)
pr(ec_aipw(F5, O5), data = dn)
set.seed(1); pr(ec_ipw(F5, bootstrap = 30), data = dn)
dx <- d; dx$x4[c(2, 250)] <- NA
pr(ec_ipw(F5), data = dx)
pr(ec_aipw(F5, O5), data = dx)
dsn <- d; dsn$S[5] <- NA
pr(ec_ipw(F5), data = dsn)
dan <- d; dan$A[5] <- NA
pr(ec_ipw(F5), data = dan)
cat("\n## run_analysis wrong input\n")
w(run_analysis(ec_ipw(F5)))
w(run_analysis(list()))
w(run_analysis(mk(ec_ipw(F5)), quiet = NA))
w(run_analysis(mk(ec_ipw(F5)), quiet = "yes"))
cat("\n## setup_analysis_primary wrong method objects\n")
w(mk(did_ec_ipw(ps_formula = F5)))
w(mk("ec_ipw"))
cat("\n## CI ordering & names, many configs\n")
cfg <- list(ec_ipw(F5), ec_ipw(F5, weight = 0), ec_ipw(F5, weight = 1), ec_aipw(F5, O5), ec_aipw(F5, O5, weight = 1))
for (m in cfg) {
  r <- run_analysis(mk(m))
  cat(m@method_name, "names:", names(r), "| cols:", names(r$results), "| rows:", rownames(r$results),
      "| lower<=pe<=upper:", all(r$results[[3]] <= r$results$point_estimates & r$results$point_estimates <= r$results[[4]]), "\n")
}
