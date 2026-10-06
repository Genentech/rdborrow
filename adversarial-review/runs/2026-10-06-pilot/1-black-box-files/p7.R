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
cat("## baseline\n"); pr(ec_ipw(F5))
cat("\n## renamed S/A columns, formula uses new name\n")
dr <- d; names(dr)[names(dr) == "S"] <- "in_trial"; names(dr)[names(dr) == "A"] <- "arm"
pr(ec_ipw("in_trial ~ x1 + x2 + x3 + x4 + x5"), data = dr, S = "in_trial", A = "arm")
cat("\n## covariate literally named A (treatment column is 'arm')\n")
dc <- dr; dc$A <- dc$x4; dc$x4 <- NULL
pr(ec_ipw("in_trial ~ x1 + x2 + x3 + A + x5"), data = dc, S = "in_trial", A = "arm", covs = c("x1", "x2", "x3", "A", "x5"))
cat("\n## covariate literally named S (trial column is 'in_trial')\n")
dc2 <- dr; dc2$S <- dc2$x4; dc2$x4 <- NULL
pr(ec_ipw("in_trial ~ x1 + x2 + x3 + S + x5"), data = dc2, S = "in_trial", A = "arm", covs = c("x1", "x2", "x3", "S", "x5"))
cat("\n## outcome named A\n")
do <- dr; do$A <- do$y1
pr(ec_ipw("in_trial ~ x1 + x2 + x3 + x4 + x5"), data = do, S = "in_trial", A = "arm", outcomes = c("A", "y2"))
cat("\n## same column used as outcome and covariate\n")
pr(ec_ipw(F5), outcomes = c("y1", "x5"))
cat("\n## S and A swapped\n")
pr(ec_ipw(F5), S = "A", A = "S")
cat("\n## logical S and A\n")
dl <- d; dl$S <- dl$S == 1; dl$A <- dl$A == 1
pr(ec_ipw(F5), data = dl)
cat("\n## factor S and A\n")
dfa <- d; dfa$S <- factor(dfa$S); dfa$A <- factor(dfa$A)
pr(ec_ipw(F5), data = dfa)
pr(ec_aipw(F5, O5), data = dfa)
cat("\n## 1/2 coded S, A\n")
d12 <- d; d12$S <- d12$S + 1; d12$A <- d12$A + 1
pr(ec_ipw(F5), data = d12)
cat("\n## character S\n")
dch <- d; dch$S <- ifelse(dch$S == 1, "trial", "external")
pr(ec_ipw(F5), data = dch)
cat("\n## external subjects with A = 1\n")
de <- d; de$A[de$S == 0][1:10] <- 1
pr(ec_ipw(F5), data = de)
pr(ec_aipw(F5, O5), data = de)
cat("\n## tibble input\n")
if (requireNamespace("tibble", quietly = TRUE)) pr(ec_ipw(F5), data = tibble::as_tibble(d))
cat("\n## matrix input\n")
w(mk(ec_ipw(F5), data = as.matrix(d)))
