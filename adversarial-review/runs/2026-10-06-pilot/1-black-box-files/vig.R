source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
wt <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-a01bdffa9ba941ed8/vignettes/"
sp <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/"
for (v in c("introduction", "primary_analysis_workflow")) {
  out <- paste0(sp, v, ".R")
  knitr::purl(paste0(wt, v, ".Rmd"), output = out, quiet = TRUE, documentation = 0)
  cat("\n################ vignette:", v, "\n")
  set.seed(2024)
  w(source(out, echo = TRUE, max.deparse.length = Inf, spaced = FALSE))
}
