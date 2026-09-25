#' @include ec_ipw.R
NULL

# S4 class definition----
.did_ec_ipw_method <- setClass(
  "did_ec_ipw_method",
  contains = "method_DID_obj",
  slots = c(
    ps_formula = "character",
    ps_fit = "ANY",
    trt_formula = "characterOrNULL"
  ),
  prototype = list(
    method_name = "DID-EC-IPW",
    ps_formula = "",
    ps_fit = NULL,
    trt_formula = NULL
  )
)

#' DID-EC-IPW method
#'
#' Creates a method object for difference-in-differences inverse
#' probability weighting (DID-EC-IPW) estimation with external
#' control borrowing for the open-label extension phase
#' (Zhou et al., 2024, Eq. 4).
#'
#' @param ps_formula Formula string for the propensity score model
#'   predicting trial participation. Omit when using \code{ps_fit}.
#' @param ps_fit Alternative to \code{ps_formula}: supply the weights
#'   yourself instead of fitting the internal logistic propensity model.
#'   Either a function of the data returning one non-negative weight per
#'   subject, or a fitted \pkg{WeightIt} or \pkg{MatchIt} object, whose
#'   stored call is re-evaluated on each bootstrap resample. Only the
#'   weights for external controls (\code{S == 0}) affect the estimate,
#'   and they enter through a self-normalized mean, so their overall scale
#'   is irrelevant. For \pkg{WeightIt}, use \code{estimand = "ATT"} with
#'   the trial as the focal group. This governs trial participation only;
#'   treatment assignment is specified with \code{trt_formula}, which
#'   describes a randomization scheme you already know rather than a model
#'   to be estimated.
#' @param trt_formula Formula string for the treatment assignment model,
#'   or \code{NULL} (default) for marginal probability.
#' @param bootstrap Number of bootstrap replicates (required for DID
#'   methods). Defaults to 500.
#' @param bootstrap_ci_type Bootstrap CI type. Defaults to \code{"perc"}.
#'
#' @return An S4 object of class \code{did_ec_ipw_method}.
#'
#' @references
#' Zhou et al. (2024). Estimating treatment effect in randomized trial
#' after control to treatment crossover using external controls.
#' \emph{Journal of Biopharmaceutical Statistics}.
#' \doi{10.1080/10543406.2024.2330209}
#'
#' @export
#'
#' @examples
#' did_ec_ipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
#'   bootstrap = 500
#' )
did_ec_ipw <- function(ps_formula = NULL,
                       ps_fit = NULL,
                       trt_formula = NULL,
                       bootstrap = 500L,
                       bootstrap_ci_type = NULL) {
  .check_ps_args(ps_formula, ps_fit, bootstrap)
  if (is.null(ps_formula)) ps_formula <- ""
  checkmate::assert_string(ps_formula)
  checkmate::assert_string(trt_formula, null.ok = TRUE)
  checkmate::assert_count(bootstrap, positive = TRUE)

  if (is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  checkmate::assert_choice(
    bootstrap_ci_type, c("perc", "bca", "norm", "basic")
  )

  .did_ec_ipw_method(
    ps_formula = ps_formula,
    ps_fit = ps_fit,
    trt_formula = trt_formula,
    bootstrap = bootstrap,
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "DID-EC-IPW"
  )
}

#' @rdname estimate
setMethod("estimate", "did_ec_ipw_method", function(method, data, outcomes,
                                                    treatment, trial_status,
                                                    covariates, alpha = 0.05,
                                                    quiet = TRUE,
                                                    T_cross) {
  df <- .build_analysis_df(data, outcomes, treatment, trial_status, covariates)
  Y <- as.matrix(df[, outcomes, drop = FALSE])
  S <- df$S
  A <- df$A

  ps_formula <- sub("^[^~]*~", paste0(trial_status, " ~"), method@ps_formula)
  trt_formula <- method@trt_formula
  if (!is.null(trt_formula)) {
    trt_formula <- sub("^[^~]*~", paste0(treatment, " ~"), trt_formula)
  }

  if (!quiet) cat("Running DID-EC-IPW estimator...\n")

  result <- .did_ec_ipw_core(
    df, Y, S, A, T_cross, ps_formula, trt_formula,
    method@ps_fit
  )
  tau <- result$tau

  if (!quiet) cat("Running bootstrap inference...\n")

  n_ole <- ncol(Y) - T_cross
  boot_res <- .run_bootstrap(
    df = df, statistic = .did_ec_ipw_boot_statistic,
    n_estimates = n_ole, bootstrap = method@bootstrap,
    bootstrap_ci_type = method@bootstrap_ci_type, alpha = alpha,
    outcomes = outcomes, ps_formula = ps_formula,
    trt_formula = trt_formula, T_cross = T_cross,
    ps_fit = method@ps_fit
  )

  data.frame(
    point_estimates = tau,
    lower_CI_boot = boot_res$lower_ci,
    upper_CI_boot = boot_res$upper_ci,
    row.names = paste0("tau", (T_cross + 1):ncol(Y))
  )
})

#' DID-EC-IPW point estimate (Zhou 2024b, Eq 4 / Appendix B).
#' @param df internal data frame.
#' @param Y outcome matrix (N x T).
#' @param S trial participation vector.
#' @param A treatment vector.
#' @param T_cross crossover time point.
#' @param ps_formula propensity score formula.
#' @param trt_formula treatment assignment formula (NULL for marginal).
#' @return list with tau vector.
#' @noRd
.did_ec_ipw_core <- function(df, Y, S, A, T_cross, ps_formula, trt_formula,
                             ps_fit = NULL) {
  # see Zhou 2024b: Eq 4 (identification), Appendix B (sample estimator)

  n <- sum(S)
  n_time <- ncol(Y)

  # propensity score model and density ratio weights
  w00 <- .ec_weights(df, ps_formula, S, ps_fit)$w00

  # treatment assignment model
  if (is.null(trt_formula)) {
    # marginal randomization probability, recycled so the weights below
    # can be subset by a length-N logical like the modelled branch
    pi_AX <- rep(sum(A[S == 1]) / n, length(S))
  } else {
    trt_model <- glm(as.formula(trt_formula),
      data = df[S == 1, , drop = FALSE], family = "binomial"
    )
    pi_AX <- predict(trt_model, newdata = df, type = "response")
  }

  # treatment weights (same as primary: W11, W10)
  w11 <- 1 / pi_AX
  w10 <- 1 / (1 - pi_AX)

  # normalized weighted outcomes per group
  Y_trt <- Y[S == 1 & A == 1, , drop = FALSE]
  Y_ctrl <- Y[S == 1 & A == 0, , drop = FALSE]
  Y_ext <- Y[S == 0, , drop = FALSE]
  w11_trt <- w11[S == 1 & A == 1]
  w10_ctrl <- w10[S == 1 & A == 0]
  w00_ext <- w00[S == 0]

  # delta_trial: treated OLE outcomes (Eq 4, first term)
  mu_trt_ole <- colSums(w11_trt * Y_trt[, (T_cross + 1):n_time, drop = FALSE]) /
    sum(w11_trt)

  # delta_EC: external control OLE outcomes (Eq 4, second term)
  mu_ext_ole <- colSums(w00_ext * Y_ext[, (T_cross + 1):n_time, drop = FALSE]) /
    sum(w00_ext)

  # bias correction: pre-crossover difference (negative control)
  # Ybar(T1) for RCT controls minus Ybar(T1) for external controls
  bias_ctrl <- sum(w10_ctrl * rowMeans(Y_ctrl[, 1:T_cross, drop = FALSE])) /
    sum(w10_ctrl)
  bias_ext <- sum(w00_ext * rowMeans(Y_ext[, 1:T_cross, drop = FALSE])) /
    sum(w00_ext)
  bias <- bias_ctrl - bias_ext

  tau <- mu_trt_ole - mu_ext_ole - bias
  list(tau = tau)
}

#' bootstrap statistic for DID-EC-IPW.
#' @param data internal data frame.
#' @param indices bootstrap sample indices.
#' @param outcomes outcome column names.
#' @param ps_formula propensity score formula.
#' @param trt_formula treatment assignment formula.
#' @param T_cross crossover time point.
#' @return numeric vector of tau estimates.
#' @noRd
.did_ec_ipw_boot_statistic <- function(data, indices, outcomes, ps_formula,
                                       trt_formula, T_cross, ps_fit = NULL) {
  d <- data[indices, , drop = FALSE]
  Y <- as.matrix(d[, outcomes, drop = FALSE])
  .did_ec_ipw_core(
    d, Y, d$S, d$A, T_cross, ps_formula, trt_formula, ps_fit
  )$tau
}
