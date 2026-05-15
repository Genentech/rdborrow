#' @include ec_ipw.R
NULL

# S4 class definition----
.ec_aipw_method <- setClass(
  "ec_aipw_method",
  contains = "method_weighting_obj",
  slots = c(
    ps_formula = "character",
    outcome_formula = "character",
    weight = "numericOrNULL",
    bootstrap = "numericOrNULL",
    bootstrap_ci_type = "characterOrNULL"
  ),
  prototype = list(
    method_name = "EC-AIPW",
    ps_formula = "",
    outcome_formula = "",
    weight = NULL,
    bootstrap = NULL,
    bootstrap_ci_type = NULL
  )
)

#' EC-AIPW method
#'
#' Creates a method object for augmented IPW estimation with external
#' control borrowing (Zhou et al., 2024). Augments the IPW estimator
#' with an outcome regression model for improved efficiency. Pass to
#' \code{\link{setup_analysis_primary}} and \code{\link{run_analysis}}.
#'
#' @param ps_formula Formula string for the propensity score model
#'   predicting trial participation.
#' @param outcome_formula Character vector of outcome model formulas,
#'   one per time point (e.g., \code{c("y1 ~ x1 + x2", "y2 ~ x1 + x2")}).
#' @param weight Borrowing weight. \code{NULL} (default) for data-adaptive
#'   optimal weight, \code{0} for RCT-only, or a value in (0, 1].
#' @param bootstrap Number of bootstrap replicates, or \code{NULL}
#'   (default) for sandwich variance with normal CIs.
#' @param bootstrap_ci_type Bootstrap CI type. Defaults to \code{"perc"}.
#'
#' @return An S4 object of class \code{ec_aipw_method}.
#'
#' @references
#' Zhou et al. (2024). Causal estimators for incorporating external
#' controls in randomized trials with longitudinal outcomes.
#' \emph{JRSS-A}. \doi{10.1093/jrsssa/qnae075}
#'
#' @export
#'
#' @examples
#' # optimal weight, sandwich SE
#' ec_aipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   outcome_formula = c(
#'     "y1 ~ x1 + x2 + x3 + x4 + x5",
#'     "y2 ~ x1 + x2 + x3 + x4 + x5"
#'   )
#' )
#'
#' # no borrowing
#' ec_aipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   outcome_formula = c(
#'     "y1 ~ x1 + x2 + x3 + x4 + x5",
#'     "y2 ~ x1 + x2 + x3 + x4 + x5"
#'   ),
#'   weight = 0
#' )
#'
#' # fixed weight with bootstrap
#' ec_aipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   outcome_formula = c(
#'     "y1 ~ x1 + x2 + x3 + x4 + x5",
#'     "y2 ~ x1 + x2 + x3 + x4 + x5"
#'   ),
#'   weight = 0.3,
#'   bootstrap = 500
#' )
ec_aipw <- function(ps_formula,
                    outcome_formula,
                    weight = NULL,
                    bootstrap = NULL,
                    bootstrap_ci_type = NULL) {
  checkmate::assert_string(ps_formula)
  checkmate::assert_character(outcome_formula, min.len = 1)
  checkmate::assert_number(weight, lower = 0, upper = 1, null.ok = TRUE)
  checkmate::assert_count(bootstrap, positive = TRUE, null.ok = TRUE)

  # bootstrap type
  if (!is.null(bootstrap) && is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  if (!is.null(bootstrap_ci_type)) {
    checkmate::assert_choice(
      bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
    )
  }

  .ec_aipw_method(
    ps_formula = ps_formula,
    outcome_formula = outcome_formula,
    weight = weight,
    bootstrap = bootstrap,
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "EC-AIPW",
    bootstrap_flag = !is.null(bootstrap),
    bootstrap_obj = .bootstrap_obj(
      replicates = bootstrap %||% 500L,
      bootstrap_CI_type = bootstrap_ci_type %||% "perc"
    )
  )
}

#' @rdname estimate
setMethod("estimate", "ec_aipw_method", function(method, data, outcomes,
                                                 treatment, trial_status,
                                                 covariates, alpha = 0.05,
                                                 quiet = TRUE) {

  # unwrap formula                                            
  ps_formula <- sub("^[^~]*~", paste0(trial_status, " ~"), method@ps_formula)
  df <- .build_analysis_df(data, outcomes, treatment, trial_status, covariates)

  if (!quiet) cat("Running EC-AIPW estimator...\n")

  core <- .ec_aipw_core(df, outcomes, ps_formula,
                        method@outcome_formula, method@weight)
  sd_tau <- .ec_aipw_sandwich(df, core, length(outcomes),
                              method@outcome_formula)

  .format_primary_results(
    tau = core$tau, sd_tau = sd_tau,
    borrow_weight = core$borrow_weight,
    n_time = length(core$tau), alpha = alpha,
    method = method, df = df, quiet = quiet,
    statistic = .ec_aipw_statistic,
    outcomes = outcomes, covariates = covariates,
    ps_formula = ps_formula,
    outcome_formula = method@outcome_formula
  )
})

#' EC-AIPW point estimate (Def 2, Eq 7).
#' fits PS + outcome models, uses residuals Y-mu(X) in place of Y,
#' computes mu11/mu10/mu00 and optimal weight.
#' shared by estimate() and bootstrap statistic.
#' @param df internal data frame.
#' @param outcomes outcome column names.
#' @param ps_formula propensity score formula string.
#' @param outcome_formula character vector of outcome model formulas.
#' @param weight fixed weight or NULL for optimal.
#' @return list with tau, borrow_weight, and model intermediates.
#' @noRd
.ec_aipw_core <- function(df, outcomes, ps_formula, outcome_formula, weight) {
  Y <- as.matrix(df[, outcomes, drop = FALSE])
  S <- df$S
  A <- df$A
  N <- nrow(df)
  n <- sum(S)
  n_time <- ncol(Y)
  pi_S <- n / N

  # propensity score model
  ps_model <- glm(as.formula(ps_formula), data = df, family = "binomial")
  pi_SX <- predict(ps_model, newdata = df, type = "response")
  pi_A <- sum(A[S == 1]) / n
  rx <- (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S)

  # outcome regression on controls, predict for all subjects
  Y0_models <- lapply(outcome_formula, \(f) {
    lm(as.formula(f), data = df[A == 0, , drop = FALSE])
  })
  Y0 <- vapply(seq_len(n_time), \(t) {
    predict(Y0_models[[t]], newdata = df)
  }, numeric(N))
  Yr <- Y - Y0

  # weighted potential outcomes using residuals
  w00 <- rx
  potential <- (S * A / pi_A + S * (1 - A) / (1 - pi_A) +
    (1 - S) * w00) * Yr
  mu1 <- colSums(potential[S == 1 & A == 1, , drop = FALSE]) / n
  mu10 <- colSums(potential[S == 1 & A == 0, , drop = FALSE]) / n
  mu00 <- colSums(potential[S == 0, , drop = FALSE]) / sum((1 - S) * w00)

  # optimal borrowing weight
  num <- sum(S * (1 - A) / (1 - pi_A)^2 / (sum(S * (1 - A) / (1 - pi_A)))^2)
  denom <- sum((1 - S) * w00^2 / (sum((1 - S) * w00))^2)
  w_opt <- num / (num + denom)
  borrow_weight <- if (is.null(weight)) w_opt else weight

  # combine rct control and external control
  mu0 <- (1 - borrow_weight) * mu10 + borrow_weight * mu00
  tau <- mu1 - mu0

  list(tau = tau, borrow_weight = borrow_weight,
       ps_model = ps_model, pi_SX = pi_SX, pi_A = pi_A,
       pi_S = pi_S, rx = rx, w00 = w00,
       Yr = Yr, mu1 = mu1, mu10 = mu10, mu00 = mu00)
}

#' sandwich variance for EC-AIPW (Theorem 4, Eq 15-16).
#' extends the IPW sandwich with outcome model parameter blocks.
#' @param df internal data frame.
#' @param core output from .ec_aipw_core.
#' @param n_time number of time points.
#' @param outcome_formula character vector of outcome model formulas.
#' @return numeric vector of standard errors (length n_time).
#' @noRd
.ec_aipw_sandwich <- function(df, core, n_time, outcome_formula) {
  S <- df$S
  A <- df$A
  N <- nrow(df)

  X_ps <- model.matrix(core$ps_model)
  n_ps <- ncol(X_ps)

  # refit outcome models on full data (needed for sandwich, not for tau)
  Y0_models_full <- lapply(outcome_formula, \(f) {
    lm(as.formula(f), data = df)
  })

  # bread: ps block----
  A33 <- diag(
    rep(-mean((1 - S) * core$w00 / (1 - core$pi_S)), n_time),
    nrow = n_time
  )
  A34 <- t((1 - S) * core$pi_SX / (core$pi_S * (1 - core$pi_SX)) *
    sweep(core$Yr, 2, core$mu00)) %*% X_ps / N
  A44 <- t(X_ps) %*% diag(-core$pi_SX * (1 - core$pi_SX)) %*% X_ps / N

  A0 <- as.matrix(Matrix::bdiag(
    diag(-1, n_time), diag(-1, n_time), A33, A44
  ))
  A0[(2 * n_time + 1):(3 * n_time),
     (3 * n_time + 1):(3 * n_time + n_ps)] <- A34

  # bread: outcome model blocks----
  Y0_model_mats <- lapply(Y0_models_full, model.matrix)
  n_outcome <- sum(vapply(Y0_model_mats, ncol, integer(1)))

  Phi1_gamma <- as.matrix(Matrix::bdiag(lapply(seq_len(n_time), \(t) {
    as.vector(-S * A / (core$pi_S * core$pi_A)) %*% Y0_model_mats[[t]] / N
  })))
  Phi2_gamma <- as.matrix(Matrix::bdiag(lapply(seq_len(n_time), \(t) {
    as.vector(-S * (1 - A) / (core$pi_S * (1 - core$pi_A))) %*%
      Y0_model_mats[[t]] / N
  })))
  Phi3_gamma <- as.matrix(Matrix::bdiag(lapply(seq_len(n_time), \(t) {
    as.vector(-(1 - S) * core$rx / (1 - core$pi_S)) %*%
      Y0_model_mats[[t]] / N
  })))
  Y0_gamma <- as.matrix(Matrix::bdiag(lapply(seq_len(n_time), \(t) {
    -t(Y0_model_mats[[t]]) %*%
      diag((1 - A) / (1 - mean(A))) %*% Y0_model_mats[[t]] / N
  })))

  # assemble full bread matrix----
  A_left <- rbind(A0, matrix(0, nrow = n_outcome, ncol = 3 * n_time + n_ps))
  A_right <- rbind(
    Phi1_gamma, Phi2_gamma, Phi3_gamma,
    matrix(0, nrow = n_ps, ncol = n_outcome),
    Y0_gamma
  )
  A_mat <- cbind(A_left, A_right)

  # meat: influence functions----
  phi1 <- S * A * sweep(core$Yr, 2, core$mu1) / core$pi_A / core$pi_S
  phi2 <- S * (1 - A) * sweep(core$Yr, 2, core$mu10) /
    (1 - core$pi_A) / core$pi_S
  phi3 <- (1 - S) * sweep(core$Yr, 2, core$mu00) *
    core$w00 / (1 - core$pi_S)
  phi_ps <- (S - core$pi_SX) * X_ps
  phi_Y0 <- do.call(cbind, lapply(seq_len(n_time), \(t) {
    ((1 - A) / (1 - mean(A))) * (core$Yr[, t] * Y0_model_mats[[t]])
  }))

  B <- crossprod(cbind(phi1, phi2, phi3, phi_ps, phi_Y0)) / N

  # sandwich: A^{-1} B A^{-T}, then extract tau variance----
  A_inv <- solve(A_mat)
  sigma <- A_inv %*% B %*% t(A_inv)

  coef_mat <- cbind(
    diag(n_time),
    -(1 - core$borrow_weight) * diag(n_time),
    -core$borrow_weight * diag(n_time),
    matrix(0, nrow = n_time, ncol = n_ps + n_outcome)
  )
  sqrt(diag(coef_mat %*% sigma %*% t(coef_mat) / N))
}

#' bootstrap statistic for EC-AIPW. called by boot::boot on each resample.
#' refits both PS and outcome models on the resampled data.
#' @param data internal data frame.
#' @param indices bootstrap sample indices.
#' @param outcomes outcome column names.
#' @param covariates covariate column names.
#' @param ps_formula propensity score formula.
#' @param outcome_formula outcome model formulas.
#' @param borrow_wt pre-computed borrowing weight.
#' @return numeric vector of tau estimates.
#' @noRd
.ec_aipw_statistic <- function(data, indices, outcomes, covariates,
                               ps_formula, outcome_formula, borrow_wt) {
  d <- data[indices, , drop = FALSE]
  core <- .ec_aipw_core(d, outcomes, ps_formula, outcome_formula, borrow_wt)
  core$tau
}
