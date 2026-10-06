# #108 evidence for the OLE methods, and estimate() called directly
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)

cat("=== #108: 10 external controls recoded A = 1, OLE point estimates\n")
d8 <- d
d8$A[which(d8$S == 0)[1:10]] <- 1
for (w in c("ipw", "aipw", "or")) {
  cat(w, ": before", round(pe(d, w), 6), " after", round(pe(d8, w), 6), "\n")
}
cat("scm : before", round(pe(d, "scm"), 6), " after", round(pe(d8, "scm"), 6), "\n")
cat("setup_analysis_OLE accepts it:\n")
show_try(class(setup_analysis_OLE(d8, "S", "A", ycols(), c("x1", "x2", "x3"), m_ipw(), 2)))

cat("\n=== estimate() directly: T_cross = 0, 4, 2.5 (no validation)\n")
for (tc in c(0, 4, 2.5)) {
  cat("-- T_cross =", tc, "\n")
  set.seed(1)
  show_try(estimate(m_or(20), data = d, outcomes = ycols(), treatment = "A",
                    trial_status = "S", covariates = c("x1", "x2", "x3"), T_cross = tc))
}
cat("-- did_ec_ipw, S coded 1/2 (not 0/1) through estimate()\n")
d2 <- d
d2$S <- d2$S + 1
set.seed(1)
show_try(estimate(m_or(20), data = d2, outcomes = ycols(), treatment = "A",
                  trial_status = "S", covariates = c("x1", "x2", "x3"), T_cross = 2))
