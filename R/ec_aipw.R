#' @include ec_ipw.R
NULL

# s4 class definition----
.ec_aipw_method <- setClass(
  "ec_aipw_method",
  contains = "method_primary_obj",
  slots = c(
    ps_formula = "character",
    outcome_formula = "character",
    weight = "numericOrNULL",
    bootstrap = "numericOrNULL",
    bootstrap_ci_type = "character"
  ),
  prototype = list(
    method_name = "EC-AIPW",
    ps_formula = "",
    outcome_formula = "",
    weight = NULL,
    bootstrap = NULL,
    bootstrap_ci_type = "perc"
  )
)

# constructor----

#' EC-AIPW method constructor
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
#' ec_aipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   outcome_formula = c(
#'     "y1 ~ x1 + x2 + x3 + x4 + x5",
#'     "y2 ~ x1 + x2 + x3 + x4 + x5"
#'   )
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

  if (is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  checkmate::assert_choice(
    bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
  )

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
      bootstrap_CI_type = bootstrap_ci_type
    )
  )
}

# estimate() method----

#' @rdname estimate
setMethod("estimate", "ec_aipw_method", function(method, data, outcomes,
                                                 treatment, trial_status,
                                                 covariates, alpha = 0.05,
                                                 quiet = TRUE) {
  Y <- as.matrix(data[, outcomes, drop = FALSE])
  S <- data[[trial_status]]
  A <- data[[treatment]]
  n_time <- ncol(Y)
  N <- nrow(data)
  n <- sum(S)
  m <- N - n
  pi_S <- n / N

  ps_formula <- sub("^[^~]*~", paste0(trial_status, " ~"), method@ps_formula)
  df <- data.frame(Y, S = S, A = A, data[, covariates, drop = FALSE])

  if (!quiet) cat("Running EC-AIPW estimator...\n")

  result <- .ec_aipw_estimate(
    df, Y, S, A, n, m, N, pi_S, n_time,
    ps_formula, method@outcome_formula, method@weight
  )

  tau <- result$tau
  sd_tau <- result$sd_tau
  borrow_weight <- result$borrow_weight
  cutoff <- qnorm(1 - alpha / 2)

  if (!is.null(method@bootstrap)) {
    if (!quiet) cat("Running bootstrap inference...\n")
    group_id <- as.integer(interaction(df$S, df$A, drop = TRUE))

    boot_ci_type_long <- switch(method@bootstrap_ci_type,
      norm = "normal",
      bca = "bca",
      stud = "student",
      perc = "percent",
      basic = "basic"
    )

    boot_out <- boot::boot(
      data = df,
      statistic = .ec_aipw_statistic,
      outcomes = outcomes,
      covariates = covariates,
      ps_formula = ps_formula,
      outcome_formula = method@outcome_formula,
      borrow_wt = borrow_weight,
      R = method@bootstrap,
      strata = group_id
    )

    lower_ci <- vapply(seq_len(n_time), \(i) {
      ci <- boot::boot.ci(boot_out,
        conf = 1 - alpha,
        type = method@bootstrap_ci_type, index = i
      )
      ci[[boot_ci_type_long]][4]
    }, numeric(1))

    upper_ci <- vapply(seq_len(n_time), \(i) {
      ci <- boot::boot.ci(boot_out,
        conf = 1 - alpha,
        type = method@bootstrap_ci_type, index = i
      )
      ci[[boot_ci_type_long]][5]
    }, numeric(1))

    sd_tau <- sqrt(diag(var(boot_out$t)))

    results <- data.frame(
      point_estimates = tau,
      standard_deviation = sd_tau,
      lower_CI_boot = lower_ci,
      upper_CI_boot = upper_ci,
      row.names = paste0("tau", seq_len(n_time))
    )
  } else {
    results <- data.frame(
      point_estimates = tau,
      standard_deviation = sd_tau,
      lower_CI_normal = tau - sd_tau * cutoff,
      upper_CI_normal = tau + sd_tau * cutoff,
      row.names = paste0("tau", seq_len(n_time))
    )
  }

  list(results = results, borrow_weight = borrow_weight)
})

# internal helpers----

#' @noRd
.ec_aipw_estimate <- function(df, Y, S, A, n, m, N, pi_S, n_time,
                              ps_formula, outcome_formula, weight) {
  ps_model <- glm(as.formula(ps_formula), data = df, family = "binomial")
  pi_SX <- predict(ps_model, newdata = df, type = "response")
  pi_A <- sum(A[S == 1]) / n
  rx <- (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S)

  # outcome regression models fitted on controls only
  Y0_models <- lapply(outcome_formula, \(f) {
    lm(as.formula(f), data = df[A == 0, , drop = FALSE])
  })

  # predicted Y0 for all subjects
  Y0 <- vapply(seq_len(n_time), \(t) {
    predict(Y0_models[[t]], newdata = df)
  }, numeric(N))

  # residuals
  Yr <- Y - Y0

  w11 <- pi_A
  w10 <- 1 - pi_A
  w00 <- rx

  potential <- (S * A / w11 + S * (1 - A) / w10 + (1 - S) * w00) * Yr
  mu1 <- colSums(potential[S == 1 & A == 1, , drop = FALSE]) / n
  mu10 <- colSums(potential[S == 1 & A == 0, , drop = FALSE]) / n
  mu00 <- colSums(potential[S == 0, , drop = FALSE]) / sum((1 - S) * w00)

  # optimal weight
  num <- sum(S * (1 - A) / w10^2 / (sum(S * (1 - A) / w10))^2)
  denom <- sum((1 - S) * w00^2 / (sum((1 - S) * w00))^2)
  w_opt <- num / (num + denom)
  borrow_weight <- if (is.null(weight)) w_opt else weight

  mu0 <- (1 - borrow_weight) * mu10 + borrow_weight * mu00
  tau <- mu1 - mu0

  # sandwich variance
  X_ps <- model.matrix(ps_model)
  n_ps <- ncol(X_ps)

  # outcome model matrices (fit on full data for sandwich)
  Y0_models_full <- lapply(outcome_formula, \(f) lm(as.formula(f), data = df))
  Y0_model_dims <- vapply(Y0_models_full, \(m) ncol(model.matrix(m)), integer(1))
  n_outcome <- sum(Y0_model_dims)

  A33 <- diag(rep(-mean((1 - S) * w00 / (1 - pi_S)), n_time), nrow = n_time)
  A34 <- t((1 - S) * pi_SX / (pi_S * (1 - pi_SX)) *
    sweep(Yr, 2, mu00)) %*% X_ps / N
  A44 <- t(X_ps) %*% diag(-pi_SX * (1 - pi_SX)) %*% X_ps / N

  A0 <- as.matrix(Matrix::bdiag(
    diag(-1, n_time), diag(-1, n_time), A33, A44
  ))
  A0[
    (n_time + n_time + 1):(n_time + n_time + n_time),
    (n_time + n_time + n_time + 1):(n_time + n_time + n_time + n_ps)
  ] <- A34

  # outcome model blocks
  Phi1_gamma_list <- lapply(seq_len(n_time), \(t) {
    Xm <- model.matrix(Y0_models_full[[t]])
    as.vector(-S * A / (pi_S * pi_A)) %*% Xm / N
  })
  Phi1_gamma <- as.matrix(Matrix::bdiag(Phi1_gamma_list))

  Phi2_gamma_list <- lapply(seq_len(n_time), \(t) {
    Xm <- model.matrix(Y0_models_full[[t]])
    as.vector(-S * (1 - A) / (pi_S * (1 - pi_A))) %*% Xm / N
  })
  Phi2_gamma <- as.matrix(Matrix::bdiag(Phi2_gamma_list))

  Phi3_gamma_list <- lapply(seq_len(n_time), \(t) {
    Xm <- model.matrix(Y0_models_full[[t]])
    as.vector(-(1 - S) * rx / (1 - pi_S)) %*% Xm / N
  })
  Phi3_gamma <- as.matrix(Matrix::bdiag(Phi3_gamma_list))

  Y0_gamma_list <- lapply(seq_len(n_time), \(t) {
    Xm <- model.matrix(Y0_models_full[[t]])
    -t(Xm) %*% diag((1 - A) / (1 - mean(A))) %*% Xm / N
  })
  Y0_gamma <- as.matrix(Matrix::bdiag(Y0_gamma_list))

  A45 <- matrix(0, nrow = n_ps, ncol = n_outcome)
  A51 <- matrix(0, nrow = n_outcome, ncol = n_time + n_time + n_time + n_ps)

  A_left <- rbind(A0, A51)
  A_right <- rbind(Phi1_gamma, Phi2_gamma, Phi3_gamma, A45, Y0_gamma)
  A_mat <- cbind(A_left, A_right)

  # meat
  phi1 <- S * A * sweep(Yr, 2, mu1) / pi_A / pi_S
  phi2 <- S * (1 - A) * sweep(Yr, 2, mu10) / (1 - pi_A) / pi_S
  phi3 <- (1 - S) * sweep(Yr, 2, mu00) * w00 / (1 - pi_S)
  phi_ps <- (S - pi_SX) * X_ps
  phi_Y0 <- do.call(cbind, lapply(seq_len(n_time), \(t) {
    Xm <- model.matrix(Y0_models_full[[t]])
    ((1 - A) / (1 - mean(A))) * (Yr[, t] * Xm)
  }))

  Phi <- cbind(phi1, phi2, phi3, phi_ps, phi_Y0)
  B <- crossprod(Phi) / N

  A_inv <- solve(A_mat)
  sigma <- A_inv %*% B %*% t(A_inv)

  coef_mat <- cbind(
    diag(n_time),
    -(1 - borrow_weight) * diag(n_time),
    -borrow_weight * diag(n_time),
    matrix(0, nrow = n_time, ncol = n_ps + n_outcome)
  )
  sd_tau <- sqrt(diag(coef_mat %*% sigma %*% t(coef_mat) / N))

  list(tau = tau, sd_tau = sd_tau, borrow_weight = borrow_weight)
}

#' @noRd
.ec_aipw_statistic <- function(data, indices, outcomes, covariates,
                               ps_formula, outcome_formula, borrow_wt) {
  d <- data[indices, , drop = FALSE]
  Y <- as.matrix(d[, outcomes, drop = FALSE])
  S <- d$S
  A <- d$A
  n <- sum(S)
  N <- nrow(d)
  n_time <- ncol(Y)
  pi_S <- n / N

  ps_model <- glm(as.formula(ps_formula), data = d, family = "binomial")
  pi_SX <- predict(ps_model, newdata = d, type = "response")
  pi_A <- sum(A[S == 1]) / n
  rx <- (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S)

  Y0_models <- lapply(outcome_formula, \(f) {
    lm(as.formula(f), data = d[A == 0, , drop = FALSE])
  })
  Y0 <- vapply(seq_len(n_time), \(t) {
    predict(Y0_models[[t]], newdata = d)
  }, numeric(N))
  Yr <- Y - Y0

  potential <- (S * A / pi_A + S * (1 - A) / (1 - pi_A) + (1 - S) * rx) * Yr
  mu1 <- colSums(potential[S == 1 & A == 1, , drop = FALSE]) / n
  mu10 <- colSums(potential[S == 1 & A == 0, , drop = FALSE]) / n
  mu00 <- colSums(potential[S == 0, , drop = FALSE]) / sum((1 - S) * rx)

  mu0 <- (1 - borrow_wt) * mu10 + borrow_wt * mu00
  mu1 - mu0
}
