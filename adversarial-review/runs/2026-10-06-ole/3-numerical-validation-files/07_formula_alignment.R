source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# DID-EC-OR / DID-EC-AIPW: are outcome formulas matched to outcomes by
# position (extends #104 to the OLE methods)? And what happens when the
# number of formulas differs from the number of outcomes?
d <- SyntheticData
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
f <- fml(outs, covs)
fp <- f[c(3, 4, 1, 2)]
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
set.seed(1)
cat("OR   in order:", pkg_fit(d, did_ec_or(f, f, f, bootstrap = 2), outs, covs, 2)$point_estimates, "\n")
cat("OR   permuted:", pkg_fit(d, did_ec_or(fp, fp, fp, bootstrap = 2), outs, covs, 2)$point_estimates, "\n")
cat("AIPW in order:", pkg_fit(d, did_ec_aipw(ps, NULL, f, bootstrap = 2), outs, covs, 2)$point_estimates, "\n")
cat("AIPW permuted:", pkg_fit(d, did_ec_aipw(ps, NULL, fp, bootstrap = 2), outs, covs, 2)$point_estimates, "\n")
cat("OR, 3 formulas (y1..y3) for 4 outcomes:\n")
print(try(pkg_fit(d, did_ec_or(f[1:3], f[1:3], f[1:3], bootstrap = 2), outs, covs, 2)))
cat("AIPW, 3 formulas (y1..y3) for 4 outcomes:\n")
print(try(pkg_fit(d, did_ec_aipw(ps, NULL, f[1:3], bootstrap = 2), outs, covs, 2)))
cat("OR, 5 formulas (y1..y4, y4) for 4 outcomes:\n")
print(try(pkg_fit(d, did_ec_or(f[c(1:4, 4)], f[c(1:4, 4)], f[c(1:4, 4)], bootstrap = 2), outs, covs, 2)))
# control outcomes after crossover are unused by every method (Remark 2)
d2 <- d
d2$y3[d2$S == 1 & d2$A == 0] <- d2$y3[d2$S == 1 & d2$A == 0] + 100
cat("OR with y3 of trial controls shifted by 100:",
  pkg_fit(d2, did_ec_or(f, f, f, bootstrap = 2), outs, covs, 2)$point_estimates, "\n")
cat("AIPW with y3 of trial controls shifted by 100:",
  pkg_fit(d2, did_ec_aipw(ps, NULL, f, bootstrap = 2), outs, covs, 2)$point_estimates, "\n")
cat("IPW (orig / shifted):",
  pkg_fit(d, did_ec_ipw(ps, bootstrap = 2), outs, covs, 2)$point_estimates,
  pkg_fit(d2, did_ec_ipw(ps, bootstrap = 2), outs, covs, 2)$point_estimates, "\n")
