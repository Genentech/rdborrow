# Independent base-R implementation of EC-IPW and EC-AIPW
# (Zhou, Zhu, Drake, Pang. JRSS-A 2025;188(3):791-818), written from the
# paper only. It never calls rdborrow code.
#
# - logistic regression: own Newton-Raphson (no glm)
# - linear regression: own normal equations (no lm)
# - weights: Theorem 1 (W11 = 1/pi_A, W10 = 1/(1 - pi_A),
#   W00 = pi_S(X)(1 - pi_S) / ((1 - pi_S(X)) pi_S))
# - point estimates: Definition 1 (Eq 6) and Definition 2 (Eq 7)
# - optimal weight: Eq 11
# - sandwich: Theorems 3 and 4. The stacked estimating functions Psi are
#   coded directly from the theorems; the bread A = E[dPsi/dtheta] is
#   obtained by central finite differences, NOT from the analytic blocks
#   in Eq 12 / Eq 15, so it independently checks those blocks.
#   Two variance summaries are returned:
#     var_full  = c' Sigma c / N with c = (I, -(1-w) I, -w I, 0), i.e. the
#                 delta method applied to the whole Sigma (all covariances)
#     var_paper = (Sigma11 + (1-w)^2 Sigma22 + w^2 Sigma33) / N, the
#                 formula exactly as printed in Eq 13 / Eq 16

# nuisance models----
ind_logit <- function(X, y, tol = 1e-12, maxit = 100) {
  b <- rep(0, ncol(X))
  for (i in seq_len(maxit)) {
    p <- 1 / (1 + exp(-drop(X %*% b)))
    g <- crossprod(X, y - p)
    H <- crossprod(X * (p * (1 - p)), X)
    step <- solve(H, g)
    b <- b + drop(step)
    if (max(abs(step)) < tol) break
  }
  b
}

ind_ols <- function(X, y) drop(solve(crossprod(X), crossprod(X, y)))

# design matrices from plain column names (intercept + main effects)----
ind_design <- function(data, cols) cbind(1, as.matrix(data[, cols, drop = FALSE]))

# point estimate----
# data: data frame with S, A, outcome columns `ycols`
# Xps: N x p PS design; Xout: N x q outcome design (same for every time),
# or a list with one N x q_t design per time point
# aipw: FALSE for EC-IPW, TRUE for EC-AIPW
# w: NULL for Eq 11 optimal weight, else fixed weight in [0, 1]
ind_ec <- function(data, ycols, Xps, Xout = NULL, aipw = FALSE, w = NULL) {
  S <- data$S
  A <- data$A
  Y <- as.matrix(data[, ycols, drop = FALSE])
  N <- length(S)
  n <- sum(S)
  pi_S <- n / N
  pi_A <- sum(S * A) / n

  alpha <- ind_logit(Xps, S)
  pi_SX <- 1 / (1 + exp(-drop(Xps %*% alpha)))
  W00 <- pi_SX / (1 - pi_SX) * (1 - pi_S) / pi_S
  W11 <- rep(1 / pi_A, N)
  W10 <- rep(1 / (1 - pi_A), N)

  beta <- NULL
  Yt <- Y
  if (aipw) {
    if (!is.list(Xout)) Xout <- rep(list(Xout), ncol(Y))
    ctrl <- A == 0
    beta <- lapply(seq_len(ncol(Y)), \(t) ind_ols(Xout[[t]][ctrl, , drop = FALSE], Y[ctrl, t]))
    mu_X <- vapply(seq_len(ncol(Y)), \(t) drop(Xout[[t]] %*% beta[[t]]), numeric(N))
    Yt <- Y - mu_X
  }

  i11 <- S == 1 & A == 1
  i10 <- S == 1 & A == 0
  i00 <- S == 0
  mu11 <- colSums(Yt[i11, , drop = FALSE] * W11[i11]) / sum(W11[i11])
  mu10 <- colSums(Yt[i10, , drop = FALSE] * W10[i10]) / sum(W10[i10])
  mu00 <- colSums(Yt[i00, , drop = FALSE] * W00[i00]) / sum(W00[i00])

  # Eq 11
  r10 <- sum(S * (1 - A) * W10^2) / sum(S * (1 - A) * W10)^2
  r00 <- sum((1 - S) * W00^2) / sum((1 - S) * W00)^2
  w_opt <- r10 / (r10 + r00)
  if (is.null(w)) w <- w_opt

  tau <- mu11 - ((1 - w) * mu10 + w * mu00)
  list(
    tau = tau, w = w, w_opt = w_opt, mu11 = mu11, mu10 = mu10, mu00 = mu00,
    alpha = alpha, beta = beta, W00 = W00, pi_S = pi_S, pi_A = pi_A
  )
}

# stacked estimating functions (Theorem 3 / Theorem 4)----
# returns an N x k matrix; columns ordered (mu11, mu10, mu00, alpha, beta_1, ..., beta_T)
ind_psi <- function(theta, data, ycols, Xps, Xout, aipw, pi_S, pi_A) {
  S <- data$S
  A <- data$A
  Y <- as.matrix(data[, ycols, drop = FALSE])
  nt <- ncol(Y)
  p <- ncol(Xps)
  mu11 <- theta[seq_len(nt)]
  mu10 <- theta[nt + seq_len(nt)]
  mu00 <- theta[2 * nt + seq_len(nt)]
  alpha <- theta[3 * nt + seq_len(p)]
  e <- drop(exp(Xps %*% alpha))
  pi_SX <- e / (1 + e)
  W00 <- pi_SX / (1 - pi_SX) * (1 - pi_S) / pi_S
  Yt <- Y
  out5 <- NULL
  if (aipw) {
    if (!is.list(Xout)) Xout <- rep(list(Xout), nt)
    off <- 3 * nt + p
    out5 <- list()
    for (t in seq_len(nt)) {
      q <- ncol(Xout[[t]])
      b <- theta[off + seq_len(q)]
      off <- off + q
      r <- Y[, t] - drop(Xout[[t]] %*% b)
      Yt[, t] <- r
      out5[[t]] <- (1 - A) / (1 - pi_A) * r * Xout[[t]]
    }
    out5 <- do.call(cbind, out5)
  }
  psi1 <- S * A * sweep(Yt, 2, mu11) / (pi_S * pi_A)
  psi2 <- S * (1 - A) * sweep(Yt, 2, mu10) / (pi_S * (1 - pi_A))
  psi3 <- (1 - S) * W00 * sweep(Yt, 2, mu00) / (1 - pi_S)
  psi4 <- (S - pi_SX) * Xps
  cbind(psi1, psi2, psi3, psi4, out5)
}

ind_sandwich <- function(fit, data, ycols, Xps, Xout = NULL, aipw = FALSE, h = 1e-6) {
  nt <- length(ycols)
  N <- nrow(data)
  theta <- c(fit$mu11, fit$mu10, fit$mu00, fit$alpha, unlist(fit$beta))
  args <- list(
    data = data, ycols = ycols, Xps = Xps, Xout = Xout, aipw = aipw,
    pi_S = fit$pi_S, pi_A = fit$pi_A
  )
  psi_at <- function(th) do.call(ind_psi, c(list(th), args))
  psi_hat <- psi_at(theta)
  k <- length(theta)
  Amat <- matrix(0, k, k)
  for (j in seq_len(k)) {
    hp <- theta
    hm <- theta
    step <- h * max(1, abs(theta[j]))
    hp[j] <- hp[j] + step
    hm[j] <- hm[j] - step
    Amat[, j] <- (colMeans(psi_at(hp)) - colMeans(psi_at(hm))) / (2 * step)
  }
  Bmat <- crossprod(psi_hat) / N
  Ainv <- solve(Amat)
  Sigma <- Ainv %*% Bmat %*% t(Ainv)
  w <- fit$w
  I <- diag(nt)
  cvec <- cbind(I, -(1 - w) * I, -w * I, matrix(0, nt, k - 3 * nt))
  var_full <- diag(cvec %*% Sigma %*% t(cvec)) / N
  idx <- function(b) (b - 1) * nt + seq_len(nt)
  s11 <- diag(Sigma[idx(1), idx(1), drop = FALSE])
  s22 <- diag(Sigma[idx(2), idx(2), drop = FALSE])
  s33 <- diag(Sigma[idx(3), idx(3), drop = FALSE])
  var_paper <- (s11 + (1 - w)^2 * s22 + w^2 * s33) / N
  list(
    se_full = sqrt(var_full), se_paper = sqrt(var_paper),
    A = Amat, B = Bmat, Sigma = Sigma, psi_mean = colMeans(psi_hat)
  )
}

# trial-only difference in means (w = 0 EC-IPW reference), MLE-type variance----
ind_dim <- function(data, ycols) {
  Y <- as.matrix(data[, ycols, drop = FALSE])
  t1 <- data$S == 1 & data$A == 1
  t0 <- data$S == 1 & data$A == 0
  v <- function(z) mean((z - mean(z))^2)
  list(
    tau = colMeans(Y[t1, , drop = FALSE]) - colMeans(Y[t0, , drop = FALSE]),
    se = sqrt(apply(Y[t1, , drop = FALSE], 2, v) / sum(t1) +
      apply(Y[t0, , drop = FALSE], 2, v) / sum(t0))
  )
}

# hand-checkable fixture----
# binary x, saturated PS model, so pi_S(x) is the empirical proportion:
#   x = 0: 2 trial, 2 external -> pi_S(0) = 1/2
#   x = 1: 3 trial, 1 external -> pi_S(1) = 3/4
#   pi_S = 5/8, W00(x) = odds(x) * (3/8)/(5/8) -> W00(0) = 0.6, W00(1) = 1.8
#   externals x = (0, 0, 1): W00 = (0.6, 0.6, 1.8), sum 3, sum of squares 3.96
#   Eq 11: (1/2) / (1/2 + 3.96/9) = 0.5 / 0.94 = 25/47
#   mu11 = mean(5, 7, 9) = 7; mu10 = mean(2, 4) = 3;
#   mu00 = (0.6*1 + 0.6*3 + 1.8*6) / 3 = 4.4
#   tau(w) = 7 - (1 - w) * 3 - w * 4.4 = 4 - 1.4 w; tau(25/47) = 153/47
hand_fixture <- function() {
  data.frame(
    S = c(1, 1, 1, 1, 1, 0, 0, 0),
    A = c(1, 1, 1, 0, 0, 0, 0, 0),
    x = c(0, 1, 1, 0, 1, 0, 0, 1),
    y1 = c(5, 7, 9, 2, 4, 1, 3, 6),
    y2 = c(5, 7, 9, 2, 4, 1, 3, 6) * 2
  )
}

hand_expected <- list(
  w_opt = 25 / 47,
  tau_opt = 4 - 1.4 * 25 / 47,
  tau_w0 = 4,
  tau_w05 = 3.3,
  W00_ext = c(0.6, 0.6, 1.8)
)

# data-generating process for the Monte Carlo (pre-registered)----
# Supplement Table 1, Scenario A (no assumption violated, both models
# correctly specified), with the unstated details fixed as:
#   X1, X2 ~ iid N(0, 1)
#   S ~ Bernoulli(expit(log 2 + 0.1 X1 + 0.1 X1^2 + 0.1 X2))
#   A | S = 1 ~ complete randomization with exactly round(2/3 n) treated;
#   A = 0 if S = 0
#   Y_t(0) = 0.5 X1 + 0.5 X1^2 + 0.5 X2 + e_t, t = 1, 2,
#   (e_1, e_2) ~ N(0, [[1, 0.5], [0.5, 1]])
#   Y_t(1) = Y_t(0) + tau_t, tau = (1, 2)
# Covariates for the models: X1, X1sq, X2.
sim_scenario_a <- function(N = 600, tau = c(1, 2)) {
  x1 <- rnorm(N)
  x2 <- rnorm(N)
  pS <- 1 / (1 + exp(-(log(2) + 0.1 * x1 + 0.1 * x1^2 + 0.1 * x2)))
  S <- rbinom(N, 1, pS)
  n <- sum(S)
  A <- numeric(N)
  A[S == 1] <- sample(rep(c(1, 0), c(round(2 / 3 * n), n - round(2 / 3 * n))))
  mu <- 0.5 * x1 + 0.5 * x1^2 + 0.5 * x2
  e1 <- rnorm(N)
  e2 <- 0.5 * e1 + sqrt(0.75) * rnorm(N)
  data.frame(
    x1 = x1, x1sq = x1^2, x2 = x2, S = S, A = A,
    y1 = mu + e1 + A * tau[1], y2 = mu + e2 + A * tau[2]
  )
}

# DGP for the double-robustness Monte Carlo (MC-C)----
sim_scenario_dr <- function(N = 1200, tau = c(1, 2)) {
  x1 <- rnorm(N)
  x2 <- rnorm(N)
  pS <- 1 / (1 + exp(-(0.5 + 0.5 * x1 - 0.5 * x1^2 + 0.3 * x2)))
  S <- rbinom(N, 1, pS)
  n <- sum(S)
  A <- numeric(N)
  A[S == 1] <- sample(rep(c(1, 0), c(round(2 / 3 * n), n - round(2 / 3 * n))))
  mu <- 0.5 * x1 + 0.5 * x1^2 + 0.5 * x2
  e1 <- rnorm(N)
  e2 <- 0.5 * e1 + sqrt(0.75) * rnorm(N)
  data.frame(
    x1 = x1, x1sq = x1^2, x2 = x2, S = S, A = A,
    y1 = mu + e1 + A * tau[1], y2 = mu + e2 + A * tau[2]
  )
}
