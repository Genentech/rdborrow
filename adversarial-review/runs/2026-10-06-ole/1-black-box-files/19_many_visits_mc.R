# Monte Carlo version of 18_many_visits.R: 40 replicates, n_int = n_ext = 2000.
# pre-registered expectation: mean bias of each DID estimator at each OLE visit
# within 3 Monte Carlo SEs of zero (DGP satisfies Assumption 3 and both
# nuisance models are correctly specified: logit P(S = 1 | X) is linear in
# x1, x2 because x1 | S is normal with equal variances and x2 | S is Bernoulli)
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
eff <- c(0.5, 0.5, 0.5, 0.5, 1, 2, 3, 4)
specs <- lapply(1:8, \(t) list(
  effect = eff[t],
  model_form_x = c("1" = t, "x1" = 0.2 * t, "x2" = -0.1 * t),
  noise_mean = 0, noise_sd = 1
))
y <- paste0("y", 1:8)
fo <- paste(y, "~ x1 + x2")
ms <- list(
  ipw = did_ec_ipw("S ~ x1 + x2", bootstrap = 2),
  aipw = did_ec_aipw("S ~ x1 + x2", outcome_formula = fo, bootstrap = 2),
  or = did_ec_or(fo, fo, fo, bootstrap = 2)
)
one <- function(seed) {
  set.seed(seed)
  X_int <- data.frame(x1 = rnorm(2000, 0.5), x2 = rbinom(2000, 1, 0.6))
  X_ext <- data.frame(x1 = rnorm(2000, 0), x2 = rbinom(2000, 1, 0.4))
  d <- simulate_trial(X_int, X_ext, num_treated = 1350, OLE_flag = TRUE,
                      T_cross = 4, outcome_model_specs = specs)
  yy <- setdiff(names(d), c("x1", "x2", "A", "S", "T_cross"))
  for (v in yy) d[[v]] <- d[[v]] + 2 * d$S
  names(d)[match(yy, names(d))] <- y
  sapply(ms, \(m) suppressWarnings(ole(m, data = d, outcomes = y, T_cross = 4, cov = c("x1", "x2")))$point_estimates - eff[5:8])
}
res <- lapply(1:40, one)
arr <- simplify2array(res)
cat("mean bias (rows = visits 5..8, cols = methods):\n")
print(round(apply(arr, 1:2, mean), 4))
cat("Monte Carlo SE of the mean bias:\n")
print(round(apply(arr, 1:2, sd) / sqrt(dim(arr)[3]), 4))
