# data and column-mapping contracts of setup_analysis_OLE() with the DID methods
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
y <- c("y1", "y2", "y3", "y4")
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
tf <- "A ~ x1 + x2 + x3 + x4 + x5"
ipw <- did_ec_ipw(ps, bootstrap = 2)
ipw_t <- did_ec_ipw(ps, trt_formula = tf, bootstrap = 2)
aipw <- did_ec_aipw(ps, outcome_formula = f5(y), bootstrap = 2)
or <- did_ec_or(f5(y), f5(y), f5(y), bootstrap = 2)
pt <- function(...) {
  set.seed(1)
  r <- show(ole(...))
  if (!is.null(r)) print(r$point_estimates)
}
cat("\n## baseline ipw / ipw+trt / aipw / or\n")
pt(ipw); pt(ipw_t); pt(aipw); pt(or)

cat("\n## treatment column renamed to arm, trt_formula uses arm\n")
d <- SyntheticData
names(d)[names(d) == "A"] <- "arm"
pt(ipw, data = d, trt = "arm")
pt(did_ec_ipw(ps, trt_formula = "arm ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2), data = d, trt = "arm")
pt(did_ec_ipw(ps, trt_formula = tf, bootstrap = 2), data = d, trt = "arm")
pt(or, data = d, trt = "arm")
pt(aipw, data = d, trt = "arm")

cat("\n## covariates_col_name narrower than the formulas\n")
pt(ipw, cov = "x1")
pt(aipw, cov = "x1")
pt(or, cov = "x1")
cat("## covariates_col_name wider than the formulas (x1..x5) vs formula on x1 only\n")
pt(did_ec_ipw("S ~ x1", bootstrap = 2))
pt(did_ec_ipw("S ~ x1", bootstrap = 2), cov = "x1")

cat("\n## dot in did_ec_or and trt_formula\n")
pt(did_ec_or(paste(y, "~ ."), paste(y, "~ ."), paste(y, "~ ."), bootstrap = 2))
pt(did_ec_ipw(ps, trt_formula = "A ~ .", bootstrap = 2))

cat("\n## external controls with A = 1 (#108)\n")
d <- SyntheticData
d$A[d$S == 0][1:20] <- 1
pt(ipw, data = d); pt(aipw, data = d); pt(or, data = d)

cat("\n## missing outcome values\n")
d <- SyntheticData
d$y3[c(1, 3, 5)] <- NA
pt(ipw, data = d); pt(aipw, data = d); pt(or, data = d)
cat("## missing covariate values\n")
d <- SyntheticData
d$x5[c(1, 3, 5)] <- NA
pt(ipw, data = d); pt(aipw, data = d); pt(or, data = d)

cat("\n## treatment coded 1/2, logical, factor; trial status logical\n")
d <- SyntheticData; d$A <- d$A + 1
pt(ipw, data = d)
d <- SyntheticData; d$A <- as.logical(d$A)
pt(ipw, data = d); pt(or, data = d)
d <- SyntheticData; d$A <- factor(d$A, labels = c("pbo", "drug"))
pt(ipw, data = d)
d <- SyntheticData; d$S <- as.logical(d$S)
pt(ipw, data = d); pt(or, data = d)

cat("\n## duplicated / missing outcome names\n")
pt(ipw, outcomes = c("y1", "y1", "y3", "y4"))
pt(ipw, outcomes = c("y1", "y2", "y3", "nope"))

cat("\n## no trial controls\n")
d <- SyntheticData[!(SyntheticData$S == 1 & SyntheticData$A == 0), ]
pt(ipw, data = d); pt(or, data = d)

cat("\n## tibble input\n")
pt(ipw, data = tibble::as_tibble(SyntheticData))
pt(or, data = tibble::as_tibble(SyntheticData))

cat("\n## primary method passed to setup_analysis_OLE\n")
show(setup_analysis_OLE(SyntheticData, "S", "A", y, paste0("x", 1:5), ec_ipw(ps), T_cross = 2))
cat("## OLE method passed to setup_analysis_primary\n")
show(setup_analysis_primary(SyntheticData, "S", "A", y, paste0("x", 1:5), ipw))

cat("\n## quiet = FALSE\n")
set.seed(1)
a <- setup_analysis_OLE(SyntheticData, "S", "A", y, paste0("x", 1:5), ipw, T_cross = 2)
r <- run_analysis(a, quiet = FALSE)
cat("## run_analysis(quiet = 'no')\n")
show(run_analysis(a, quiet = "no"))

cat("\n## reproducibility: same seed twice\n")
set.seed(3); r1 <- run_analysis(setup_analysis_OLE(SyntheticData, "S", "A", y, paste0("x", 1:5), did_ec_ipw(ps, bootstrap = 50), T_cross = 2))
set.seed(3); r2 <- run_analysis(setup_analysis_OLE(SyntheticData, "S", "A", y, paste0("x", 1:5), did_ec_ipw(ps, bootstrap = 50), T_cross = 2))
print(identical(r1, r2))
