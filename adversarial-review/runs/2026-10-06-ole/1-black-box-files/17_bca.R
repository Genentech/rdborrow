# bca intervals with small bootstrap counts, and for scm()
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
a <- commandArgs(TRUE)
if ("did" %in% a) {
  for (B in c(2, 10, 20, 50, 299, 400)) {
    set.seed(1)
    t0 <- Sys.time()
    r <- show(ole(did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = B, bootstrap_ci_type = "bca")))
    cat("B =", B, sprintf("[%.1fs]", as.numeric(Sys.time() - t0, units = "secs")), "\n")
    print(r)
  }
}
if ("scm" %in% a) {
  for (ty in c("norm", "basic", "bca")) {
    set.seed(1)
    t0 <- Sys.time()
    r <- show(ole(scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 4, bootstrap_ci_type = ty)))
    cat("scm", ty, sprintf("[%.1fs]", as.numeric(Sys.time() - t0, units = "secs")), "\n")
    print(r)
  }
}
