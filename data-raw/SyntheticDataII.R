## code to prepare `SyntheticDataII` dataset
## An unbalanced companion to SyntheticData: 2:1 randomization (160 treated,
## 80 controls), 140 external controls, and a shift in a binary covariate
## (x1) between the trial and the external controls. The outcome models are
## the same as in SyntheticData.
## Based on real clinical trial summary statistics (SMA study)
## Covariates are generated via copula to mimic realistic correlation structure

library(copula)
library(rdborrow)

set.seed(202610)

# ===== Copula for correlated covariates =====
normal <- copula::normalCopula(param = c(0.8), dim = 4, dispstr = "ar1")

# ===== Generate internal (RCT) covariates =====
# x1 = SMA_Type (0 = Type II, 1 = Type III)
# x2 = SMN2_Copy_Number (0 = 3 copies, 1 = 4 copies)
# x3 = Scoliosis (0 = No, 1 = Yes)
# x4 = Age_Enrollment
X_int <- simulate_X_copula(
  n = 240,
  p = 4,
  cp = normal,
  margins = c("binom", "binom", "binom", "exp"),
  paramMargins = list(
    list(size = 1, prob = 0.7),
    list(size = 1, prob = 0.9),
    list(size = 1, prob = 0.3),
    list(rate = 1 / 10)
  )
)

X_int$x4 <- round(X_int$x4) + 1
# x5 = Baseline outcome (Y0), modeled as linear function of covariates
X_int$x5 <- 30 + 10 * X_int$x1 + 7 * X_int$x2 +
  (-6) * X_int$x3 + (-0.5) * X_int$x4 +
  rnorm(240, mean = 0, sd = 10)

# ===== Generate external control covariates =====
X_ext <- simulate_X_copula(
  n = 140,
  p = 4,
  cp = normal,
  margins = c("binom", "binom", "binom", "exp"),
  paramMargins = list(
    list(size = 1, prob = 0.5),
    list(size = 1, prob = 0.9),
    list(size = 1, prob = 0.3),
    list(rate = 1 / 10)
  )
)

X_ext$x4 <- round(X_ext$x4) + 1
# External baseline outcome has different coefficients, and a smaller
# intercept shift than in SyntheticData, so that the participation model has
# good overlap
X_ext$x5 <- 35 + 10 * X_ext$x1 + 2 * X_ext$x2 +
  (-1) * X_ext$x3 + (-0.3) * X_ext$x4 +
  rnorm(140, mean = 0, sd = 10)

# ===== Outcome model specifications =====
varnames <- c("1", paste0("x", 1:5))

# Coefficients: intercept, SMA_Type, SMN2_Copy, Scoliosis, Age, Y0
# Treatment effect (A) and noise SD noted in comments
model_form_x_t1 <- setNames(
  c(10.0, 0.05, -1.5, -1.0, -0.2, -0.1), varnames
) # effect = 1.5, sigma = 4.0

model_form_x_t2 <- setNames(
  c(6.0, 0.5, -0.5, -1.0, -0.3, -0.06), varnames
) # effect = 1.8, sigma = 4.0

model_form_x_t3 <- setNames(
  c(5.0, 1.9, 1.4, -1.3, -0.4, -0.15), varnames
) # effect = 1.6, sigma = 4.0

model_form_x_t4 <- setNames(
  c(1.2, 1.0, 2.0, -0.5, -0.4, -0.10), varnames
) # effect = 2.5, sigma = 5.0

outcome_model_specs <- list(
  list(
    effect = 0, model_form_x = model_form_x_t1,
    noise_mean = 0, noise_sd = 4
  ),
  list(
    effect = 1.0, model_form_x = model_form_x_t2,
    noise_mean = 0, noise_sd = 4
  ),
  list(
    effect = 2.0, model_form_x = model_form_x_t3,
    noise_mean = 0, noise_sd = 4
  ),
  list(
    effect = 5.0, model_form_x = model_form_x_t4,
    noise_mean = 0, noise_sd = 4
  )
)

# ===== Simulate trial data =====
SyntheticDataII <- simulate_trial(
  X_int,
  X_ext,
  num_treated = 160,
  OLE_flag = TRUE,
  T_cross = 2,
  outcome_model_specs
)

# ===== Save to data/ =====
usethis::use_data(SyntheticDataII, overwrite = TRUE)
