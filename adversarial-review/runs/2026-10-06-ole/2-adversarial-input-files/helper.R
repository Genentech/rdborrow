# shared helper for the r2 adversarial scripts----
# load the installed copy of the review commit (6185ba9)
.libPaths(c(
  "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib",
  .libPaths()
))
suppressPackageStartupMessages(library(rdborrow))
ns <- asNamespace("rdborrow")

# linear-factor DGP of Zhou et al. (2024) Eq. 2 with a constant study effect
# n1 treated, n0 trial controls (cross over after T1), m external controls.
# true effect tau_t = 0.5 * t for t > T1 (period II), study bias delta_s.
make_ole <- function(n1 = 60, n0 = 30, m = 40, T1 = 2, T2 = 4, seed = 1,
                     delta_s = 1, ec_shift = 0.5, tau = NULL) {
  set.seed(seed)
  N <- n1 + n0 + m
  S <- c(rep(1, n1 + n0), rep(0, m))
  A <- c(rep(1, n1), rep(0, n0), rep(0, m))
  x1 <- rnorm(N, mean = ifelse(S == 1, 0, ec_shift))
  x2 <- rbinom(N, 1, 0.5)
  x3 <- rnorm(N)
  if (is.null(tau)) tau <- 0.5 * seq_len(T2)
  Y <- sapply(seq_len(T2), \(t) {
    trt <- if (t <= T1) A else as.numeric(S == 1)
    0.3 * t + x1 + 0.5 * x2 - 0.5 * x3 + delta_s * S +
      ifelse(A == 1, tau[t], 0) +
      ifelse(S == 1 & A == 0 & t > T1, 0.7 * tau[t], 0) +
      rnorm(N, sd = 0.5)
  })
  colnames(Y) <- paste0("y", seq_len(T2))
  data.frame(x1 = x1, x2 = x2, x3 = x3, A = A, S = S, Y)
}

ycols <- function(T2 = 4) paste0("y", seq_len(T2))

forms <- function(T2 = 4, rhs = "x1 + x2 + x3") {
  paste0("y", seq_len(T2), " ~ ", rhs)
}

m_ipw <- function(B = 20, ...) {
  did_ec_ipw(ps_formula = "S ~ x1 + x2 + x3", bootstrap = B, ...)
}
m_aipw <- function(B = 20, T2 = 4, ...) {
  did_ec_aipw(
    ps_formula = "S ~ x1 + x2 + x3", outcome_formula = forms(T2),
    bootstrap = B, ...
  )
}
m_or <- function(B = 20, T2 = 4, ...) {
  f <- forms(T2)
  did_ec_or(
    outcome_formula_ext = f, outcome_formula_rct_ctrl = f,
    outcome_formula_rct_trt = f, bootstrap = B, ...
  )
}
m_scm <- function(B = 3, lambda_min = 0.01, lambda_max = 0.01, nlambda = 1,
                  ...) {
  scm(
    lambda_min = lambda_min, lambda_max = lambda_max, nlambda = nlambda,
    bootstrap = B, ...
  )
}

fit <- function(d, method, T_cross = 2, outcomes = ycols(),
                covs = c("x1", "x2", "x3"), seed = 2024) {
  a <- setup_analysis_OLE(
    data = d, trial_status_col_name = "S", treatment_col_name = "A",
    outcome_col_name = outcomes, covariates_col_name = covs,
    method_OLE_obj = method, T_cross = T_cross
  )
  set.seed(seed)
  run_analysis(a)
}

# point estimates only, through the core functions (no bootstrap)
pe <- function(d, which, T_cross = 2, outcomes = ycols(),
               covs = c("x1", "x2", "x3"), lambda = 0.01, ff = NULL) {
  df <- ns$.build_analysis_df(d, outcomes, "A", "S", covs)
  Y <- as.matrix(df[, outcomes, drop = FALSE])
  if (is.null(ff)) ff <- forms(length(outcomes))
  switch(which,
    ipw = ns$.did_ec_ipw_core(df, Y, df$S, df$A, T_cross, "S ~ x1 + x2 + x3", NULL)$tau,
    aipw = ns$.did_ec_aipw_core(df, Y, df$S, df$A, T_cross, "S ~ x1 + x2 + x3", NULL, ff)$tau,
    or = ns$.did_ec_or_core(df, df$S, df$A, T_cross, ff, ff, ff)$tau,
    scm = ns$.scm_boot_statistic(df, seq_len(nrow(df)), outcomes, covs, T_cross, lambda)
  )
}

show_try <- function(expr) {
  ws <- character()
  r <- tryCatch(
    withCallingHandlers(expr, warning = function(w) {
      ws <<- c(ws, conditionMessage(w))
      invokeRestart("muffleWarning")
    }),
    error = function(e) paste("ERROR:", conditionMessage(e))
  )
  if (length(ws)) {
    tab <- table(ws)
    for (k in names(tab)) message(sprintf("  WARNING x%d: %s", tab[[k]], k))
  }
  print(r)
  invisible(r)
}
