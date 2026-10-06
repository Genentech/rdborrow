# usage: Rscript run_tests_in.R <pkg_dir> <test filter regex>
args <- commandArgs(trailingOnly = TRUE)
pkg <- args[1]
flt <- args[2]
Sys.setenv(NOT_CRAN = "true")
suppressMessages(pkgload::load_all(pkg, quiet = TRUE, export_all = TRUE, helpers = TRUE))
files <- list.files(file.path(pkg, "tests/testthat"), pattern = "^test-.*[.]R$")
files <- files[grepl(flt, files)]
out <- lapply(files, function(f) {
  r <- testthat::test_file(file.path(pkg, "tests/testthat", f),
    reporter = "silent", stop_on_failure = FALSE, package = "rdborrow",
    load_package = "none"
  )
  d <- as.data.frame(r)
  d$file <- f
  d
})
d <- do.call(rbind, out)
bad <- d[d$failed > 0 | d$error, c("file", "test", "failed", "error")]
cat("TESTFILES:", paste(files, collapse = ","), "\n")
cat("PASSED_EXPECTATIONS:", sum(d$passed), " FAILED_TESTS:", nrow(bad), "\n")
if (nrow(bad) > 0) {
  for (i in seq_len(nrow(bad))) {
    cat(sprintf("KILLED_BY: %s :: %s%s\n", bad$file[i], bad$test[i],
      if (bad$error[i]) " [error]" else ""))
  }
} else {
  cat("SURVIVED\n")
}
