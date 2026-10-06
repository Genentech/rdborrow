# bca with B below the sample size (n = 130); seed 2024
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)
for (B in c(10, 50, 200)) {
  cat("-- did_ec_ipw bca, B =", B, "\n")
  show_try(fit(d, m_ipw(B, bootstrap_ci_type = "bca")))
}
for (B in c(10, 50)) {
  cat("-- did_ec_ipw perc, B =", B, "\n")
  show_try(fit(d, m_ipw(B)))
}
