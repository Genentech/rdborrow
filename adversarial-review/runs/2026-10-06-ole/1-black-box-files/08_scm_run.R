# scm() estimation: lambda grid, T_cross, parallel, reproducibility
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
run <- function(label, m, ...) {
  set.seed(7)
  t0 <- Sys.time()
  r <- show(ole(m, ...))
  cat("\n##", label, sprintf("[%.1fs]", as.numeric(Sys.time() - t0, units = "secs")), "\n")
  print(r)
  invisible(r)
}
a <- commandArgs(TRUE)
if ("grid" %in% a) {
  run("default lambdas (0, 0.1, 2)", scm(bootstrap = 2))
  run("lambda 0 only", scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2))
  run("lambda 0.1 only", scm(lambda_min = 0.1, lambda_max = 0.1, nlambda = 1, bootstrap = 2))
  run("nlambda 1 with min 0 max 0.1", scm(lambda_min = 0, lambda_max = 0.1, nlambda = 1, bootstrap = 2))
  run("lambda 10 only", scm(lambda_min = 10, lambda_max = 10, nlambda = 1, bootstrap = 2))
  run("lambda_max Inf", scm(lambda_min = 0, lambda_max = Inf, nlambda = 2, bootstrap = 2))
}
if ("tcross" %in% a) {
  m <- scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2)
  run("T_cross 1", m, T_cross = 1)
  run("T_cross 3", m, T_cross = 3)
  run("one post visit", m, outcomes = c("y1", "y2", "y3"))
}
if ("par" %in% a) {
  run("serial", scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 4))
  run("multicore 2", scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 4, parallel = "multicore", ncpus = 2))
  run("snow 2", scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 4, parallel = "snow", ncpus = 2))
  run("serial again", scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 4))
}
if ("scale" %in% a) {
  m <- scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2)
  run("x5 as is", m)
  d <- SyntheticData
  d$x5 <- d$x5 * 1000
  run("x5 * 1000", m, data = d)
  d <- SyntheticData
  d$x5 <- d$x5 + 1000
  run("x5 + 1000", m, data = d)
}
if ("ci" %in% a) {
  for (ty in c("norm", "basic", "bca")) {
    run(paste("ci", ty), scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 5, bootstrap_ci_type = ty))
  }
}
