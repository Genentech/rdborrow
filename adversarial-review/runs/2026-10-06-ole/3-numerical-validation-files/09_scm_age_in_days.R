source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/n3/common.R")
# realistic unit choice: x4 (age-like, 1-32) recorded in days
d <- SyntheticData
d$x4 <- d$x4 * 365.25
outs <- paste0("y", 1:4)
covs <- paste0("x", 1:5)
a <- setup_analysis_OLE(
  data = d, trial_status_col_name = "S", treatment_col_name = "A",
  outcome_col_name = outs, covariates_col_name = covs, T_cross = 2,
  method_OLE_obj = scm(bootstrap = 2)
)
ws <- character()
set.seed(1)
res <- withCallingHandlers(
  try(run_analysis(a)),
  warning = function(cond) {
    ws <<- c(ws, conditionMessage(cond))
    invokeRestart("muffleWarning")
  }
)
print(res)
cat("warnings:", length(ws), "\n")
print(table(substr(ws, 1, 60)))
