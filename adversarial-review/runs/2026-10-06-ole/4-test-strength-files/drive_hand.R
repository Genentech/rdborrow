# usage: Rscript drive_hand.R [id-regex]
art <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/4-test-strength-artifacts"
source(file.path(art, "hand_mutants.R"))
args <- commandArgs(trailingOnly = TRUE)
sel <- if (length(args)) args[1] else "."
pristine <- file.path(art, "handpkg")
work <- file.path(art, "handwork")
dir.create(work, showWarnings = FALSE)
dir.create(file.path(art, "hand_diffs"), showWarnings = FALSE)
dir.create(file.path(art, "hand_logs"), showWarnings = FALSE)
tests_for <- attr(hand_mutants, "tests")
todo <- Filter(function(x) grepl(sel, x$id), hand_mutants)

run_one <- function(mu) {
  d <- file.path(work, mu$id)
  unlink(d, recursive = TRUE)
  dir.create(d)
  file.copy(list.files(pristine, full.names = TRUE), d, recursive = TRUE)
  f <- file.path(d, "R", mu$file)
  src <- paste(readLines(f), collapse = "\n")
  for (k in seq_along(mu$old)) {
    hits <- lengths(regmatches(src, gregexpr(mu$old[k], src, fixed = TRUE)))
    want <- if (length(mu$old) > 1) 1 else mu$n
    if (hits != want) stop(mu$id, ": pattern ", k, " matched ", hits, " times")
    src <- gsub(mu$old[k], mu$new[k], src, fixed = TRUE)
  }
  writeLines(src, f)
  diff <- system2("diff", c("-u", file.path(pristine, "R", mu$file), f), stdout = TRUE)
  diff <- sub(pristine, "a", diff, fixed = TRUE)
  diff <- sub(d, "b", diff, fixed = TRUE)
  writeLines(diff, file.path(art, "hand_diffs", paste0(mu$id, ".diff")))
  flt <- tests_for(mu$file)
  t0 <- Sys.time()
  out <- system2("Rscript", c(file.path(art, "run_tests_in.R"), d, shQuote(flt)),
    stdout = TRUE, stderr = TRUE
  )
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  log <- c(paste("#", mu$id, "-", mu$desc), paste("# test filter:", flt),
    paste("# runtime (s):", round(el, 1)), out)
  writeLines(log, file.path(art, "hand_logs", paste0(mu$id, ".log")))
  unlink(d, recursive = TRUE)
  killed <- grep("^KILLED_BY", out, value = TRUE)
  data.frame(
    id = mu$id, file = mu$file, desc = mu$desc,
    status = if (length(killed)) "KILLED" else if (any(grepl("^SURVIVED", out))) "SURVIVED" else "ERROR",
    killed_by = paste(sub("^KILLED_BY: ", "", killed), collapse = " | "),
    secs = round(el, 1)
  )
}

res <- parallel::mclapply(todo, run_one, mc.cores = 6, mc.preschedule = FALSE)
res <- do.call(rbind, lapply(res, function(x) if (inherits(x, "try-error")) data.frame(id = NA, file = NA, desc = as.character(x), status = "DRIVER_ERROR", killed_by = "", secs = NA) else x))
outfile <- file.path(art, paste0("hand_results_", gsub("[^A-Za-z0-9]", "_", sel), ".csv"))
write.csv(res, outfile, row.names = FALSE)
print(res[, c("id", "status", "killed_by")], right = FALSE)
