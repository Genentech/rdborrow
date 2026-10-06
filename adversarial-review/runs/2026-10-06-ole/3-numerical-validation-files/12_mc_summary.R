N3 <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3"
truth <- c(`3` = 1.875, `4` = 2.5)
s4bias <- c(`3` = 0.30, `4` = 0.54)
if (file.exists(file.path(N3, "10_mc_did.rds"))) {
  r <- readRDS(file.path(N3, "10_mc_did.rds"))
  r$truth <- truth[as.character(r$t)]
  r$cover <- r$lo <= r$truth & r$truth <= r$hi
  r$width <- r$hi - r$lo
  cat("max |pkg - independent| over all DID replicates:", max(abs(r$est - r$ind), na.rm = TRUE), "\n")
  cat("non-finite estimates or CIs:", sum(!is.finite(r$est) | !is.finite(r$lo) | !is.finite(r$hi)), "\n")
  key <- unique(r[, c("setting", "method", "t")])
  tab <- do.call(rbind, lapply(seq_len(nrow(key)), function(k) {
    x <- merge(r, key[k, ])
    R <- nrow(x)
    bias <- mean(x$est) - x$truth[1]
    sdv <- sd(x$est)
    cov <- mean(x$cover)
    exp_bias <- if (key$setting[k] == "S4") s4bias[as.character(key$t[k])] else 0
    data.frame(key[k, ], R = R,
      bias = round(bias, 4), mcse_bias = round(sdv / sqrt(R), 4),
      exp_bias = exp_bias,
      z_bias = round((bias - exp_bias) / (sdv / sqrt(R)), 2),
      emp_sd = round(sdv, 4),
      se_proxy_ratio = round(mean(x$width / 3.92) / sdv, 3),
      coverage = round(100 * cov, 1), mcse_cov = round(100 * sqrt(cov * (1 - cov) / R), 1),
      width = round(mean(x$width), 3)
    )
  }))
  rownames(tab) <- NULL
  print(tab[order(tab$setting, tab$method, tab$t), ], row.names = FALSE)
  cat("mean n1, n0, m:", colMeans(unique(r[, c("setting", "rep", "n1", "n0", "m")])[, 3:5]), "\n")
}
if (file.exists(file.path(N3, "11_mc_scm.rds"))) {
  s <- readRDS(file.path(N3, "11_mc_scm.rds"))
  s$truth <- truth[as.character(s$t)]
  cat("\nSCM\n")
  key <- unique(s[, c("setting", "t")])
  tab <- do.call(rbind, lapply(seq_len(nrow(key)), function(k) {
    x <- merge(s, key[k, ])
    R <- nrow(x)
    f <- function(v) c(round(mean(v) - x$truth[1], 4), round(sd(v) / sqrt(R), 4), round(sd(v), 4))
    data.frame(key[k, ], R = R,
      pkg_bias = f(x$pkg)[1], pkg_mcse = f(x$pkg)[2], pkg_sd = f(x$pkg)[3],
      ind_bias = f(x$ind)[1], ind_mcse = f(x$ind)[2],
      max_abs_pkg_minus_ind = round(max(abs(x$pkg - x$ind)), 4),
      share_ind_lambda0 = mean(x$ind_lambda == 0),
      std_bias = f(x$ind_std)[1], std_mcse = f(x$ind_std)[2], std_sd = f(x$ind_std)[3]
    )
  }))
  print(tab, row.names = FALSE)
}
