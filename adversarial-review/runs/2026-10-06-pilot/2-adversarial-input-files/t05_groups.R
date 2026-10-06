source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
cat("== external controls with A = 1 (first 10 external rows set A = 1)\n")
d <- SyntheticData
ext <- which(d$S == 0)
d$A[ext[1:10]] <- 1
d$y1[ext[1:10]] <- d$y1[ext[1:10]] + 50
try_show(ra(ec_ipw(ps5), d))
try_show(ra(ec_ipw(ps5, weight = 1), d))
try_show(ra(ec_aipw(ps5, of5), d))
cat("-- reference: those 10 external rows dropped\n")
try_show(ra(ec_ipw(ps5), d[-ext[1:10], ]))
try_show(ra(ec_ipw(ps5, weight = 1), d[-ext[1:10], ]))

cat("\n== no external controls at all\n")
d0 <- SyntheticData[SyntheticData$S == 1, ]
try_show(ra(ec_ipw(ps5), d0))
try_show(ra(ec_ipw(ps5, weight = 0), d0))
try_show(ra(ec_aipw(ps5, of5), d0))
cat("\n== no trial controls\n")
d1 <- SyntheticData[!(SyntheticData$S == 1 & SyntheticData$A == 0), ]
try_show(ra(ec_ipw(ps5), d1))
try_show(ra(ec_ipw(ps5, weight = 1), d1))
try_show(ra(ec_aipw(ps5, of5, weight = 1), d1))
cat("\n== no trial treated\n")
d2 <- SyntheticData[!(SyntheticData$S == 1 & SyntheticData$A == 1), ]
try_show(ra(ec_ipw(ps5), d2))
try_show(ra(ec_aipw(ps5, of5), d2))
cat("\n== one trial control\n")
keep <- c(which(SyntheticData$S == 1 & SyntheticData$A == 0)[1],
  which(!(SyntheticData$S == 1 & SyntheticData$A == 0)))
d3 <- SyntheticData[keep, ]
try_show(ra(ec_ipw(ps5), d3))
try_show(ra(ec_ipw(ps5, weight = 0), d3))
try_show(ra(ec_aipw(ps5, of5), d3))
set.seed(3)
try_show(ra(ec_ipw(ps5, bootstrap = 50), d3))
cat("\n== one external control\n")
keep <- c(which(SyntheticData$S == 0)[1], which(SyntheticData$S == 1))
d4 <- SyntheticData[keep, ]
try_show(ra(ec_ipw(ps5), d4))
try_show(ra(ec_aipw(ps5, of5), d4))
cat("\n== tiny: 4 per group, single covariate\n")
set.seed(4)
d5 <- SyntheticData[c(sample(which(SyntheticData$S == 1 & SyntheticData$A == 1), 4),
  sample(which(SyntheticData$S == 1 & SyntheticData$A == 0), 4),
  sample(which(SyntheticData$S == 0), 4)), ]
try_show(ra(ec_ipw("S ~ x5"), d5, x = "x5"))
try_show(ra(ec_aipw("S ~ x5", c("y1 ~ x5", "y2 ~ x5")), d5, x = "x5"))
set.seed(5)
try_show(ra(ec_ipw("S ~ x5", bootstrap = 50), d5, x = "x5"))
try_show(ra(ec_aipw("S ~ x5", c("y1 ~ x5", "y2 ~ x5"), bootstrap = 50), d5, x = "x5"))
