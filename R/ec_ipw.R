#' @include method_class.R
NULL

# class unions----
setClassUnion("numericOrNULL", c("numeric", "NULL"))

# s4 class definition----
.ec_ipw_method <- setClass(
  "ec_ipw_method",
  contains = "method_primary_obj",
  slots = c(
    ps_formula = "character",
    weight = "numericOrNULL",
    bootstrap = "numericOrNULL",
    bootstrap_ci_type = "character"
  ),
  prototype = list(
    method_name = "EC-IPW",
    ps_formula = "",
    weight = NULL,
    bootstrap = NULL,
    bootstrap_ci_type = "perc"
  )
)

# constructor----

#' EC-IPW method constructor
#'
#' Creates a method object for IPW estimation with external control
#' borrowing (Zhou et al., 2024). Pass to \code{\link{setup_analysis_primary}}
#' and \code{\link{run_analysis}}.
#'
#' @param ps_formula Formula string for the propensity score model
#'   predicting trial participation. The left-hand side is replaced
#'   internally (e.g., \code{"S ~ x1 + x2 + x3"}).
#' @param weight Borrowing weight. \code{NULL} (default) for data-adaptive
#'   optimal weight, \code{0} for RCT-only, or a value in (0, 1].
#' @param bootstrap Number of bootstrap replicates, or \code{NULL}
#'   (default) for sandwich variance with normal CIs.
#' @param bootstrap_ci_type Bootstrap CI type. Defaults to \code{"perc"}
#'   when \code{bootstrap} is non-NULL. One of \code{"perc"}, \code{"bca"},
#'   \code{"norm"}, \code{"basic"}, or \code{"stud"}.
#'
#' @return An S4 object of class \code{ec_ipw_method}.
#'
#' @references
#' Zhou et al. (2024). Causal estimators for incorporating external
#' controls in randomized trials with longitudinal outcomes.
#' \emph{JRSS-A}. \doi{10.1093/jrsssa/qnae075}
#'
#' @export
#'
#' @examples
#' # Optimal weight, sandwich SE
#' ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
#'
#' # No borrowing
#' ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5", weight = 0)
#'
#' # Fixed weight with bootstrap
#' ec_ipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   weight = 0.3,
#'   bootstrap = 500
#' )
ec_ipw <- function(ps_formula,
                   weight = NULL,
                   bootstrap = NULL,
                   bootstrap_ci_type = NULL) {
  checkmate::assert_string(ps_formula)
  checkmate::assert_number(weight, lower = 0, upper = 1, null.ok = TRUE)
  checkmate::assert_count(bootstrap, positive = TRUE, null.ok = TRUE)

  if (is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- if (!is.null(bootstrap)) "perc" else "perc"
  }
  checkmate::assert_choice(
    bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
  )

  .ec_ipw_method(
    ps_formula = ps_formula,
    weight = weight,
    bootstrap = bootstrap,
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "EC-IPW",
    bootstrap_flag = !is.null(bootstrap),
    bootstrap_obj = .bootstrap_obj(
      replicates = bootstrap %||% 500L,
      bootstrap_CI_type = bootstrap_ci_type
    )
  )
}

# estimate() generic and method----

#' Run estimation for a method object
#'
#' S4 generic that dispatches to the appropriate estimation logic
#' based on the method class. Each method defines its own arguments.
#'
#' @param method An S4 method object (e.g., from \code{\link{ec_ipw}}).
#' @param ... Method-specific arguments (data, outcomes, etc.).
#'
#' @return A list with estimation results.
#' @export
setGeneric("estimate", function(method, ...) standardGeneric("estimate"))

#' @rdname estimate
setMethod("estimate", "ec_ipw_method", function(method, data, outcomes,
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

  if (!quiet) cat("Running EC-IPW estimator...\n")

  weight <- method@weight
  use_borrowing <- is.null(weight) || weight > 0

  if (!use_borrowing) {
    result <- .ec_ipw_no_borrow(df, Y, S, A, n, n_time)
    borrow_weight <- 0
  } else {
    result <- .ec_ipw_borrow(
      df, Y, S, A, n, m, N, pi_S, n_time,
      ps_formula, weight
    )
    borrow_weight <- result$borrow_weight
  }

  tau <- result$tau
  sd_tau <- result$sd_tau
  cutoff <- qnorm(1 - alpha / 2)

  if (!is.null(method@bootstrap)) {
    if (!quiet) cat("Running bootstrap inference...\n")

    boot_res <- .run_bootstrap(
      df = df, statistic = .ec_ipw_statistic,
      n_estimates = n_time, bootstrap = method@bootstrap,
      bootstrap_ci_type = method@bootstrap_ci_type, alpha = alpha,
      outcomes = outcomes, covariates = covariates,
      ps_formula = ps_formula, borrow_wt = borrow_weight
    )
    sd_tau <- boot_res$sd_boot

    results <- data.frame(
      point_estimates = tau,
      standard_deviation = sd_tau,
      lower_CI_boot = boot_res$lower_ci,
      upper_CI_boot = boot_res$upper_ci,
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

# point estimate for weight=0 (rct-only, no PS model)----
#' @noRd
.ec_ipw_no_borrow_core <- function(df, Y, S, A, n, n_time) {
  rct <- df[df$S == 1, , drop = FALSE]
  Y_rct <- Y[S == 1, , drop = FALSE]
  pi_A <- sum(rct$A) / n

  potential <- (rct$A / pi_A + (1 - rct$A) / (1 - pi_A)) * Y_rct
  mu1 <- colSums(potential[rct$A == 1, , drop = FALSE]) / n
  mu0 <- colSums(potential[rct$A == 0, , drop = FALSE]) / n

  list(tau = mu1 - mu0, pi_A = pi_A, mu1 = mu1, mu0 = mu0,
       Y_rct = Y_rct, rct = rct)
}

# sandwich variance for weight=0 case----
#' @noRd
.ec_ipw_no_borrow <- function(df, Y, S, A, n, n_time) {
  core <- .ec_ipw_no_borrow_core(df, Y, S, A, n, n_time)

  phi1 <- core$rct$A * sweep(core$Y_rct, 2, core$mu1) / core$pi_A
  phi0 <- (1 - core$rct$A) * sweep(core$Y_rct, 2, core$mu0) / (1 - core$pi_A)
  B <- crossprod(cbind(phi1, phi0)) / n

  coef_mat <- cbind(diag(n_time), -diag(n_time))
  sd_tau <- sqrt(diag(coef_mat %*% B %*% t(coef_mat) / n))

  list(tau = core$tau, sd_tau = sd_tau)
}

# point estimate with borrowing (shared by estimate and bootstrap)----
#' @noRd
.ec_ipw_borrow_core <- function(df, Y, S, A, n, N, pi_S, n_time,
                                ps_formula, weight) {
  ps_model <- glm(as.formula(ps_formula), data = df, family = "binomial")
  pi_SX <- predict(ps_model, newdata = df, type = "response")
  pi_A <- sum(A[S == 1]) / n
  rx <- (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S)

  w11 <- pi_A
  w10 <- 1 - pi_A
  w00 <- rx

  potential <- (S * A / w11 + S * (1 - A) / w10 + (1 - S) * w00) * Y
  mu1 <- colSums(potential[S == 1 & A == 1, , drop = FALSE]) / sum(S * A / w11)
  mu10 <- colSums(potential[S == 1 & A == 0, , drop = FALSE]) / sum(S * (1 - A) / w10)
  mu00 <- colSums(potential[S == 0, , drop = FALSE]) / sum((1 - S) * w00)

  # optimal weight (Eq. 11 from Zhou et al. 2024)
  num <- sum(S * (1 - A) / w10^2 / (sum(S * (1 - A) / w10))^2)
  denom <- sum((1 - S) * w00^2 / (sum((1 - S) * w00))^2)
  w_opt <- num / (num + denom)
  borrow_weight <- if (is.null(weight)) w_opt else weight

  mu0 <- (1 - borrow_weight) * mu10 + borrow_weight * mu00
  tau <- mu1 - mu0

  list(tau = tau, borrow_weight = borrow_weight, ps_model = ps_model,
       pi_SX = pi_SX, pi_A = pi_A, w00 = w00, w10 = w10,
       mu1 = mu1, mu10 = mu10, mu00 = mu00)
}

# sandwich variance with borrowing----
#' @noRd
.ec_ipw_borrow <- function(df, Y, S, A, n, m, N, pi_S, n_time,
                           ps_formula, weight) {
  core <- .ec_ipw_borrow_core(df, Y, S, A, n, N, pi_S, n_time,
                              ps_formula, weight)

  X_model <- model.matrix(core$ps_model)
  n_ps <- ncol(X_model)

  A33 <- diag(rep(-mean((1 - S) * core$w00 / (1 - pi_S)), n_time), nrow = n_time)
  A34 <- t((1 - S) * core$pi_SX / (pi_S * (1 - core$pi_SX)) *
    sweep(Y, 2, core$mu00)) %*% X_model / N
  A44 <- t(X_model) %*% diag(-core$pi_SX * (1 - core$pi_SX)) %*% X_model / N

  block_dim <- n_time + n_time + n_time + n_ps
  A_mat <- matrix(0, nrow = block_dim, ncol = block_dim)
  A_mat[1:n_time, 1:n_time] <- diag(-1, n_time)
  idx2 <- (n_time + 1):(2 * n_time)
  A_mat[idx2, idx2] <- diag(-1, n_time)
  idx3 <- (2 * n_time + 1):(3 * n_time)
  A_mat[idx3, idx3] <- A33
  idx4 <- (3 * n_time + 1):block_dim
  A_mat[idx4, idx4] <- A44
  A_mat[idx3, idx4] <- A34

  phi1 <- S * A * sweep(Y, 2, core$mu1) / core$pi_A / pi_S
  phi2 <- S * (1 - A) * sweep(Y, 2, core$mu10) / (1 - core$pi_A) / pi_S
  phi3 <- (1 - S) * sweep(Y, 2, core$mu00) * core$w00 / (1 - pi_S)
  phi_ps <- (S - core$pi_SX) * X_model
  B <- crossprod(cbind(phi1, phi2, phi3, phi_ps)) / N

  A_inv <- solve(A_mat)
  sigma <- A_inv %*% B %*% t(A_inv)

  coef_mat <- cbind(
    diag(n_time),
    -(1 - core$borrow_weight) * diag(n_time),
    -core$borrow_weight * diag(n_time),
    matrix(0, nrow = n_time, ncol = n_ps)
  )
  sd_tau <- sqrt(diag(coef_mat %*% sigma %*% t(coef_mat) / N))

  list(tau = core$tau, sd_tau = sd_tau, borrow_weight = core$borrow_weight)
}

# bootstrap statistic (calls _core, returns tau only)----
#' @noRd
.ec_ipw_statistic <- function(data, indices, outcomes, covariates,
                              ps_formula, borrow_wt) {
  d <- data[indices, , drop = FALSE]
  Y <- as.matrix(d[, outcomes, drop = FALSE])
  S <- d$S
  A <- d$A
  n <- sum(S)
  N <- nrow(d)
  n_time <- ncol(Y)

  if (borrow_wt == 0) {
    return(.ec_ipw_no_borrow_core(d, Y, S, A, n, n_time)$tau)
  }

  pi_S <- n / N
  core <- .ec_ipw_borrow_core(d, Y, S, A, n, N, pi_S, n_time,
                              ps_formula, borrow_wt)
  core$tau
}
