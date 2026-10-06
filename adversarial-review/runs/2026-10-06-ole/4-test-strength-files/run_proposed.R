# usage: Rscript run_proposed.R <pkg_dir> [file filter]
args <- commandArgs(trailingOnly = TRUE)
pkg <- args[1]
flt <- if (length(args) > 1) args[2] else "."
Sys.setenv(NOT_CRAN = "true")
suppressMessages(pkgload::load_all(pkg, quiet = TRUE, export_all = TRUE, helpers = FALSE))
pdir <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/proposed-tests"
sys.source(file.path(pdir, "helper-ole.R"), envir = globalenv())
files <- list.files(pdir, pattern = "^test-.*[.]R$")
files <- files[grepl(flt, files)]
d <- do.call(rbind, lapply(files, function(f) {
  r <- testthat::test_file(file.path(pdir, f), reporter = "silent",
    stop_on_failure = FALSE, package = "rdborrow", load_package = "none",
    env = new.env(parent = globalenv()))
  x <- as.data.frame(r)
  x$file <- f
  x
}))
for (i in seq_len(nrow(d))) {
  cat(sprintf("%-6s %5.1fs %s :: %s\n",
    if (d$failed[i] > 0 || d$error[i]) "FAIL" else if (d$skipped[i]) "SKIP" else "PASS",
    d$real[i], d$file[i], d$test[i]))
}
