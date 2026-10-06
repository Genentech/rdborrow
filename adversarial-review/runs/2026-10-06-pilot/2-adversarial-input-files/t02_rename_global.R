source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
d <- SyntheticData
names(d)[names(d) == "S"] <- "trial"
cat("== only S renamed, no global\n")
try_show(ra(ec_ipw(ps5), d, S = "trial"))
cat("== only A renamed\n")
d2 <- SyntheticData
names(d2)[names(d2) == "A"] <- "trt"
try_show(ra(ec_ipw(ps5), d2, A = "trt"))
try_show(ra(ec_aipw(ps5, of5), d2, A = "trt"))
cat("== S renamed, user has a global vector `trial` (same data order)\n")
trial <- d$trial
set.seed(1)
r_glob <- try_show(ra(ec_ipw(ps5, bootstrap = 200), d, S = "trial"))
set.seed(1)
cat("== reference: original names, same seed\n")
r_ref <- try_show(ra(ec_ipw(ps5, bootstrap = 200)))
cat("== S renamed, global `trial` from a differently ordered copy\n")
set.seed(2)
d_shuf <- d[sample(nrow(d)), ]
trial <- d$trial
try_show(ra(ec_ipw(ps5), d_shuf, S = "trial"))
cat("== reference on shuffled with original names\n")
try_show(ra(ec_ipw(ps5), SyntheticData[as.integer(rownames(d_shuf)), ]))
