# bootstrap_ci_type, alpha, bootstrap counts for DID methods
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
y4 <- c("y1", "y2", "y3", "y4")
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
cat("\n#### ci types (did_ec_ipw, B = 200)\n")
for (ty in list(NULL, "perc", "norm", "basic", "bca", "stud", "all", c("perc", "norm"), "foo", NA)) {
  cat("\n## bootstrap_ci_type =", deparse(ty), "\n")
  m <- show(did_ec_ipw(ps, bootstrap = 200, bootstrap_ci_type = ty))
  if (!is.null(m)) {
    set.seed(1)
    print(show(ole(m)))
  }
}
cat("\n#### alpha (did_ec_ipw, perc, B = 400)\n")
for (a in list(0.05, 0.2, 0.5, 0.01, 0, 1, -0.1, 1.5, NA, c(0.05, 0.1))) {
  cat("\n## alpha =", deparse(a), "\n")
  set.seed(1)
  print(show(ole(did_ec_ipw(ps, bootstrap = 400), alpha = a)))
}
cat("\n#### bootstrap counts\n")
for (b in list(NULL, 0, 1, 2, 3, 2.5, -5, NA, "10", TRUE, 1e9)) {
  cat("\n## bootstrap =", deparse(b), "\n")
  m <- show(did_ec_ipw(ps, bootstrap = b))
  if (!is.null(m) && !identical(b, 1e9)) {
    set.seed(1)
    print(show(ole(m)))
  } else if (!is.null(m)) cat("constructed OK; not run\n")
}
cat("\n#### the same for did_ec_or and did_ec_aipw: bootstrap NULL / 1 / 2\n")
for (b in list(NULL, 1, 2)) {
  cat("\n## bootstrap =", deparse(b), "\n")
  m <- show(did_ec_or(f5(y4), f5(y4), f5(y4), bootstrap = b))
  if (!is.null(m)) print(show(ole(m)))
  m <- show(did_ec_aipw(ps, outcome_formula = f5(y4), bootstrap = b))
  if (!is.null(m)) print(show(ole(m)))
  m <- show(scm(bootstrap = b))
}
