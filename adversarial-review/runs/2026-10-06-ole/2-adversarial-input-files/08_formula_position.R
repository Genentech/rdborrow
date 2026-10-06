# new evidence for #104: did_ec_aipw() and did_ec_or() match formulas by position,
# and did_ec_or() takes the number of visits from the formulas, not the outcomes
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)
f <- forms()
fr <- rev(f)

cat("=== did_ec_aipw: formulas in reverse order\n")
show_try(fit(d, m_aipw(20)))
show_try(fit(d, did_ec_aipw("S ~ x1 + x2 + x3", outcome_formula = fr, bootstrap = 20)))

cat("\n=== did_ec_or: formulas in reverse order\n")
show_try(fit(d, did_ec_or(fr, fr, fr, bootstrap = 20)))

cat("\n=== did_ec_or: LHS names a column that is not in outcome_col_name\n")
d$z <- d$y4 + 10
fz <- c(f[1:3], "z ~ x1 + x2 + x3")
show_try(fit(d, did_ec_or(fz, fz, fz, bootstrap = 20)))

cat("\n=== did_ec_or: five outcomes, four formulas (T_cross = 2)\n")
d5 <- make_ole(T2 = 5, seed = 1)
show_try(fit(d5, m_or(20, T2 = 4), outcomes = ycols(5)))

cat("\n=== did_ec_or: four outcomes, five formulas (extra y5 in data)\n")
show_try(fit(d5, m_or(20, T2 = 5), outcomes = ycols(4)))

cat("\n=== did_ec_aipw: four outcomes, five formulas\n")
show_try(fit(d5, m_aipw(20, T2 = 5), outcomes = ycols(4)))

cat("\n=== did_ec_aipw: five outcomes, four formulas\n")
show_try(fit(d5, m_aipw(20, T2 = 4), outcomes = ycols(5)))
