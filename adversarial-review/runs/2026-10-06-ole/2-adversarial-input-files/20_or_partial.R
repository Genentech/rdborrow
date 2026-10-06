# did_ec_or() with rct_ctrl formulas for period I only and rct_trt for period II only
# (the only visits each set is used for, R/did_ec_or.R:161-170)
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)
f <- forms()
show_try(fit(d, did_ec_or(f, f[1:2], f[3:4], bootstrap = 20)))
