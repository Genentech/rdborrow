# DGP of MC_PREREGISTRATION.md
dgp_h <- function(x1, x2, x3, x4, x5) cbind(x1, x2, x3, x4, x2 * x4, x5)
dgp_center <- c(0.5, 0.4, 3.1, 13.5, 5.4, 45)
dgp_beta <- c(0.5, -0.5, 0.4, 0.05, 0.03, -0.03)
dgp_theta <- c(-1, -0.8, 0.6, -0.08, -0.15, 0.03)
dgp_delta <- c(0, -0.5, -1, -1.5)
dgp_m <- c(1, 1.5, 2, 2.5)
dgp_tau <- c(0.625, 1.5, 1.875, 2.5)

dgp_covariates <- function(n) {
  data.frame(
    x1 = rbinom(n, 1, 0.5),
    x2 = rbinom(n, 1, 0.4),
    x3 = sample(2:4, n, replace = TRUE, prob = c(0.1, 0.7, 0.2)),
    x4 = runif(n, 2, 25),
    x5 = rnorm(n, 45, 10)
  )
}

dgp_lin_ps <- function(X, a) {
  H <- dgp_h(X$x1, X$x2, X$x3, X$x4, X$x5)
  a + drop(sweep(H, 2, dgp_center) %*% dgp_beta)
}

# tune intercept once so that P(S = 1) = 0.75 (no outcomes involved)
dgp_tune_a <- function(seed = 1) {
  set.seed(seed)
  X <- dgp_covariates(1e6)
  uniroot(function(a) mean(plogis(dgp_lin_ps(X, a))) - 0.75, c(-5, 5))$root
}

sim_ole <- function(setting, a, N = 220) {
  X <- dgp_covariates(N)
  S <- rbinom(N, 1, plogis(dgp_lin_ps(X, a)))
  A <- S * rbinom(N, 1, 2 / 3)
  if (setting == "S1") {
    lam <- rep(0, 4)
    Delta <- 0
  } else if (setting == "S3") {
    lam <- rep(1, 4)
    Delta <- 1
  } else if (setting == "S4") {
    lam <- c(0.6, 0.8, 1.2, 1.6)
    Delta <- 0
  }
  U <- rnorm(N, 0.6 * S, 1)
  H <- dgp_h(X$x1, X$x2, X$x3, X$x4, X$x5)
  hb <- drop(H %*% dgp_theta)
  b <- rnorm(N)
  Y <- sapply(1:4, function(t) {
    y0 <- dgp_delta[t] + dgp_m[t] * hb + lam[t] * U + Delta * S + b + rnorm(N)
    eff <- if (t <= 2) A * dgp_tau[t] else S * (A * dgp_tau[t] + (1 - A) * dgp_tau[t - 2])
    y0 + eff
  })
  colnames(Y) <- paste0("y", 1:4)
  data.frame(X, S = S, A = A, Y)
}
