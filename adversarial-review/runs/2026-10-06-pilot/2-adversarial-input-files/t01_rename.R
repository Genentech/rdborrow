source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
cat("== baseline\n")
try_show(ra(ec_ipw(ps5)))
d <- SyntheticData
names(d)[names(d) == "S"] <- "trial"
names(d)[names(d) == "A"] <- "trt"
cat("== renamed S->trial, A->trt; ps 'S ~ ...'\n")
try_show(ra(ec_ipw(ps5), d, S = "trial", A = "trt"))
cat("== renamed; ps 'trial ~ ...'\n")
try_show(ra(ec_ipw("trial ~ x1 + x2 + x3 + x4 + x5"), d, S = "trial", A = "trt"))
cat("== renamed; ec_aipw\n")
try_show(ra(ec_aipw(ps5, of5), d, S = "trial", A = "trt"))
cat("== renamed; ec_ipw weight = 0\n")
try_show(ra(ec_ipw(ps5, weight = 0), d, S = "trial", A = "trt"))
cat("== rename outcomes and covariates only\n")
d2 <- SyntheticData
names(d2)[match(c("y1", "y2", "x1"), names(d2))] <- c("out_a", "out_b", "age")
try_show(ra(ec_aipw("S ~ age + x2 + x3 + x4 + x5",
  c("out_a ~ age + x2 + x3 + x4 + x5", "out_b ~ age + x2 + x3 + x4 + x5")),
  d2, y = c("out_a", "out_b"), x = c("age", "x2", "x3", "x4", "x5")))
cat("== baseline aipw\n")
try_show(ra(ec_aipw(ps5, of5)))
