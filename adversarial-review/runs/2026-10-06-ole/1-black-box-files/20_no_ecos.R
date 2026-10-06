# simulate a machine without the suggested package ECOSolveR, then run the
# vignette's scm() chunk as written
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
suppressMessages(trace("requireNamespace",
  tracer = quote(if (identical(package, "ECOSolveR")) return(FALSE)),
  print = FALSE, where = baseenv()
))
method <- scm(lambda_min = 0, lambda_max = 1e-3, nlambda = 2, bootstrap = 3, bootstrap_ci_type = "perc")
analysis <- setup_analysis_OLE(
  data = SyntheticData, trial_status_col_name = "S", treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  T_cross = 2, method_OLE_obj = method
)
show(run_analysis(analysis))
cat("vignette chunk guarded by requireNamespace('ECOSolveR')? ",
    any(grepl("ECOSolveR", readLines("/home/matts/Documents/rdborrow/.claude/worktrees/agent-a0c92496bd7f92298/vignettes/OLE_analysis_workflow.Rmd"))), "\n")
