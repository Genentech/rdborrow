# factor / character covariates
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
y <- c("y1", "y2", "y3", "y4")
d <- SyntheticData
d$x3 <- factor(d$x3, labels = c("no", "yes"))
pt <- function(m, ...) {
  set.seed(1)
  r <- show(suppressWarnings(ole(m, ...)))
  if (!is.null(r)) print(r$point_estimates)
}
cat("## DID methods with factor x3 (numeric 0/1 x3 for reference)\n")
pt(did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2))
pt(did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2), data = d)
pt(did_ec_or(f5(y), f5(y), f5(y), bootstrap = 2), data = d)
cat("## scm with factor x3\n")
pt(scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2), data = d)
