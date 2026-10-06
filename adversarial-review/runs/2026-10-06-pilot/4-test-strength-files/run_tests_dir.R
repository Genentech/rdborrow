args <- commandArgs(trailingOnly = TRUE)
pkg <- args[1]
out <- args[2]
res <- tryCatch(
  devtools::test(pkg, reporter = "silent", stop_on_failure = FALSE),
  error = function(e) e
)
if (inherits(res, "error")) {
  writeLines(paste("KILLED (load/run error):", conditionMessage(res)), out)
} else {
  df <- as.data.frame(res)
  bad <- df[df$failed > 0 | df$error, c("file", "test", "failed", "error")]
  lines <- c(
    sprintf(
      "%s: tests %d, failing tests %d, expectations passed %d",
      if (nrow(bad)) "KILLED" else "SURVIVED", nrow(df), nrow(bad), sum(df$passed)
    ),
    if (nrow(bad)) sprintf("FAIL %s :: %s (failed=%d, error=%s)", bad$file, bad$test, bad$failed, bad$error)
  )
  writeLines(lines, out)
}
