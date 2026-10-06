args <- commandArgs(trailingOnly = TRUE)
ncores <- as.integer(args[1])
ids <- args[-1]
if (length(ids) == 1 && startsWith(ids, "@")) ids <- scan(sub("@", "", ids), what = "", quiet = TRUE)
sp <- "/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad"
out <- parallel::mclapply(ids, \(id) {
  r <- system2("Rscript", c(file.path(sp, "run_prop.R"), shQuote(id)),
    stdout = TRUE, stderr = FALSE,
    env = c("OMP_NUM_THREADS=1", "OPENBLAS_NUM_THREADS=1")
  )
  grep("^\\[[A-Za-z]", r, value = TRUE)
}, mc.cores = ncores, mc.preschedule = FALSE)
f <- file.path(sp, "prop_results.txt")
cat(unlist(out), sep = "\n", file = f, append = TRUE)
