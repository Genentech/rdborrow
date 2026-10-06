# missing values, factor and constant covariates, constant outcomes, overlap
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")

d <- make_ole(seed = 1)
all3 <- function(d, T_cross = 2, outcomes = ycols(), B = 20, covs = c("x1", "x2", "x3")) {
  for (nm in c("ipw", "aipw", "or")) {
    cat("--", nm, "\n")
    m <- switch(nm, ipw = m_ipw(B), aipw = m_aipw(B), or = m_or(B))
    show_try(fit(d, m, T_cross = T_cross, outcomes = outcomes, covs = covs))
  }
}
cat("baseline\n"); print(sapply(c("ipw", "aipw", "or"), \(w) pe(d, w)))

cat("\n=== M1 one missing covariate value in an external control\n")
dm <- d; dm$x1[which(dm$S == 0)[1]] <- NA; all3(dm)

cat("\n=== M2 one missing period-II outcome (y4) in an external control\n")
dm <- d; dm$y4[which(dm$S == 0)[1]] <- NA; all3(dm)

cat("\n=== M3 one missing period-I outcome (y1) in a trial control\n")
dm <- d; dm$y1[which(dm$S == 1 & dm$A == 0)[1]] <- NA; all3(dm)

cat("\n=== M4 one missing period-II outcome (y3) in a treated patient\n")
dm <- d; dm$y3[which(dm$A == 1)[1]] <- NA; all3(dm)

cat("\n=== F1 factor covariate (x2 as factor)\n")
df <- d; df$x2 <- factor(df$x2, labels = c("no", "yes")); all3(df)

cat("\n=== F2 character covariate (x2 as character)\n")
df <- d; df$x2 <- ifelse(df$x2 == 1, "yes", "no"); all3(df)

cat("\n=== C1 constant covariate (x2 = 1 for everyone)\n")
dc <- d; dc$x2 <- 1; all3(dc)

cat("\n=== C2 constant outcomes at every visit\n")
dc <- d; dc[ycols()] <- 5; all3(dc)

cat("\n=== C3 constant outcome at one OLE visit (y4 = 5 for everyone)\n")
dc <- d; dc$y4 <- 5; all3(dc)

cat("\n=== O1 complete separation: ECs far from the trial on x1\n")
dsep <- make_ole(seed = 4, ec_shift = 8); all3(dsep)

cat("\n=== O2 ECs identical in distribution to the trial, no study bias\n")
did <- make_ole(seed = 5, ec_shift = 0, delta_s = 0, n1 = 400, n0 = 200, m = 400)
print(sapply(c("ipw", "aipw", "or"), \(w) pe(did, w)))
