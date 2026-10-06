source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
library(parallel)
RNGkind("L'Ecuyer-CMRG")
covs <- c("x1", "x1sq", "x2")
ys <- c("y1", "y2")
cells <- list(
  i = list(ps = "S ~ x1 + x2", out = c("y1 ~ x1 + x1sq + x2", "y2 ~ x1 + x1sq + x2")),
  ii = list(ps = "S ~ x1 + x1sq + x2", out = c("y1 ~ x1 + x2", "y2 ~ x1 + x2")),
  iii = list(ps = "S ~ x1 + x2", out = c("y1 ~ x1 + x2", "y2 ~ x1 + x2"))
)
one <- function() {
  d <- sim_scenario_dr(1200)
  rows <- list()
  for (cn in names(cells)) {
    for (meth in c("ipw", "aipw")) {
      for (wn in c("w05", "wopt")) {
        w <- if (wn == "w05") 0.5 else NULL
        m <- if (meth == "ipw") {
          ec_ipw(cells[[cn]]$ps, weight = w)
        } else {
          ec_aipw(cells[[cn]]$ps, cells[[cn]]$out, weight = w)
        }
        r <- estimate(m, data = d, outcomes = ys, treatment = "A", trial_status = "S", covariates = covs)
        rows[[length(rows) + 1]] <- data.frame(
          cell = cn, meth = meth, wn = wn, t = 1:2,
          tau = r$results$point_estimates, lo = r$results$lower_CI_normal,
          hi = r$results$upper_CI_normal, w = r$borrow_weight
        )
      }
    }
  }
  do.call(rbind, rows)
}
set.seed(31)
x <- do.call(rbind, mclapply(1:1000, \(i) one(), mc.cores = 8, mc.set.seed = TRUE))
saveRDS(x, "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/mcC.rds")
x$truth <- ifelse(x$t == 1, 1, 2)
key <- interaction(x$cell, x$meth, x$wn, x$t, drop = TRUE, lex.order = TRUE)
s <- do.call(rbind, lapply(split(x, key), \(g) {
  R <- nrow(g)
  data.frame(
    cell = g$cell[1], meth = g$meth[1], w = g$wn[1], t = g$t[1], R = R,
    mean_w = round(mean(g$w), 3), bias = round(mean(g$tau - g$truth), 4),
    mcse = round(sd(g$tau) / sqrt(R), 4),
    z = round(mean(g$tau - g$truth) / (sd(g$tau) / sqrt(R)), 1),
    cover = round(mean(g$lo <= g$truth & g$truth <= g$hi), 3)
  )
}))
rownames(s) <- NULL
options(width = 200)
print(s)
