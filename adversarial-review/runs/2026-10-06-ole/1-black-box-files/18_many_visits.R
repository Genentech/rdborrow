# many visits (8, T_cross = 4), large n, DGP satisfying Assumption 3 (Eq. 2):
# outcome = delta_t + theta_t' X + effect_t * A_t + Delta * S + noise
# with Delta = 2 (direct effect of trial participation), and covariate shift
# between trial and external controls. expected: DID estimates within a few
# Monte Carlo SEs of effect_t = 1, 2, 3, 4 at visits 5..8.
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
set.seed(2026)
n_int <- 4000
n_ext <- 4000
X_int <- data.frame(x1 = rnorm(n_int, 0.5), x2 = rbinom(n_int, 1, 0.6))
X_ext <- data.frame(x1 = rnorm(n_ext, 0), x2 = rbinom(n_ext, 1, 0.4))
eff <- c(0.5, 0.5, 0.5, 0.5, 1, 2, 3, 4)
specs <- lapply(1:8, \(t) list(
  effect = eff[t],
  model_form_x = c("1" = t, "x1" = 0.2 * t, "x2" = -0.1 * t),
  noise_mean = 0, noise_sd = 1
))
d <- simulate_trial(X_int, X_ext, num_treated = 2700, OLE_flag = TRUE,
                    T_cross = 4, outcome_model_specs = specs)
y <- grep("^y", names(d), value = TRUE)
if (!length(y)) y <- setdiff(names(d), c("x1", "x2", "A", "S", "T_cross"))
cat("outcome columns:", y, "\n")
for (v in y) d[[v]] <- d[[v]] + 2 * d$S
names(d)[match(y, names(d))] <- paste0("y", 1:8)
y <- paste0("y", 1:8)
cat("means by group:\n")
print(round(aggregate(d[, y], list(S = d$S, A = d$A), mean), 2))
fo <- paste(y, "~ x1 + x2")
ms <- list(
  ipw = did_ec_ipw("S ~ x1 + x2", bootstrap = 20),
  aipw = did_ec_aipw("S ~ x1 + x2", outcome_formula = fo, bootstrap = 20),
  or = did_ec_or(fo, fo, fo, bootstrap = 20)
)
for (m in names(ms)) {
  set.seed(1)
  r <- show(suppressWarnings(ole(ms[[m]], data = d, outcomes = y, T_cross = 4, cov = c("x1", "x2"))))
  cat("\n##", m, " (truth 1, 2, 3, 4)\n")
  print(round(r, 3))
}
