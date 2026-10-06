source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
set.seed(20261006)
for (N in c(2000, 8000, 16000)) {
  d <- sim_scenario_a(N)
  gc(reset = TRUE)
  t_ipw <- system.time(r <- estimate(ec_ipw("S ~ x1 + x1sq + x2"),
    data = d, outcomes = c("y1", "y2"), treatment = "A", trial_status = "S",
    covariates = c("x1", "x1sq", "x2")
  ))[["elapsed"]]
  mem_ipw <- sum(gc()[, 6])
  gc(reset = TRUE)
  t_aipw <- system.time(r <- estimate(ec_aipw("S ~ x1 + x1sq + x2", c("y1 ~ x1 + x1sq + x2", "y2 ~ x1 + x1sq + x2")),
    data = d, outcomes = c("y1", "y2"), treatment = "A", trial_status = "S",
    covariates = c("x1", "x1sq", "x2")
  ))[["elapsed"]]
  mem_aipw <- sum(gc()[, 6])
  t_ind <- system.time({
    f <- ind_ec(d, c("y1", "y2"), ind_design(d, c("x1", "x1sq", "x2")), ind_design(d, c("x1", "x1sq", "x2")), aipw = TRUE)
    s <- ind_sandwich(f, d, c("y1", "y2"), ind_design(d, c("x1", "x1sq", "x2")), ind_design(d, c("x1", "x1sq", "x2")), aipw = TRUE)
  })[["elapsed"]]
  cat(sprintf(
    "N=%5d  ec_ipw %.2fs peak %.0f MB | ec_aipw %.2fs peak %.0f MB | independent aipw+sandwich %.2fs | N^2*8 bytes = %.0f MB\n",
    N, t_ipw, mem_ipw, t_aipw, mem_aipw, t_ind, N^2 * 8 / 2^20
  ))
}
