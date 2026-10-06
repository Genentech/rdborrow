if (Sys.getenv("RDB_LOADALL") == "1") {
  suppressMessages(devtools::load_all("/home/matts/Documents/rdborrow/.claude/worktrees/agent-a01bdffa9ba941ed8", quiet = TRUE))
} else {
  .libPaths(c("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib", .libPaths()))
  library(rdborrow)
}
w <- function(expr) {
  withCallingHandlers(
    tryCatch(expr, error = function(e) {
      cat("ERROR:", conditionMessage(e), "\n")
      invisible(NULL)
    }),
    warning = function(w) {
      cat("WARNING:", conditionMessage(w), "\n")
      invokeRestart("muffleWarning")
    }
  )
}
mk <- function(method, data = SyntheticData, outcomes = c("y1", "y2"),
               covs = c("x1", "x2", "x3", "x4", "x5"), alpha = 0.05, S = "S", A = "A") {
  setup_analysis_primary(
    data = data, trial_status_col_name = S, treatment_col_name = A,
    outcome_col_name = outcomes, covariates_col_name = covs,
    method_weighting_obj = method, alpha = alpha
  )
}
F5 <- "S ~ x1 + x2 + x3 + x4 + x5"
O5 <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
