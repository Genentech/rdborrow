suppressMessages(devtools::load_all("/home/matts/Documents/rdborrow/.claude/worktrees/agent-a01bdffa9ba941ed8", quiet = TRUE))
library(testthat)
res <- testthat::test_file(
  "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/test-proposed.R",
  reporter = "summary"
)
df <- as.data.frame(res)
print(df[, c("test", "nb", "failed", "error", "passed")])
