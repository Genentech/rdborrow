args <- commandArgs(trailingOnly = TRUE)
id <- args[1]
sp <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad"
wt <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-abfdf543787540182"
src <- file.path(wt, "mutator-run", "pkgcopy")
pt <- file.path(sp, "review-pilot", "proposed-tests")
source(file.path(sp, "hand_mutants.R"))
dest <- file.path(wt, "mutator-run", paste0("prop-", gsub("[^A-Za-z0-9_.]", "_", id)))
unlink(dest, recursive = TRUE)
dir.create(dest)
file.copy(file.path(src, c("DESCRIPTION", "NAMESPACE", "R", "data", "inst")), dest, recursive = TRUE)
if (startsWith(id, "surv:")) {
  mres <- readRDS(file.path(sp, "mutator_main.rds"))
  pm <- mres$package_mutants[[sub("surv:", "", id)]]
  file.copy(pm$mutant_file, file.path(dest, "R", basename(pm$src)), overwrite = TRUE)
} else if (id != "orig") {
  for (one in strsplit(id, "+", fixed = TRUE)[[1]]) {
    m <- hm[[one]]
    path <- file.path(dest, m$file)
    orig <- readChar(path, file.size(path), useBytes = TRUE)
    stopifnot(length(gregexpr(m$old, orig, fixed = TRUE)[[1]]) == 1)
    writeChar(sub(m$old, m$new, orig, fixed = TRUE), path, eos = NULL, useBytes = TRUE)
  }
}
suppressMessages(pkgload::load_all(dest, quiet = TRUE, export_all = TRUE, helpers = FALSE))
library(testthat)
env <- new.env(parent = asNamespace("rdborrow"))
sys.source(file.path(pt, "helper-independent.R"), envir = env)
res <- testthat::test_file(file.path(pt, "test-ec_independent.R"), env = env, reporter = "silent")
df <- as.data.frame(res)
cat(sprintf("[%s] %s: %s\n", id, df$test, ifelse(df$failed > 0 | df$error, "FAIL", "pass")), sep = "")
only <- Sys.getenv("SHOW")
if (nzchar(only)) {
  for (t in res) {
    if (!startsWith(t$test, only)) next
    for (r in t$results) {
      if (inherits(r, c("expectation_failure", "expectation_error"))) {
        msg <- strsplit(conditionMessage(r), "\n")[[1]]
        cat("   >", head(msg[nzchar(msg)], 6), sep = "\n   > ")
        cat("\n")
      }
    }
  }
}
unlink(dest, recursive = TRUE)
