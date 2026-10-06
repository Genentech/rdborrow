source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
covs <- c("x1", "x2", "x3", "x4", "x5")

cat("== P1: trial status column not named S ==\n")
d2 <- SyntheticData
names(d2)[names(d2) == "S"] <- "trial"
r <- try(estimate(ec_ipw("trial ~ x1 + x2 + x3 + x4 + x5"),
  data = d2, outcomes = c("y1", "y2"), treatment = "A",
  trial_status = "trial", covariates = covs
))
print(r)

cat("== P1b: same via run_analysis ==\n")
a <- try(setup_analysis_primary(
  data = d2, trial_status_col_name = "trial", treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"), covariates_col_name = covs,
  method_weighting_obj = ec_ipw("trial ~ x1 + x2 + x3 + x4 + x5")
))
print(try(run_analysis(a)))

cat("== P2: outcome_formula order swapped relative to outcomes ==\n")
of <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
r1 <- estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", of),
  data = SyntheticData, outcomes = c("y1", "y2"), treatment = "A",
  trial_status = "S", covariates = covs
)
r2 <- estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", rev(of)),
  data = SyntheticData, outcomes = c("y1", "y2"), treatment = "A",
  trial_status = "S", covariates = covs
)
print(r1$results)
print(r2$results)
cat("== P2b: outcome_formula LHS for a column not among outcomes ==\n")
r3 <- try(estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", c("y3 ~ x1", "y4 ~ x1")),
  data = SyntheticData, outcomes = c("y1", "y2"), treatment = "A",
  trial_status = "S", covariates = covs
))
print(r3)
