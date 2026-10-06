source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
d <- SyntheticData
covs <- c("x1", "x2", "x3", "x4", "x5")
ys <- c("y1", "y2", "y3", "y4")
Xps <- ind_design(d, covs)

cat("\n== bootstrap re-estimating w-hat in each resample vs holding it fixed ==\n")
stat_fixed <- function(dd, i, wt) {
  x <- dd[i, ]
  ind_ec(x, ys[1], ind_design(x, covs), w = wt)$tau
}
stat_reest <- function(dd, i) {
  x <- dd[i, ]
  ind_ec(x, ys[1], ind_design(x, covs))$tau
}
w_hat <- ind_ec(d, ys[1], Xps)$w
set.seed(5)
b1 <- boot::boot(d, stat_fixed, R = 2000, strata = 2 * d$S + d$A, wt = w_hat)
set.seed(5)
b2 <- boot::boot(d, stat_reest, R = 2000, strata = 2 * d$S + d$A)
cat(sprintf("EC-IPW y1: boot SD with w fixed = %.4f, with w re-estimated = %.4f\n", sd(b1$t), sd(b2$t)))
