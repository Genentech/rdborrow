# shared loader: LOAD=installed (default) or LOAD=dev
mode <- Sys.getenv("LOAD", "installed")
if (mode == "dev") {
  suppressMessages(devtools::load_all(
    "/home/matts/Documents/rdborrow/.claude/worktrees/agent-a0c92496bd7f92298",
    quiet = TRUE
  ))
} else {
  .libPaths(c(
    "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib",
    .libPaths()
  ))
  library(rdborrow)
}
cat("# rdborrow", format(packageVersion("rdborrow")), "mode:", mode, "\n")

show <- function(expr) {
  ws <- character()
  res <- withCallingHandlers(
    tryCatch(expr, error = function(e) {
      cat("ERROR:", conditionMessage(e), "\n")
      invisible(NULL)
    }),
    warning = function(w) {
      ws <<- c(ws, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (length(ws)) {
    tab <- table(ws)
    for (i in seq_along(tab)) cat("WARNING (x", tab[[i]], "):", names(tab)[i], "\n")
  }
  invisible(res)
}

ole <- function(method, data = SyntheticData, outcomes = c("y1", "y2", "y3", "y4"),
                T_cross = 2, alpha = 0.05, ts = "S", trt = "A",
                cov = c("x1", "x2", "x3", "x4", "x5")) {
  a <- setup_analysis_OLE(
    data = data, trial_status_col_name = ts, treatment_col_name = trt,
    outcome_col_name = outcomes, covariates_col_name = cov,
    method_OLE_obj = method, T_cross = T_cross, alpha = alpha
  )
  run_analysis(a)
}

f5 <- function(y) paste(y, "~ x1 + x2 + x3 + x4 + x5")
