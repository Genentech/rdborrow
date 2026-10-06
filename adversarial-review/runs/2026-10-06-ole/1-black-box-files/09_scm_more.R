# scm(): covariate scale, larger bootstrap, error on large covariates
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
a <- commandArgs(TRUE)
m0 <- scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2)
pt <- function(m, ...) {
  set.seed(7)
  r <- show(ole(m, ...))
  if (!is.null(r)) r$point_estimates
}
if ("scale" %in% a) {
  for (k in c(1, 10, 100, 300, 1000)) {
    d <- SyntheticData
    d$x5 <- d$x5 * k
    cat("x5 *", k, ":", pt(m0, data = d), "\n")
  }
  print(summary(SyntheticData[, paste0("x", 1:5)]))
  print(sapply(SyntheticData[, paste0("x", 1:5)], class))
}
if ("outcome_scale" %in% a) {
  for (k in c(1, 100, 1000)) {
    d <- SyntheticData
    for (v in c("y1", "y2", "y3", "y4")) d[[v]] <- d[[v]] * k
    cat("y * ", k, ":", pt(m0, data = d) / k, "(divided by k)\n")
  }
}
if ("bigB" %in% a) {
  set.seed(11)
  t0 <- Sys.time()
  r <- show(ole(scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 60,
                    bootstrap_ci_type = "norm", parallel = "multicore", ncpus = 12)))
  print(r)
  ctr <- (r$lower_CI_boot + r$upper_CI_boot) / 2
  cat("implied boot mean:", 2 * r$point_estimates - ctr, " implied bias:", r$point_estimates - ctr, "\n")
  cat("elapsed", as.numeric(Sys.time() - t0, units = "secs"), "\n")
}
if ("par" %in% a) {
  for (p in list(list("no", 1L), list("multicore", 2L), list("snow", 2L), list("no", 1L))) {
    set.seed(7)
    t0 <- Sys.time()
    r <- show(ole(scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 4,
                      parallel = p[[1]], ncpus = p[[2]])))
    cat("\n## parallel =", p[[1]], "ncpus =", p[[2]], sprintf("[%.1fs]\n", as.numeric(Sys.time() - t0, units = "secs")))
    print(r)
  }
}
