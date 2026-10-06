# missing values: is the result the complete-case analysis, or something else?
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
cat("SyntheticData columns:", names(SyntheticData), "\n")
print(table(SyntheticData$T_cross))
y <- c("y1", "y2", "y3", "y4")
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
pt <- function(...) {
  set.seed(1)
  r <- show(suppressWarnings(ole(...)))
  if (!is.null(r)) r$point_estimates
}
ipw <- did_ec_ipw(ps, bootstrap = 2)
or <- did_ec_or(f5(y), f5(y), f5(y), bootstrap = 2)
for (rows in list(c(1, 3, 5), c(2, 4, 6), which(SyntheticData$S == 0)[1:3])) {
  cat("\n## NA in x5 at rows", rows, " (S =", SyntheticData$S[rows], ")\n")
  d <- SyntheticData
  d$x5[rows] <- NA
  cat("did_ec_ipw with NA rows:       ", pt(ipw, data = d), "\n")
  cat("did_ec_ipw complete cases only:", pt(ipw, data = SyntheticData[-rows, ]), "\n")
}
cat("\n## NA in y3 at rows 1, 3, 5\n")
d <- SyntheticData
d$y3[c(1, 3, 5)] <- NA
cat("did_ec_or with NA rows:        ", pt(or, data = d), "\n")
cat("did_ec_or complete cases only: ", pt(or, data = SyntheticData[-c(1, 3, 5), ]), "\n")
