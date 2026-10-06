args <- commandArgs(trailingOnly = TRUE)
n_mut <- as.integer(args[1])
tag <- args[2]
wt <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-abfdf543787540182"
sp <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad"
setwd(wt)
all_r <- basename(list.files(file.path(wt, "mutator-run", "pkgcopy", "R"), pattern = "\\.R$"))
in_scope <- c("ec_ipw.R", "ec_aipw.R", "ec_weights.R", "method_class.R")
excl <- setdiff(all_r, in_scope)
set.seed(20261006)
t0 <- Sys.time()
res <- mutator::mutate_package(
  pkg_dir = file.path(wt, "mutator-run", "pkgcopy"),
  cores = 12,
  isFullLog = FALSE,
  detectEqMutants = FALSE,
  mutation_dir = file.path(wt, "mutator-run", tag),
  max_mutants = n_mut,
  timeout_seconds = 300,
  max_line_deletions = 0,
  cran = FALSE,
  fail_fast = TRUE,
  isolate = TRUE,
  exclude_files = excl,
  max_show = Inf
)
print(Sys.time() - t0)
saveRDS(res, file.path(sp, paste0("mutator_", tag, ".rds")))
print(res$summary)
print(res$timing)
