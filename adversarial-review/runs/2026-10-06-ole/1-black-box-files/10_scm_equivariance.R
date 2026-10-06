# scm(): multiplying every covariate and every outcome by k multiplies the Eq. 7
# objective by k^2 for every lambda, so the weights, and hence tau / k, must not
# change (Zhou et al. 2024, Eq. 7-9). Adding a constant to one covariate leaves
# Eq. 7 unchanged because the weights sum to one.
# no bootstrap needed for the point estimate, but bootstrap >= 2 is required
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
k <- as.numeric(commandArgs(TRUE)[1])
cols <- c(paste0("x", 1:5), paste0("y", 1:4))
d <- SyntheticData
d[cols] <- d[cols] * k
set.seed(7)
r <- show(ole(scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2), data = d))
cat("k =", k, " tau / k =", r$point_estimates / k, "\n")
