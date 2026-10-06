# cross-method identities implied by Eq. 3-5 and Appendix B
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)
yc <- ycols()
df <- ns$.build_analysis_df(d, yc, "A", "S", c("x1", "x2", "x3"))
Y <- as.matrix(df[, yc])
f1 <- paste0(yc, " ~ 1")

ipw0 <- ns$.did_ec_ipw_core(df, Y, df$S, df$A, 2, "S ~ 1", NULL)$tau
or0 <- ns$.did_ec_or_core(df, df$S, df$A, 2, f1, f1, f1)$tau
aipw00 <- ns$.did_ec_aipw_core(df, Y, df$S, df$A, 2, "S ~ 1", NULL, f1)$tau
raw <- (colMeans(Y[df$A == 1, 3:4]) - mean(rowMeans(Y[df$S == 1 & df$A == 0, 1:2]))) -
  (colMeans(Y[df$S == 0, 3:4]) - mean(rowMeans(Y[df$S == 0, 1:2])))
cat("X1 intercept-only nuisance models: IPW, OR, AIPW and the raw DID of means agree\n")
print(rbind(ipw0, or0, aipw00, raw))

ipw <- ns$.did_ec_ipw_core(df, Y, df$S, df$A, 2, "S ~ x1 + x2 + x3", NULL)$tau
aipw_int <- ns$.did_ec_aipw_core(df, Y, df$S, df$A, 2, "S ~ x1 + x2 + x3", NULL, f1)$tau
cat("\nX2 AIPW with intercept-only outcome models equals IPW\n")
print(rbind(ipw, aipw_int))

ipw_trt1 <- ns$.did_ec_ipw_core(df, Y, df$S, df$A, 2, "S ~ x1 + x2 + x3", "A ~ 1")$tau
cat("\nX3 trt_formula = 'A ~ 1' equals the marginal default\n")
print(rbind(ipw, ipw_trt1))

cat("\nX4 covariate constant among external controls only (x2 = 1 for every EC)\n")
d2 <- d
d2$x2[d2$S == 0] <- 1
show_try(pe(d2, "or"))
show_try(pe(d2, "aipw"))
