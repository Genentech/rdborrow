source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
base_ipw <- ra(ec_ipw(ps5))$results
base_aipw <- ra(ec_aipw(ps5, of5))$results
cmp <- function(r, base) {
  if (!is.null(r)) cat("  max abs diff vs baseline:", max(abs(as.matrix(r$results) - as.matrix(base))), "\n")
}
for (ty in c("logical", "integer", "factor", "character", "factor_rev")) {
  d <- SyntheticData
  conv <- switch(ty,
    logical = as.logical, integer = as.integer, factor = factor,
    character = as.character, factor_rev = \(x) factor(x, levels = c(1, 0))
  )
  cat("\n== S and A as", ty, "\n")
  d$S <- conv(d$S)
  d$A <- conv(d$A)
  cmp(try_show(ra(ec_ipw(ps5), d)), base_ipw)
  cmp(try_show(ra(ec_aipw(ps5, of5), d)), base_aipw)
  cmp(try_show(ra(ec_ipw(ps5, weight = 0), d)), ra(ec_ipw(ps5, weight = 0))$results)
}
cat("\n== S coded 1/2\n")
d <- SyntheticData
d$S <- d$S + 1
try_show(ra(ec_ipw(ps5), d))
cat("\n== A coded -1/1\n")
d <- SyntheticData
d$A <- 2 * d$A - 1
try_show(ra(ec_ipw(ps5), d))
cat("\n== S as factor with labels trial/external\n")
d <- SyntheticData
d$S <- factor(d$S, labels = c("external", "trial"))
try_show(ra(ec_ipw(ps5), d))
cat("\n== S = 1.0000001 (near-1 numeric)\n")
d <- SyntheticData
d$S[d$S == 1] <- 1 + 1e-12
try_show(ra(ec_ipw(ps5), d))
