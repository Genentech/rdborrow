source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
source(file.path(N3, "dgp.R"))
a <- 1.1883925124
R <- as.integer(Sys.getenv("MC_R", "150"))
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
zvars <- c(covs, outs[1:2])
one_rep <- function(r, setting) {
  set.seed(30261006 + r + 100000 * match(setting, c("S1", "S3", "S4")))
  d <- sim_ole(setting, a)
  pk <- pkg_fit(d, scm(bootstrap = 2), outs, covs, 2)$point_estimates
  cv <- ind_scm_lambda(d, outs, 2, covs, c(0, 0.1))
  ind <- ind_scm(d, outs, 2, covs, cv$lambda)$tau
  dz <- d
  for (v in zvars) dz[[v]] <- d[[v]] / sd(d[d$S == 0, v])
  cvz <- ind_scm_lambda(dz, outs, 2, covs, c(0, 0.01, 0.1, 1))
  indz <- ind_scm(dz, outs, 2, covs, cvz$lambda)$tau
  data.frame(
    setting = setting, rep = r, t = 3:4, pkg = pk, ind = ind,
    ind_lambda = cv$lambda, ind_std = indz, ind_std_lambda = cvz$lambda
  )
}
out <- list()
for (s in c("S1", "S3", "S4")) {
  t0 <- Sys.time()
  out[[s]] <- do.call(rbind, parallel::mclapply(seq_len(R), one_rep,
    setting = s, mc.cores = 22, mc.preschedule = FALSE
  ))
  cat(s, "done in", format(Sys.time() - t0), "\n")
}
saveRDS(do.call(rbind, out), file.path(N3, "11_mc_scm.rds"))
