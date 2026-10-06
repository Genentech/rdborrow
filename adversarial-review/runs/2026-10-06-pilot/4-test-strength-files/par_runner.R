args <- commandArgs(trailingOnly = TRUE)
mode <- args[1]
ncores <- as.integer(args[2])
only <- args[-(1:2)]
sp <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad"
wt <- "/home/matts/Documents/rdborrow/.claude/worktrees/agent-abfdf543787540182"
src <- file.path(wt, "mutator-run", "pkgcopy")
outdir <- file.path(sp, mode)
dir.create(outdir, showWarnings = FALSE)

if (mode == "hand") {
  source(file.path(sp, "hand_mutants.R"))
  jobs <- lapply(names(hm), \(id) {
    m <- hm[[id]]
    orig <- readChar(file.path(src, m$file), file.size(file.path(src, m$file)), useBytes = TRUE)
    hits <- gregexpr(m$old, orig, fixed = TRUE)[[1]]
    stopifnot(length(hits) == 1, hits[1] > 0)
    list(id = id, file = m$file, content = sub(m$old, m$new, orig, fixed = TRUE))
  })
} else {
  res <- readRDS(file.path(sp, "mutator_main.rds"))
  st <- unlist(res$test_results)
  ids <- names(st)[st == "SURVIVED"]
  jobs <- lapply(ids, \(id) {
    pm <- res$package_mutants[[id]]
    f <- file.path("R", basename(pm$src))
    list(id = id, file = f, content = readChar(pm$mutant_file, file.size(pm$mutant_file), useBytes = TRUE))
  })
}
names(jobs) <- vapply(jobs, \(j) j$id, "")
if (length(only)) jobs <- jobs[only]

run_job <- function(j) {
  dest <- file.path(wt, "mutator-run", paste0(mode, "-", j$id))
  unlink(dest, recursive = TRUE)
  dir.create(dest)
  file.copy(file.path(src, c("DESCRIPTION", "NAMESPACE", "R", "data", "inst", "tests")), dest, recursive = TRUE)
  path <- file.path(dest, j$file)
  orig <- readChar(path, file.size(path), useBytes = TRUE)
  mut_copy <- file.path(outdir, paste0(j$id, ".mutant.R"))
  writeChar(j$content, mut_copy, eos = NULL, useBytes = TRUE)
  orig_copy <- file.path(outdir, paste0(j$id, ".orig.R"))
  writeChar(orig, orig_copy, eos = NULL, useBytes = TRUE)
  d <- suppressWarnings(system2("diff", c("-u", shQuote(orig_copy), shQuote(mut_copy)), stdout = TRUE))
  d[1] <- paste("---", j$file)
  d[2] <- paste("+++", j$file, "(mutant)")
  writeLines(d, file.path(outdir, paste0(j$id, ".diff")))
  unlink(c(orig_copy, mut_copy))
  writeChar(j$content, path, eos = NULL, useBytes = TRUE)
  out <- file.path(outdir, paste0(j$id, ".out"))
  t0 <- Sys.time()
  system2("Rscript", c(file.path(sp, "run_tests_dir.R"), dest, out),
    env = c("NOT_CRAN=true", "OMP_NUM_THREADS=1", "OPENBLAS_NUM_THREADS=1"),
    stdout = FALSE, stderr = FALSE
  )
  unlink(dest, recursive = TRUE)
  r <- if (file.exists(out)) readLines(out) else "NO OUTPUT"
  sprintf(
    "%s %.0fs\n  %s", j$id, as.numeric(difftime(Sys.time(), t0, units = "secs")),
    paste(r, collapse = "\n  ")
  )
}
res <- parallel::mclapply(jobs, run_job, mc.cores = ncores, mc.preschedule = FALSE)
writeLines(unlist(res), file.path(sp, paste0(mode, "_summary.txt")))
