# usage: Rscript mutant_diffs.R <mutants dir> <csv> <out file>
# writes a compact diff (deparsed original vs mutant) for each non-killed mutant
args <- commandArgs(trailingOnly = TRUE)
pkg <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-a81ea1649fef0ead6"
info <- read.csv(args[2])
info <- info[info$status != "KILLED", ]
norm <- function(path) {
  ex <- parse(path, keep.source = FALSE)
  unlist(lapply(ex, function(e) c(deparse(e), "")))
}
out <- character()
for (i in seq_len(nrow(info))) {
  a <- tempfile()
  b <- tempfile()
  writeLines(norm(file.path(pkg, "R", info$file[i])), a)
  writeLines(norm(file.path(args[1], info$mutant_file[i])), b)
  d <- suppressWarnings(system2("diff", c("-U0", a, b), stdout = TRUE))
  d <- d[!grepl("^(---|\\+\\+\\+)", d)]
  out <- c(out, sprintf("### %s %s:%d %s [%s]", info$status[i], info$file[i], info$line[i], info$details[i], info$mutant_file[i]), d, "")
}
writeLines(out, args[3])
