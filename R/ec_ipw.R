#' @include method_class.R
NULL

# S4 class definition
.ec_ipw_method <- setClass(
  "ec_ipw_method",
  contains = "method_weighting_obj",
  slots = c(
    ps_formula = "character",
    weight = "numericOrNULL",
    bootstrap = "numericOrNULL",
    bootstrap_ci_type = "characterOrNULL"
  ),
  prototype = list(
    method_name = "EC-IPW",
    ps_formula = "",
    weight = NULL,
    bootstrap = NULL,
    bootstrap_ci_type = NULL
  )
)

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
#' @param bootstrap_ci_type Bootstrap CI type, or \code{NULL} (default)
#'   which resolves to \code{"perc"} when \code{bootstrap} is set. One of
#'   \code{"perc"}, \code{"bca"}, \code{"norm"}, \code{"basic"}, or
#'   \code{"stud"}.
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
#' # optimal weight, sandwich SE
#' ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
#'
#' # no borrowing
#' ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5", weight = 0)
#'
#' # optimal weight with bootstrap
#' ec_ipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   bootstrap = 500
#' )
#'
#' # fixed weight with bootstrap
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

  # bootstrap type
  if (!is.null(bootstrap) && is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  if (!is.null(bootstrap_ci_type)) {
    checkmate::assert_choice(
      bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
    )
  }

  .ec_ipw_method(
    ps_formula = ps_formula,
    weight = weight,
    bootstrap = bootstrap,
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "EC-IPW",
    bootstrap_flag = !is.null(bootstrap),
    bootstrap_obj = .bootstrap_obj(
      replicates = bootstrap %||% 500L,
      bootstrap_CI_type = bootstrap_ci_type %||% "perc"
    )
  )
}

#' @rdname estimate
setMethod("estimate", "ec_ipw_method", function(method, data, outcomes,
                                                treatment, trial_status,
                                                covariates, alpha = 0.05,
                                                quiet = TRUE) {
  # unwrap formula
  ps_formula <- sub("^[^~]*~", paste0(trial_status, " ~"), method@ps_formula)
  df <- .build_analysis_df(data, outcomes, treatment, trial_status, covariates)
  n_time <- length(outcomes)

  if (!quiet) cat("Running EC-IPW estimator...\n")

  weight <- method@weight
  use_borrowing <- is.null(weight) || weight > 0

  # weight=0 uses rct-only path (no PS model needed)
  if (!use_borrowing) {
    Y <- as.matrix(df[, outcomes, drop = FALSE])
    result <- .ec_ipw_no_borrow(df, Y, df$S, df$A)
    borrow_weight <- 0
  } else {
    # weight>0 or NULL: fit PS model, compute borrowing weight, sandwich SE
    core <- .ec_ipw_borrow_core(
      df, as.matrix(df[, outcomes, drop = FALSE]),
      df$S, df$A, ps_formula, weight
    )
    result <- .ec_ipw_sandwich(df, core, n_time)
    borrow_weight <- core$borrow_weight
  }

  # format output and optionally run bootstrap
  .format_primary_results(
    tau = result$tau, sd_tau = result$sd_tau,
    borrow_weight = borrow_weight,
    n_time = n_time, alpha = alpha,
    method = method, df = df, quiet = quiet,
    statistic = .ec_ipw_statistic,
    outcomes = outcomes, covariates = covariates,
    ps_formula = ps_formula
  )
})

#' compute Hajek ATE using only RCT subjects (w=0, no PS model).
#' @param df internal data frame with S, A, outcome columns.
#' @param Y outcome matrix (N x T).
#' @param S trial participation vector.
#' @param A treatment vector.
#' @return list with tau and intermediates for sandwich.
#' @noRd
.ec_ipw_no_borrow_core <- function(df, Y, S, A) {
  # see Zhou 2024a: Def 1 (Eq 6) with w=0, reduces to Hajek estimator
  n <- sum(S)
  rct <- df[df$S == 1, , drop = FALSE]
  Y_rct <- Y[S == 1, , drop = FALSE]
  pi_A <- sum(rct$A) / n

  # normalized IPTW (Hajek estimator) -- Def 1 with w=0
  potential <- (rct$A / pi_A + (1 - rct$A) / (1 - pi_A)) * Y_rct
  mu1 <- colSums(potential[rct$A == 1, , drop = FALSE]) / n
  mu0 <- colSums(potential[rct$A == 0, , drop = FALSE]) / n

  list(
    tau = mu1 - mu0, pi_A = pi_A,
    mu1 = mu1, mu0 = mu0,
    Y_rct = Y_rct, rct = rct
  )
}

#' sandwich SE for the rct-only case (Theorem 3 with w=0).
#' @param df internal data frame.
#' @param Y outcome matrix.
#' @param S trial participation vector.
#' @param A treatment vector.
#' @return list with tau and sd_tau.
#' @noRd
.ec_ipw_no_borrow <- function(df, Y, S, A) {
  # see Zhou 2024a: Theorem 3 with w=0
  core <- .ec_ipw_no_borrow_core(df, Y, S, A)
  n <- sum(S)
  n_time <- ncol(Y)

  # influence functions for treated and control
  phi1 <- core$rct$A * sweep(core$Y_rct, 2, core$mu1) / core$pi_A
  phi0 <- (1 - core$rct$A) * sweep(core$Y_rct, 2, core$mu0) / (1 - core$pi_A)
  B <- crossprod(cbind(phi1, phi0)) / n

  # tau = mu1 - mu0, so coef_mat = [I, -I]
  coef_mat <- cbind(diag(n_time), -diag(n_time))
  sd_tau <- sqrt(diag(coef_mat %*% B %*% t(coef_mat) / n))

  list(tau = core$tau, sd_tau = sd_tau)
}

#' EC-IPW point estimate with borrowing (Def 1, Eq 6).
#' fits PS model, computes density ratio weights W00 (Eq 4),
#' mu11/mu10/mu00, and optimal weight (Eq 11).
#' shared by estimate() and bootstrap statistic.
#' @param df internal data frame.
#' @param Y outcome matrix (N x T).
#' @param S trial participation vector.
#' @param A treatment vector.
#' @param ps_formula propensity score formula string.
#' @param weight fixed weight or NULL for optimal.
#' @return list with tau, borrow_weight, and model intermediates.
#' @noRd
.ec_ipw_borrow_core <- function(df, Y, S, A, ps_formula, weight) {
  # see Zhou 2024a: Def 1 (Eq 6) for point estimate, Eq 11 for optimal weight

  n <- sum(S)
  N <- length(S)
  pi_S <- n / N

  # propensity score model for trial participation
  ps_model <- glm(as.formula(ps_formula), data = df, family = "binomial")
  pi_SX <- predict(ps_model, newdata = df, type = "response")
  pi_A <- sum(A[S == 1]) / n

  # weights (Theorem 1)
  w11 <- 1 / pi_A
  w10 <- 1 / (1 - pi_A)
  w00 <- (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S) # density ratio

  # mu-hat components
  Y_trt <- Y[S == 1 & A == 1, , drop = FALSE]
  Y_ctrl <- Y[S == 1 & A == 0, , drop = FALSE]
  Y_ext <- Y[S == 0, , drop = FALSE]
  w00_ext <- w00[S == 0]

  mu1 <- colMeans(Y_trt)
  mu10 <- colMeans(Y_ctrl)
  mu00 <- colSums(w00_ext * Y_ext) / sum(w00_ext)

  # optimal weight (Eq 11)
  if (is.null(weight)) {
    num <- sum(rep(w10^2, nrow(Y_ctrl))) / sum(rep(w10, nrow(Y_ctrl)))^2
    denom <- sum(w00_ext^2) / sum(w00_ext)^2
    borrow_weight <- num / (num + denom)
  } else {
    borrow_weight <- weight
  }

  # combine of trial and external controls
  mu0 <- (1 - borrow_weight) * mu10 + borrow_weight * mu00
  tau <- mu1 - mu0

  list(
    tau = tau, borrow_weight = borrow_weight,
    ps_model = ps_model, pi_SX = pi_SX, pi_A = pi_A,
    w00 = w00, w10 = w10,
    mu1 = mu1, mu10 = mu10, mu00 = mu00
  )
}

#' sandwich variance for EC-IPW with borrowing
#' constructs bread matrix A and meat matrix B from core intermediates.
#' @param df internal data frame.
#' @param core output from .ec_ipw_borrow_core.
#' @param n_time number of time points.
#' @return list with tau and sd_tau.
#' @noRd
.ec_ipw_sandwich <- function(df, core, n_time) {
  # see Zhou 2024a: Theorem 3 (Eq 12 for A/B matrices, Eq 13 for variance)

  Y <- as.matrix(df[, seq_len(n_time), drop = FALSE])
  S <- df$S
  A <- df$A
  N <- nrow(df)
  pi_S <- sum(S) / N

  X_model <- model.matrix(core$ps_model)
  n_ps <- ncol(X_model)

  # bread: A matrix blocks (Eq 12)
  # A11 = -I_T, A22 = -I_T (for mu1, mu10)
  # A33 = external control block
  # A34 = cross-term linking mu00 to PS params
  # A44 = PS model Hessian
  A33 <- diag(rep(-mean((1 - S) * core$w00 / (1 - pi_S)), n_time), nrow = n_time)
  A34 <- t((1 - S) * core$pi_SX / (pi_S * (1 - core$pi_SX)) *
    sweep(Y, 2, core$mu00)) %*% X_model / N
  A44 <- t(X_model) %*% diag(-core$pi_SX * (1 - core$pi_SX)) %*% X_model / N

  block_dim <- 3 * n_time + n_ps
  A_mat <- matrix(0, nrow = block_dim, ncol = block_dim)
  A_mat[1:n_time, 1:n_time] <- diag(-1, n_time)
  A_mat[(n_time + 1):(2 * n_time), (n_time + 1):(2 * n_time)] <- diag(-1, n_time)
  A_mat[(2 * n_time + 1):(3 * n_time), (2 * n_time + 1):(3 * n_time)] <- A33
  A_mat[(3 * n_time + 1):block_dim, (3 * n_time + 1):block_dim] <- A44
  A_mat[(2 * n_time + 1):(3 * n_time), (3 * n_time + 1):block_dim] <- A34

  # meat: influence functions (Psi_1 through Psi_4 in Theorem 3)
  phi1 <- S * A * sweep(Y, 2, core$mu1) / core$pi_A / pi_S
  phi2 <- S * (1 - A) * sweep(Y, 2, core$mu10) / (1 - core$pi_A) / pi_S
  phi3 <- (1 - S) * sweep(Y, 2, core$mu00) * core$w00 / (1 - pi_S)
  phi_ps <- (S - core$pi_SX) * X_model
  B <- crossprod(cbind(phi1, phi2, phi3, phi_ps)) / N

  # sandwich: Sigma = A^{-1} B A^{-T} (Eq 13)
  A_inv <- solve(A_mat)
  sigma <- A_inv %*% B %*% t(A_inv)

  # tau = mu1 - (1-w)*mu10 - w*mu00, extract variance via linear combination
  coef_mat <- cbind(
    diag(n_time),
    -(1 - core$borrow_weight) * diag(n_time),
    -core$borrow_weight * diag(n_time),
    matrix(0, nrow = n_time, ncol = n_ps)
  )
  sd_tau <- sqrt(diag(coef_mat %*% sigma %*% t(coef_mat) / N))

  list(tau = core$tau, sd_tau = sd_tau)
}

#' bootstrap statistic for EC-IPW. called by boot::boot on each resample.
#' @param data internal data frame.
#' @param indices bootstrap sample indices.
#' @param outcomes outcome column names.
#' @param covariates covariate column names.
#' @param ps_formula propensity score formula.
#' @param borrow_wt pre-computed borrowing weight.
#' @return numeric vector of tau estimates.
#' @noRd
.ec_ipw_statistic <- function(data, indices, outcomes, covariates,
                              ps_formula, borrow_wt) {
  d <- data[indices, , drop = FALSE]
  Y <- as.matrix(d[, outcomes, drop = FALSE])
  S <- d$S
  A <- d$A

  if (borrow_wt == 0) {
    core <- .ec_ipw_no_borrow_core(d, Y, S, A)
  } else {
    core <- .ec_ipw_borrow_core(d, Y, S, A, ps_formula, borrow_wt)
  }
  core$tau
}
