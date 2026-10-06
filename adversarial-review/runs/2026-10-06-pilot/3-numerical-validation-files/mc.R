source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
library(parallel)
RNGkind("L'Ecuyer-CMRG")
out_dir <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3"

args <- commandArgs(trailingOnly = TRUE)
which_mc <- args[1]

covs <- c("x1", "x1sq", "x2")
ps_f <- "S ~ x1 + x1sq + x2"
out_f <- c("y1 ~ x1 + x1sq + x2", "y2 ~ x1 + x1sq + x2")
ys <- c("y1", "y2")
weights <- list(w0 = 0, wopt = NULL, w05 = 0.5, w1 = 1)

one_rep <- function(N, direct = 0, boot = NULL) {
  d <- sim_scenario_a(N)
  if (direct != 0) {
    d$y1 <- d$y1 + direct * d$S
    d$y2 <- d$y2 + direct * d$S
  }
  Xd <- ind_design(d, covs)
  rows <- list()
  for (meth in c("ipw", "aipw")) {
    for (wn in names(weights)) {
      if (!is.null(boot) && !(wn %in% c("wopt", "w05"))) next
      w <- weights[[wn]]
      m <- if (meth == "ipw") {
        ec_ipw(ps_f, weight = w, bootstrap = boot)
      } else {
        ec_aipw(ps_f, out_f, weight = w, bootstrap = boot)
      }
      r <- estimate(m, data = d, outcomes = ys, treatment = "A", trial_status = "S", covariates = covs)
      res <- r$results
      f <- ind_ec(d, ys, Xd, Xd, aipw = meth == "aipw", w = w)
      s <- ind_sandwich(f, d, ys, Xd, Xd, aipw = meth == "aipw")
      dim0 <- if (meth == "ipw" && wn == "w0") max(abs(ind_dim(d, ys)$tau - res$point_estimates)) else NA
      lo <- if (is.null(boot)) res$lower_CI_normal else res$lower_CI_boot
      hi <- if (is.null(boot)) res$upper_CI_normal else res$upper_CI_boot
      rows[[length(rows) + 1]] <- data.frame(
        meth = meth, wn = wn, t = 1:2, tau = res$point_estimates,
        se = res$standard_deviation, lo = lo, hi = hi,
        w = r$borrow_weight, tau_ind = f$tau, se_full = s$se_full,
        se_paper = s$se_paper, dim0 = dim0
      )
    }
  }
  do.call(rbind, rows)
}

run_mc <- function(R, N, seed, direct = 0, boot = NULL, cores = 8) {
  set.seed(seed)
  res <- mclapply(seq_len(R), \(i) cbind(rep = i, one_rep(N, direct, boot)),
    mc.cores = cores, mc.set.seed = TRUE
  )
  bad <- vapply(res, \(x) inherits(x, "try-error"), logical(1))
  if (any(bad)) stop("failed reps: ", sum(bad), "\n", res[[which(bad)[1]]])
  do.call(rbind, res)
}

if (which_mc == "A") {
  for (N in c(300, 1200)) {
    t0 <- Sys.time()
    x <- run_mc(2000, N, seed = 101 + N)
    saveRDS(x, file.path(out_dir, sprintf("mcA_N%d.rds", N)))
    cat("MC-A N =", N, "done in", format(Sys.time() - t0), "\n")
  }
}
if (which_mc == "B") {
  x <- run_mc(1000, 300, seed = 7, direct = 0.5)
  saveRDS(x, file.path(out_dir, "mcB_N300.rds"))
  cat("MC-B done\n")
}
if (which_mc == "boot") {
  t0 <- Sys.time()
  x <- run_mc(400, 300, seed = 2026, boot = 199L, cores = 10)
  saveRDS(x, file.path(out_dir, "mcboot_N300.rds"))
  cat("MC-boot done in", format(Sys.time() - t0), "\n")
}
