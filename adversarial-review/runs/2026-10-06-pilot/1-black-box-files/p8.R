source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
d <- SyntheticData
pr <- function(m, ...) {
  rr <- w(run_analysis(mk(m, ...)))
  if (!is.null(rr)) print(c(rr$results$point_estimates, bw = rr$borrow_weight))
  invisible(rr)
}
dS <- d; names(dS)[names(dS) == "S"] <- "in_trial"
dA <- d; names(dA)[names(dA) == "A"] <- "arm"
cat("## only S renamed: formula LHS in_trial\n")
pr(ec_ipw("in_trial ~ x1 + x2 + x3 + x4 + x5"), data = dS, S = "in_trial")
cat("## only S renamed: formula LHS S\n")
pr(ec_ipw(F5), data = dS, S = "in_trial")
cat("## only S renamed: AIPW\n")
pr(ec_aipw(F5, O5), data = dS, S = "in_trial")
pr(ec_aipw("in_trial ~ x1 + x2 + x3 + x4 + x5", O5), data = dS, S = "in_trial")
cat("## only A renamed\n")
pr(ec_ipw(F5), data = dA, A = "arm")
pr(ec_aipw(F5, O5), data = dA, A = "arm")
cat("## only S renamed, with bootstrap\n")
set.seed(1); pr(ec_ipw(F5, bootstrap = 20), data = dS, S = "in_trial")
cat("## covariate named A (treatment renamed to arm)\n")
dc <- dA; dc$A <- dc$x4; dc$x4 <- NULL
pr(ec_ipw("S ~ x1 + x2 + x3 + A + x5"), data = dc, A = "arm", covs = c("x1", "x2", "x3", "A", "x5"))
pr(ec_aipw("S ~ x1 + x2 + x3 + A + x5", c("y1 ~ x1 + A", "y2 ~ x1 + A")), data = dc, A = "arm", covs = c("x1", "x2", "x3", "A", "x5"))
cat("## reference: same data with covariate called x4\n")
pr(ec_ipw(F5), data = dA, A = "arm")
pr(ec_aipw(F5, c("y1 ~ x1 + x4", "y2 ~ x1 + x4")), data = dA, A = "arm")
cat("## outcome column named S (trial col renamed)\n")
do <- dS; do$S <- do$y1
pr(ec_ipw(F5), data = do, S = "in_trial", outcomes = c("S", "y2"))
pr(ec_ipw(F5), data = dS, S = "in_trial", outcomes = c("y1", "y2"))
