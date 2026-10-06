pkg <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-a81ea1649fef0ead6"
targets <- c("scm.R")
others <- setdiff(basename(list.files(file.path(pkg, "R"), pattern = "[.]R$")), targets)
set.seed(20261007)
t0 <- Sys.time()
res <- mutator::mutate_package(
  pkg_dir = pkg,
  cores = 8,
  detectEqMutants = FALSE,
  mutation_dir = file.path(pkg, ".mutants-scm"),
  max_mutants = 80,
  timeout_seconds = 600,
  cran = FALSE,
  isolate = TRUE,
  exclude_files = others,
  max_show = Inf
)
cat("wall time:", format(Sys.time() - t0), "\n")
saveRDS(res, "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/4-test-strength-artifacts/mutator_scm.rds")
str(res$summary)
str(res$timing)
