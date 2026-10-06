# Independent implementation of the OLE estimators of
# Zhou, Pang, Drake, Burger, Zhu (2024), J Biopharm Stat 34(6):893-921.
# Written from the paper (Sec 3.1 Eqs 3-5, Appendix B, Sec 3.2 Eqs 7-9,
# Remark 4) without calling any rdborrow helper.
#
# Data convention: a data.frame with columns S (1 = trial, 0 = external),
# A (trial arm; 0 for externals), outcome columns `outs` (Period I first,
# then Period II), covariates `covs`. Tc = number of Period I visits (T1).
#
# Nuisance models (all linear in the covariates, with intercept, unless a
# design-matrix function is supplied):
#   pi_S(X)  : logistic regression of S on X, all patients (own Newton fit)
#   pi_A(X)  : marginal n1/n, or logistic regression of A on X in the trial
#   mu(X,s,a,t): OLS of Y_t on X, in the relevant group (own normal eqs)

# nuisance fitters ----
ind_design <- function(d, covs) cbind(1, as.matrix(d[, covs, drop = FALSE]))

ind_ols <- function(X, y) {
  drop(solve(crossprod(X), crossprod(X, y)))
}

ind_logit <- function(X, y, tol = 1e-12, maxit = 100) {
  b <- rep(0, ncol(X))
  for (i in seq_len(maxit)) {
    eta <- drop(X %*% b)
    p <- 1 / (1 + exp(-eta))
    W <- p * (1 - p)
    step <- solve(crossprod(X * W, X), crossprod(X, y - p))
    b <- b + drop(step)
    if (max(abs(step)) < tol) break
  }
  b
}

# DID-EC-OR, Appendix B (p. 916) ----
# tau_t = 1/n sum_{i in R} [ mu(X_i,1,(1,1),t) - mubar(X_i,1,A1=0,T1)
#                           - (mu(X_i,0,(0,0),t) - mubar(X_i,0,(0,0),T1)) ]
ind_did_or <- function(d, outs, Tc, covs, design = ind_design) {
  R <- d$S == 1
  trt <- d$S == 1 & d$A == 1
  ctl <- d$S == 1 & d$A == 0
  ext <- d$S == 0
  XR <- design(d[R, ], covs)
  pred <- function(rows, y) {
    b <- ind_ols(design(d[rows, ], covs), d[rows, y])
    drop(XR %*% b)
  }
  per1 <- outs[seq_len(Tc)]
  per2 <- outs[-seq_len(Tc)]
  mu10_bar <- rowMeans(sapply(per1, \(y) pred(ctl, y)))
  mu00_bar <- rowMeans(sapply(per1, \(y) pred(ext, y)))
  vapply(per2, function(y) {
    mean((pred(trt, y) - mu10_bar) - (pred(ext, y) - mu00_bar))
  }, numeric(1))
}

# weights shared by IPW and AIPW ----
ind_weights <- function(d, covs, trt_covs = NULL, design = ind_design) {
  R <- d$S == 1
  bS <- ind_logit(design(d, covs), d$S)
  eta <- drop(design(d, covs) %*% bS)
  # W0(X) = p_R(X)/p_E(X) = odds(pi_S(X)) * (1 - pi_S)/pi_S; the constant
  # cancels after normalization, kept for completeness
  piS <- mean(d$S)
  W0 <- exp(eta) * (1 - piS) / piS
  if (is.null(trt_covs)) {
    piA <- rep(mean(d$A[R]), nrow(d))
  } else {
    bA <- ind_logit(design(d[R, ], trt_covs), d$A[R])
    piA <- 1 / (1 + exp(-drop(design(d, trt_covs) %*% bA)))
  }
  list(W0 = W0, W11 = 1 / piA, W10 = 1 / (1 - piA))
}

# generic DID weighting formula of Appendix B; Ymat may be raw outcomes
# (IPW) or residuals from the external-control outcome model (AIPW)
ind_did_weighting <- function(d, Ymat, Tc, w) {
  R <- d$S == 1
  E <- d$S == 0
  A <- d$A
  per2 <- seq_len(ncol(Ymat))[-seq_len(Tc)]
  ybar1 <- rowMeans(Ymat[, seq_len(Tc), drop = FALSE])
  a1 <- R & A == 1
  a0 <- R & A == 0
  out <- numeric(length(per2))
  for (k in seq_along(per2)) {
    yt <- Ymat[, per2[k]]
    d_trial <- sum(w$W11[a1] * yt[a1]) / sum(w$W11[a1]) -
      sum(w$W10[a0] * ybar1[a0]) / sum(w$W10[a0])
    d_ec <- sum(w$W0[E] * (yt[E] - ybar1[E])) / sum(w$W0[E])
    out[k] <- d_trial - d_ec
  }
  names(out) <- colnames(Ymat)[per2]
  out
}

# DID-EC-IPW, Appendix B ----
ind_did_ipw <- function(d, outs, Tc, covs, trt_covs = NULL,
                        design = ind_design) {
  w <- ind_weights(d, covs, trt_covs, design)
  ind_did_weighting(d, as.matrix(d[, outs]), Tc, w)
}

# DID-EC-AIPW, Appendix B: residuals Y_t - mu(X, S=0, (0,0), t) ----
ind_did_aipw <- function(d, outs, Tc, covs, trt_covs = NULL,
                         out_covs = covs, design = ind_design) {
  w <- ind_weights(d, covs, trt_covs, design)
  E <- d$S == 0
  Xall <- design(d, out_covs)
  res <- sapply(outs, function(y) {
    b <- ind_ols(design(d[E, ], out_covs), d[E, y])
    d[, y] - drop(Xall %*% b)
  })
  ind_did_weighting(d, res, Tc, w)
}

# SCM, Eqs 7-9 and Remark 4 ----
# Eq 7: min_w ||z_i - Z w||^2 + lambda sum_j w_j ||z_i - z_j||^2,
#       w >= 0, sum w = 1, z = (X, Y_1..Y_T1).
# Written as the QP  min 1/2 w'Pw + q'w  with P = 2 Z'Z,
#   q = -2 Z'z_i + lambda * dist, solved by OSQP (not the ECOS/CVXR path
#   used in the package).
ind_sc_weights <- function(zi, Z, lambda) {
  m <- ncol(Z)
  dist <- colSums((Z - zi)^2)
  P <- 2 * crossprod(Z)
  q <- -2 * drop(crossprod(Z, zi)) + lambda * dist
  Acon <- rbind(rep(1, m), diag(m))
  l <- c(1, rep(0, m))
  u <- c(1, rep(Inf, m))
  sol <- osqp::solve_osqp(
    P = Matrix::Matrix(P, sparse = TRUE), q = q,
    A = Matrix::Matrix(Acon, sparse = TRUE), l = l, u = u,
    pars = osqp::osqpSettings(
      verbose = FALSE, eps_abs = 1e-10, eps_rel = 1e-10,
      max_iter = 200000L, polishing = TRUE
    )
  )
  w <- pmax(sol$x, 0)
  w / sum(w)
}

ind_sc_objective <- function(w, zi, Z, lambda) {
  sum((zi - drop(Z %*% w))^2) + lambda * sum(w * colSums((Z - zi)^2))
}

# Remark 4: leave-one-out over external controls, squared error summed
# over Period II visits and patients
ind_scm_lambda <- function(d, outs, Tc, covs, grid) {
  E <- which(d$S == 0)
  Z <- t(as.matrix(d[E, c(covs, outs[seq_len(Tc)])]))
  Y2 <- t(as.matrix(d[E, outs[-seq_len(Tc)], drop = FALSE]))
  sse <- vapply(grid, function(lam) {
    s <- 0
    for (k in seq_along(E)) {
      w <- ind_sc_weights(Z[, k], Z[, -k, drop = FALSE], lam)
      s <- s + sum((Y2[, k] - drop(Y2[, -k, drop = FALSE] %*% w))^2)
    }
    s
  }, numeric(1))
  list(lambda = grid[which.min(sse)], sse = sse)
}

# Eqs 8-9
ind_scm <- function(d, outs, Tc, covs, lambda) {
  E <- which(d$S == 0)
  C <- which(d$S == 1 & d$A == 0)
  Tr <- which(d$S == 1 & d$A == 1)
  per2 <- outs[-seq_len(Tc)]
  Z <- t(as.matrix(d[E, c(covs, outs[seq_len(Tc)])]))
  Y2 <- t(as.matrix(d[E, per2, drop = FALSE]))
  W <- sapply(C, function(i) {
    ind_sc_weights(unlist(d[i, c(covs, outs[seq_len(Tc)])]), Z, lambda)
  })
  yhat <- t(Y2 %*% W)
  tau <- colMeans(d[Tr, per2, drop = FALSE]) - colMeans(yhat)
  list(tau = tau, W = W, yhat = yhat)
}
