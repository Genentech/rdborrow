# run every chunk of vignettes/OLE_analysis_workflow.Rmd as written, surfacing the
# warnings and messages that the chunk options hide
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
rmd <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-a0c92496bd7f92298/vignettes/OLE_analysis_workflow.Rmd"
out <- tempfile(fileext = ".R")
knitr::purl(rmd, output = out, quiet = TRUE)
code <- parse(out)
set.seed(20261006)
for (e in code) {
  cat("\n> ", paste(deparse(e)[1:min(2, length(deparse(e)))], collapse = " "), "\n")
  t0 <- Sys.time()
  withCallingHandlers(
    print(eval(e, globalenv())),
    warning = function(w) { cat("WARNING:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") },
    message = function(m) { cat("MESSAGE:", conditionMessage(m)); invokeRestart("muffleMessage") }
  )
  cat("[elapsed", round(as.numeric(Sys.time() - t0, units = "secs"), 1), "s]\n")
}
