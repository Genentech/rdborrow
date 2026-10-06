# factor-coded trial status / treatment pass the 0/1 check in setup
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)
ipw_trt <- function(B = 20) {
  did_ec_ipw("S ~ x1 + x2 + x3", trt_formula = "A ~ x1 + x2 + x3", bootstrap = B)
}

cat("=== numeric A, trt_formula given\n")
show_try(fit(d, ipw_trt()))

cat("\n=== A as factor, levels c('0', '1')\n")
dA <- d
dA$A <- factor(dA$A, levels = c(0, 1))
show_try(fit(dA, ipw_trt()))

cat("\n=== A as factor, levels c('1', '0') (e.g. 'treated' listed first)\n")
dA <- d
dA$A <- factor(dA$A, levels = c(1, 0))
show_try(fit(dA, ipw_trt()))
show_try(fit(dA, m_aipw(20)))
show_try(fit(dA, m_or(20)))
show_try(fit(dA, m_scm(3)))

cat("\n=== S as factor, levels c('1', '0')\n")
dS <- d
dS$S <- factor(dS$S, levels = c(1, 0))
show_try(fit(dS, m_ipw(20)))
show_try(fit(dS, m_or(20)))
show_try(fit(dS, m_scm(3)))
