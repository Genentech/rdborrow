source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
cat("mode:", if (Sys.getenv("RDB_LOADALL") == "1") "load_all" else "installed", "\n")
d <- SyntheticData
pe <- function(m, data = d, S = "S", A = "A", outcomes = c("y1", "y2"), covs = c("x1", "x2", "x3", "x4", "x5")) {
  r <- w(run_analysis(setup_analysis_primary(data, S, A, outcomes, covs, m)))
  if (!is.null(r)) print(round(c(r$results$point_estimates, sd = r$results$standard_deviation, bw = r$borrow_weight), 4))
}
cat("\nF4 trial status column not named S\n")
dS <- d; names(dS)[names(dS) == "S"] <- "in_trial"
pe(ec_ipw("in_trial ~ x1 + x2 + x3 + x4 + x5"), data = dS, S = "in_trial")
pe(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", O5), data = dS, S = "in_trial")

cat("\nF3 column named A collides with treatment\n")
dA <- d; names(dA)[names(dA) == "A"] <- "arm"
pe(ec_ipw(F5), data = dA, A = "arm")
dc <- dA; names(dc)[names(dc) == "x4"] <- "A"
pe(ec_ipw("S ~ x1 + x2 + x3 + A + x5"), data = dc, A = "arm", covs = c("x1", "x2", "x3", "A", "x5"))
db <- dA; db$ybin <- as.numeric(db$y1 > 0); db$A <- db$ybin
pe(ec_ipw(F5), data = db, A = "arm", outcomes = "ybin")
pe(ec_ipw(F5), data = db, A = "arm", outcomes = "A")

cat("\nF1 outcome_formula matched by position, LHS used\n")
pe(ec_aipw(F5, O5))
pe(ec_aipw(F5, rev(O5)))
pe(ec_aipw(F5, O5[c(1, 1)]))

cat("\nF2 S ~ . pulls outcomes and treatment into the PS model\n")
pe(ec_ipw(F5))
pe(ec_ipw("S ~ ."))
pe(ec_ipw("S ~ x1 + x2 + x3 + x4 + x5 + y1 + y2 + A"))

cat("\nF5 optimal weight ignores outcome conflict\n")
for (s in c(0, 5, 50)) {
  ds <- d; ds$y1[ds$S == 0] <- ds$y1[ds$S == 0] + s; ds$y2[ds$S == 0] <- ds$y2[ds$S == 0] + s
  pe(ec_ipw(F5), data = ds)
}

cat("\nF6 missing outcome values: silent NA that contaminates other outcomes\n")
dn <- d; dn$y1[c(1, 3, 250)] <- NA
pe(ec_ipw(F5), data = dn)
pe(ec_aipw(F5, O5), data = dn)

cat("\nF7 external controls with A = 1 accepted silently\n")
de <- d; de$A[which(de$S == 0)[1:10]] <- 1
pe(ec_ipw(F5), data = de)
pe(ec_aipw(F5, O5), data = de)

cat("\nF8 bootstrap_ci_type without bootstrap silently ignored\n")
m <- ec_ipw(F5, bootstrap_ci_type = "bca")
print(m@bootstrap_ci_type)
print(names(run_analysis(setup_analysis_primary(d, "S", "A", c("y1", "y2"), c("x1", "x2", "x3", "x4", "x5"), m))$results))

cat("\nF9 alpha = 0 / 1 accepted\n")
set.seed(1)
print(run_analysis(setup_analysis_primary(d, "S", "A", "y1", c("x1", "x2", "x3", "x4", "x5"), ec_ipw(F5, bootstrap = 50), alpha = 0))$results)
print(run_analysis(setup_analysis_primary(d, "S", "A", "y1", c("x1", "x2", "x3", "x4", "x5"), ec_ipw(F5), alpha = 1))$results)
