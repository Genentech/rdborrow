# usage: Rscript drive_proposed.R <id-regex>
# applies each selected hand mutant (or mutator mutant file "mut:<file>:<mutant file>")
# and runs the proposed tests against it.
art <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/4-test-strength-artifacts"
pkg <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-a81ea1649fef0ead6"
source(file.path(art, "hand_mutants.R"))
args <- commandArgs(trailingOnly = TRUE)
sel <- args[1]
pristine <- file.path(art, "handpkg")
work <- file.path(art, "propwork")
dir.create(work, showWarnings = FALSE)
dir.create(file.path(art, "proposed_logs"), showWarnings = FALSE)

flt_for <- function(file) {
  switch(file,
    "did_ec_ipw.R" = "did_ec_ipw|method_class",
    "did_ec_aipw.R" = "did_ec_aipw|method_class",
    "did_ec_or.R" = "did_ec_or|method_class",
    "scm.R" = "scm|method_class",
    "method_class.R" = "method_class"
  )
}

todo <- Filter(function(x) grepl(sel, x$id), hand_mutants)
extra <- if (length(args) > 1) strsplit(args[2], ",")[[1]] else character()
for (e in extra) {
  dir <- if (grepl("^scm", e)) ".mutants-scm" else ".mutants-did"
  todo[[length(todo) + 1]] <- list(id = paste0("MUT_", sub("[.]R$", "", e)),
    file = sub("_[0-9]+[.]R$", "", e), mutant = file.path(pkg, dir, e))
}

run_one <- function(mu) {
  d <- file.path(work, mu$id)
  unlink(d, recursive = TRUE)
  dir.create(d)
  file.copy(list.files(pristine, full.names = TRUE), d, recursive = TRUE)
  f <- file.path(d, "R", mu$file)
  if (!is.null(mu$mutant)) {
    file.copy(mu$mutant, f, overwrite = TRUE)
  } else {
    src <- paste(readLines(f), collapse = "\n")
    for (k in seq_along(mu$old)) src <- gsub(mu$old[k], mu$new[k], src, fixed = TRUE)
    writeLines(src, f)
  }
  out <- system2("Rscript", c(file.path(art, "run_proposed.R"), d, shQuote(flt_for(mu$file))),
    stdout = TRUE, stderr = TRUE)
  writeLines(out, file.path(art, "proposed_logs", paste0(mu$id, ".log")))
  unlink(d, recursive = TRUE)
  fails <- sub("^FAIL +[0-9.]+s ", "", grep("^FAIL", out, value = TRUE))
  data.frame(id = mu$id, n_fail = length(fails), failing = paste(fails, collapse = " | "))
}
res <- do.call(rbind, parallel::mclapply(todo, run_one, mc.cores = 6, mc.preschedule = FALSE))
write.csv(res, file.path(art, paste0("proposed_vs_mutants_", gsub("[^A-Za-z0-9]", "_", sel), ".csv")), row.names = FALSE)
print(res, right = FALSE)
