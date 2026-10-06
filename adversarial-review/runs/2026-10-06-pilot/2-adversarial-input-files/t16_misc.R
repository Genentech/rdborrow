source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
cat("== tibble input\n")
if (requireNamespace("tibble", quietly = TRUE)) {
  tb <- tibble::as_tibble(SyntheticData)
  a <- ra(ec_aipw(ps5, of5), tb); b <- ra(ec_aipw(ps5, of5))
  cat("tibble identical to data.frame:", isTRUE(all.equal(a, b)), "\n")
}
cat("== EC-AIPW weight = 0 under complete separation (PS model irrelevant to tau at w = 0)\n")
d <- SyntheticData; d$x5[d$S == 0] <- d$x5[d$S == 0] + 200
try_show(ra(ec_aipw("S ~ x5", c("y1 ~ x5", "y2 ~ x5"), weight = 0), d, x = "x5"))
cat("-- same data, PS formula without x5 (tau must be identical at w = 0)\n")
try_show(ra(ec_aipw("S ~ 1", c("y1 ~ x5", "y2 ~ x5"), weight = 0), d, x = "x5"))
