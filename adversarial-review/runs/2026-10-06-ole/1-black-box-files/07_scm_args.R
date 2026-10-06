# scm() constructor contracts (no estimation)
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
args <- list(
  list(lambda_min = 0.1, lambda_max = 0),
  list(lambda_min = -1, lambda_max = 0.1),
  list(lambda_min = 0, lambda_max = Inf),
  list(lambda_min = 0, lambda_max = 0.1, nlambda = 1),
  list(lambda_min = 0.05, lambda_max = 0.05, nlambda = 5),
  list(nlambda = 0),
  list(nlambda = 2.5),
  list(nlambda = NA),
  list(lambda_min = NA),
  list(lambda_min = c(0, 1)),
  list(parallel = "foo"),
  list(parallel = "multicore", ncpus = 0),
  list(parallel = "no", ncpus = 4),
  list(parallel = "snow", ncpus = 2),
  list(ncpus = 2.5),
  list(bootstrap = 1),
  list(bootstrap = 2),
  list(bootstrap = NULL),
  list(bootstrap_ci_type = "bca")
)
for (a in args) {
  cat("\n## scm(", paste(names(a), sapply(a, deparse), sep = " = ", collapse = ", "), ")\n")
  m <- show(do.call(scm, a))
  if (!is.null(m)) cat("accepted\n")
}
