# Monte Carlo: scm() bias depends on the units of a covariate.
# DGP satisfies the SCM assumption (Eq. 6): unmeasured U with time-varying
# loading, no study effect. x1 is a measured confounder; age is a measured
# covariate with no effect on outcome (same in trial and ECs).
# expected before running: in years the SC weights match on (x1, age, y1, y2),
# and y1, y2 proxy U, so bias is small. With age in days (x 365) the distance
# is dominated by age, matching on y1, y2 and x1 is lost, so bias moves
# toward the naive comparison. lambda fixed at 0.01; tau3 = 1.5, tau4 = 2.
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")

gen <- function(seed, n1 = 40, n0 = 20, m = 40) {
  set.seed(seed)
  N <- n1 + n0 + m
  S <- c(rep(1, n1 + n0), rep(0, m))
  A <- c(rep(1, n1), rep(0, n0 + m))
  x1 <- rnorm(N, ifelse(S == 1, 0, 0.5))
  U <- rnorm(N, ifelse(S == 1, 0, -1))
  age <- runif(N, 2, 25)
  tau <- c(0.5, 1, 1.5, 2)
  lam <- c(1, 1.2, 1.4, 1.6)
  Y <- sapply(1:4, \(t) {
    0.3 * t + x1 + lam[t] * U + ifelse(A == 1, tau[t], 0) +
      ifelse(S == 1 & A == 0 & t > 2, tau[t], 0) + rnorm(N, sd = 0.3)
  })
  colnames(Y) <- ycols()
  data.frame(x1 = x1, x2 = age, x3 = rnorm(N), A = A, S = S, Y)
}

R <- 40
res <- t(sapply(seq_len(R), \(r) {
  d <- gen(1000 + r)
  dd <- d
  dd$x2 <- dd$x2 * 365
  c(years = pe(d, "scm", lambda = 0.01), days = pe(dd, "scm", lambda = 0.01))
}))
bias <- colMeans(res) - rep(c(1.5, 2), 2)
mcse <- apply(res, 2, sd) / sqrt(R)
print(round(rbind(bias = bias, mcse = mcse), 3))
