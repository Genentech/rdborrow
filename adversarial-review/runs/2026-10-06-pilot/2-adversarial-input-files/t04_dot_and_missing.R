source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
ns <- asNamespace("rdborrow")
df <- ns$.build_analysis_df(SyntheticData, c("y1", "y2"), "A", "S", cov5)
cat("internal df columns:", names(df), "\n")
cat("S ~ . expands to:", deparse(formula(terms(as.formula("S ~ ."), data = df))), "\n")

cat("\n== NA in one outcome (trial control row)\n")
d <- SyntheticData
i_ctrl <- which(d$S == 1 & d$A == 0)[1]
d$y1[i_ctrl] <- NA
try_show(ra(ec_ipw(ps5), d))
try_show(ra(ec_aipw(ps5, of5), d))
cat("\n== NA in one outcome (external row)\n")
d <- SyntheticData
d$y2[which(d$S == 0)[1]] <- NA
try_show(ra(ec_ipw(ps5), d))
try_show(ra(ec_aipw(ps5, of5), d))
cat("\n== NA in a covariate (external row)\n")
d <- SyntheticData
d$x5[which(d$S == 0)[1]] <- NA
try_show(ra(ec_ipw(ps5), d))
try_show(ra(ec_ipw(ps5, weight = 0.5), d))
try_show(ra(ec_aipw(ps5, of5), d))
cat("\n== NA in a covariate (trial treated row)\n")
d <- SyntheticData
d$x5[which(d$S == 1 & d$A == 1)[1]] <- NA
try_show(ra(ec_ipw(ps5), d))
try_show(ra(ec_aipw(ps5, of5), d))
cat("\n== NA in a covariate not in the PS formula, EC-IPW weight = 0\n")
try_show(ra(ec_ipw(ps5, weight = 0), d))
cat("\n== NA in S\n")
d <- SyntheticData
d$S[1] <- NA
try_show(ra(ec_ipw(ps5), d))
cat("\n== NA in A\n")
d <- SyntheticData
d$A[1] <- NA
try_show(ra(ec_ipw(ps5), d))
cat("\n== NA in outcome with bootstrap\n")
d <- SyntheticData
d$y1[i_ctrl] <- NA
set.seed(1)
try_show(ra(ec_ipw(ps5, bootstrap = 50), d))
