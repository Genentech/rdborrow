if (identical(Sys.getenv("RDB_LOAD"), "dev")) {
  suppressMessages(devtools::load_all("/home/matts/Documents/rdborrow/.claude/worktrees/agent-ad99b4e28fccdd97f", quiet = TRUE))
  cat("[loaded via devtools::load_all]\n")
} else {
  .libPaths(c("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib", .libPaths()))
  suppressMessages(library(rdborrow))
  cat("[loaded installed rdborrow", as.character(packageVersion("rdborrow")), "]\n")
}
cov5 <- c("x1", "x2", "x3", "x4", "x5")
ps5 <- "S ~ x1 + x2 + x3 + x4 + x5"
of5 <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
ra <- function(m, data = SyntheticData, S = "S", A = "A", y = c("y1", "y2"),
               x = cov5, alpha = 0.05) {
  run_analysis(setup_analysis_primary(data, S, A, y, x, m, alpha = alpha))
}
show_res <- function(r) {
  print(signif(as.matrix(r$results), 7))
  cat("borrow_weight:", format(r$borrow_weight, digits = 10), "\n")
}
try_show <- function(expr) {
  res <- tryCatch(
    withCallingHandlers(expr, warning = function(w) {
      cat("WARNING:", conditionMessage(w), "\n")
      invokeRestart("muffleWarning")
    }),
    error = function(e) {
      cat("ERROR:", conditionMessage(e), "\n")
      NULL
    }
  )
  if (!is.null(res)) show_res(res)
  invisible(res)
}
