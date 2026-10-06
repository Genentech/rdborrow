source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/n3/lib.R")
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/3-independent-implementation.R")
d <- SyntheticData
covs <- c("x1", "x2", "x3", "x4", "x5")
Xps <- ind_design(d, covs)
est <- function(m, ys = c("y1", "y2")) {
  estimate(m, data = d, outcomes = ys, treatment = "A", trial_status = "S", covariates = covs)
}

cat("== different outcome formula per time ==\n")
of <- c("y1 ~ x1 + x2", "y2 ~ x3 + x4 + x5")
r <- est(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", of, weight = 0.4))
Xo <- list(ind_design(d, c("x1", "x2")), ind_design(d, c("x3", "x4", "x5")))
f <- ind_ec(d, c("y1", "y2"), Xps, Xo, aipw = TRUE, w = 0.4)
s <- ind_sandwich(f, d, c("y1", "y2"), Xps, Xo, aipw = TRUE)
print(cbind(pkg_tau = r$results$point_estimates, ind_tau = f$tau, pkg_se = r$results$standard_deviation, ind_se = s$se_full))

cat("== poly() and ns() in outcome formula vs explicit basis ==\n")
d$x5sq <- d$x5^2
r_explicit <- estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", c("y1 ~ x5 + x5sq", "y2 ~ x5 + x5sq"), weight = 0.4),
  data = d, outcomes = c("y1", "y2"), treatment = "A", trial_status = "S", covariates = c(covs, "x5sq")
)
r_poly <- est(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", c("y1 ~ poly(x5, 2)", "y2 ~ poly(x5, 2)"), weight = 0.4))
print(cbind(explicit = r_explicit$results[, 1:2], poly = r_poly$results[, 1:2]))

r_ns <- est(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", c("y1 ~ splines::ns(x5, df = 3)", "y2 ~ splines::ns(x5, df = 3)"), weight = 0.4))
# independent: the point estimate's basis is ns() built on the controls (A == 0)
ctrl <- d$A == 0
B_ctrl <- splines::ns(d$x5[ctrl], df = 3)
Xns <- cbind(1, predict(B_ctrl, d$x5))
f <- ind_ec(d, c("y1", "y2"), Xps, Xns, aipw = TRUE, w = 0.4)
s <- ind_sandwich(f, d, c("y1", "y2"), Xps, Xns, aipw = TRUE)
print(cbind(pkg_tau = r_ns$results$point_estimates, ind_tau = f$tau, pkg_se = r_ns$results$standard_deviation, ind_se = s$se_full))
cat("ns knots on controls:", attr(B_ctrl, "knots"), " on all:", attr(splines::ns(d$x5, df = 3), "knots"), "\n")
