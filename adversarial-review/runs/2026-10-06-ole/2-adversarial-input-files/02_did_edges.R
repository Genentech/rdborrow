# edge cases for the DID methods through setup_analysis_OLE() / run_analysis()
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")

d <- make_ole(seed = 1)
all3 <- function(d, T_cross = 2, outcomes = ycols(), B = 20, ...) {
  T2 <- length(outcomes)
  for (nm in c("ipw", "aipw", "or")) {
    cat("--", nm, "\n")
    m <- switch(nm, ipw = m_ipw(B, ...), aipw = m_aipw(B, T2, ...), or = m_or(B, T2, ...))
    show_try(fit(d, m, T_cross = T_cross, outcomes = outcomes))
  }
}

cat("\n=== E1 T_cross = 1 of 4\n"); all3(d, T_cross = 1)
cat("\n=== E2 T_cross = 3 of 4 (one OLE visit)\n"); all3(d, T_cross = 3)
cat("\n=== E3 two visits, T_cross = 1\n")
d2 <- make_ole(T2 = 2, T1 = 1, seed = 1); all3(d2, T_cross = 1, outcomes = ycols(2))
cat("\n=== E4 T_cross = 4 of 4 (rejected?)\n"); show_try(fit(d, m_ipw(), T_cross = 4))

cat("\n=== E5 estimate() called directly with T_cross = 0 and 2.5\n")
for (tc in c(0, 2.5)) {
  set.seed(1)
  show_try(estimate(m_ipw(), data = d, outcomes = ycols(), treatment = "A",
                    trial_status = "S", covariates = c("x1", "x2", "x3"), T_cross = tc))
}

cat("\n=== E6 tiny arms: n1 = 3, n0 = 2, m = 4\n")
d3 <- make_ole(n1 = 3, n0 = 2, m = 4, seed = 3); all3(d3)

cat("\n=== E7 no trial controls (all trial patients A = 1)\n")
d4 <- d; d4$A[d4$S == 1] <- 1; all3(d4)

cat("\n=== E8 no external controls\n")
d5 <- d[d$S == 1, ]; all3(d5)

cat("\n=== E9 very unbalanced: n1 = 200, n0 = 3, m = 300\n")
d6 <- make_ole(n1 = 200, n0 = 3, m = 300, seed = 6); all3(d6)

cat("\n=== E10 bootstrap = 2, each CI type, did_ec_ipw\n")
for (ty in c("perc", "basic", "norm", "bca")) {
  cat("--", ty, "\n"); show_try(fit(d, m_ipw(2, bootstrap_ci_type = ty)))
}

cat("\n=== E11 alpha = 0 and alpha = 1\n")
for (al in c(0, 1)) {
  a <- setup_analysis_OLE(d, "S", "A", ycols(), c("x1", "x2", "x3"), m_ipw(), 2, alpha = al)
  set.seed(1); show_try(run_analysis(a))
}
