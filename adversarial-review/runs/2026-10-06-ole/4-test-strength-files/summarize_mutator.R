art <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/4-test-strength-artifacts"
args <- commandArgs(trailingOnly = TRUE)
res <- readRDS(file.path(art, args[1]))
pm <- res$package_mutants
info <- do.call(rbind, lapply(names(pm), function(id) {
  x <- pm[[id]]
  l <- x$mutation_loc
  data.frame(id = id, status = if (is.null(x$status)) NA else x$status,
    file = basename(l$file_path), line = l$start_line, end = l$end_line,
    details = gsub("\n", "\\\\n", l$details), mutant_file = basename(x$mutant_file))
}))
print(table(info$file, info$status, useNA = "ifany"))
info <- info[order(info$file, info$line), ]
write.csv(info, file.path(art, sub("[.]rds$", "_mutants.csv", args[1])), row.names = FALSE)
s <- info[info$status != "KILLED" & !is.na(info$status), ]
for (i in seq_len(nrow(s))) cat(sprintf("%-8s %s:%d-%d %s [%s]\n", s$status[i], s$file[i], s$line[i], s$end[i], s$details[i], s$mutant_file[i]))
