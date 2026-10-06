source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
source(file.path(N3, "dgp.R"))
a <- 1.1883925124
R <- as.integer(Sys.getenv("MC_R", "400"))
B <- 199L
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
rhs_ok <- "x1 + x2 + x3 + x4 + x2:x4 + x5"
rhs_mis <- "x1 + x2 + x3 + x4 + x5"
f_ok <- paste(outs, "~", rhs_ok)
f_mis <- paste(outs, "~", rhs_mis)
ps_ok <- paste("S ~", rhs_ok)
ps_mis <- paste("S ~", rhs_mis)
methods_base <- list(
  OR = did_ec_or(f_ok, f_ok, f_ok, bootstrap = B),
  IPW = did_ec_ipw(ps_ok, bootstrap = B),
  AIPW = did_ec_aipw(ps_ok, NULL, f_ok, bootstrap = B)
)
methods_mis <- list(
  OR_misOR = did_ec_or(f_mis, f_mis, f_mis, bootstrap = B),
  IPW_misPS = did_ec_ipw(ps_mis, bootstrap = B),
  AIPW_misOR = did_ec_aipw(ps_ok, NULL, f_mis, bootstrap = B),
  AIPW_misPS = did_ec_aipw(ps_mis, NULL, f_ok, bootstrap = B)
)
one_rep <- function(r, setting) {
  set.seed(20261006 + r + 100000 * match(setting, c("S1", "S3", "S4")))
  d <- sim_ole(setting, a)
  ms <- if (setting == "S3") c(methods_base, methods_mis) else methods_base
  do.call(rbind, lapply(names(ms), function(nm) {
    res <- pkg_fit(d, ms[[nm]], outs, covs, 2)
    des <- function(dd, cc) cbind(1, dgp_h(dd$x1, dd$x2, dd$x3, dd$x4, dd$x5))
    ind <- switch(nm,
      OR = ind_did_or(d, outs, 2, covs, design = des),
      IPW = ind_did_ipw(d, outs, 2, covs, design = des),
      AIPW = ind_did_aipw(d, outs, 2, covs, design = des),
      NA
    )
    data.frame(
      setting = setting, rep = r, method = nm, t = 3:4,
      est = res$point_estimates, lo = res$lower_CI_boot, hi = res$upper_CI_boot,
      ind = ind, n1 = sum(d$S == 1 & d$A == 1), n0 = sum(d$S == 1 & d$A == 0),
      m = sum(d$S == 0)
    )
  }))
}
out <- list()
for (s in c("S1", "S3", "S4")) {
  t0 <- Sys.time()
  out[[s]] <- do.call(rbind, parallel::mclapply(seq_len(R), one_rep,
    setting = s,
    mc.cores = 20, mc.preschedule = FALSE
  ))
  cat(s, "done in", format(Sys.time() - t0), "\n")
}
res <- do.call(rbind, out)
saveRDS(res, file.path(N3, "10_mc_did.rds"))
