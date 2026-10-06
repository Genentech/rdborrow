# randomized sweep of the DID properties: 200 datasets, seeds 1:200, random
# arm sizes, T2 in 2:6, T_cross in 1:(T2 - 1), random shifts.
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
methods <- c("ipw", "aipw", "or")
props <- c("permute", "shift_all", "scale", "ec_shift_all", "ec_shift_II",
           "ctrl_shift_I", "trt_I_unused", "ctrl_II_unused", "duplicate")
worst <- setNames(numeric(length(props)), props)
for (seed in 1:200) {
  set.seed(seed)
  T2 <- sample(2:6, 1)
  Tc <- sample(seq_len(T2 - 1), 1)
  n1 <- sample(15:80, 1)
  n0 <- sample(10:60, 1)
  m <- sample(15:80, 1)
  d <- make_ole(n1 = n1, n0 = n0, m = m, T1 = Tc, T2 = T2, seed = seed + 1000)
  yc <- ycols(T2)
  pre <- yc[1:Tc]
  post <- yc[(Tc + 1):T2]
  est <- function(dd) sapply(methods, \(w) pe(dd, w, T_cross = Tc, outcomes = yc))
  base <- est(d)
  base <- matrix(base, ncol = 3)
  c0 <- runif(1, -50, 50)
  k <- runif(1, 0.1, 10)
  delta <- runif(length(post), -5, 5)
  dev <- function(dd, expected = base) max(abs(matrix(est(dd), ncol = 3) - expected))
  is_ec <- d$S == 0
  is_ctrl <- d$S == 1 & d$A == 0
  r <- list()
  r$permute <- dev(d[sample(nrow(d)), ])
  d2 <- d; d2[yc] <- d2[yc] + c0; r$shift_all <- dev(d2)
  d2 <- d; d2[yc] <- d2[yc] * k; r$scale <- dev(d2, k * base) / k
  d2 <- d; d2[is_ec, yc] <- d2[is_ec, yc] + c0; r$ec_shift_all <- dev(d2)
  d2 <- d; d2[is_ec, post] <- sweep(as.matrix(d2[is_ec, post, drop = FALSE]), 2, delta, "+")
  r$ec_shift_II <- dev(d2, base - delta)
  d2 <- d; d2[is_ctrl, pre] <- d2[is_ctrl, pre] + c0; r$ctrl_shift_I <- dev(d2, base - c0)
  d2 <- d; d2[d2$A == 1, pre] <- rnorm(sum(d2$A == 1) * Tc); r$trt_I_unused <- dev(d2)
  d2 <- d; d2[is_ctrl, post] <- rnorm(sum(is_ctrl) * length(post)); r$ctrl_II_unused <- dev(d2)
  r$duplicate <- dev(rbind(d, d))
  worst <- pmax(worst, unlist(r)[props])
}
print(signif(worst, 3))
