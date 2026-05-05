#' EC-IPW estimator for external control borrowing
#'
#' Estimates the average treatment effect (ATE) in a randomized trial
#' by optionally borrowing from external controls using the External
#' Controls Enhanced Inverse Probability Weighting (EC-IPW) estimator
#' from Zhou et al. (2024).
#'
#' The estimator combines RCT treated, RCT control, and reweighted
#' external control outcomes:
#' \deqn{\hat{\tau} = \hat{\mu}_{11} - [(1-w)\hat{\mu}_{10} +
#' w\hat{\mu}_{00}]}
#' where \eqn{w} is the borrowing weight. When \code{weight = 0},
#' only trial data is used (Hajek estimator). When
#' \code{weight = "optimal"}, the data-driven weight from Equation 11
#' of the paper is used.
#'
#' @param data A data frame containing all subject-level data
#'   (both RCT and external control subjects).
#' @param outcomes Character vector of outcome column names (one per
#'   time point).
#' @param treatment Name of the treatment column (binary: 1 =
#'   treated, 0 = control).
#' @param trial_status Name of the trial status column (1 = RCT,
#'   0 = external control).
#' @param covariates Character vector of covariate column names.
#' @param ps_formula Formula string for the propensity score model
#'   of trial participation, e.g. `"S ~ x1 + x2 + x3"`.
#' @param weight Borrowing weight. One of:
#'   \describe{
#'     \item{`"optimal"`}{Data-driven weight that minimizes
#'       variance (default).}
#'     \item{A number in `[0, 1]`}{Fixed weight. Use `0` for
#'       within-trial only (no borrowing).}
#'   }
#' @param alpha Significance level for confidence intervals
#'   (default 0.05).
#' @param bootstrap A `bootstrap_obj` created by
#'   [setup_bootstrap()], or `NULL` (default) for parametric
#'   inference.
#'
#' @return A list with:
#'   \describe{
#'     \item{`results`}{A data frame with columns
#'       `point_estimates`, `standard_deviation`, and either
#'       `lower_CI_normal`/`upper_CI_normal` (parametric) or
#'       `lower_CI_boot`/`upper_CI_boot` (bootstrap).}
#'     \item{`borrow_weight`}{The borrowing weight used.}
#'   }
#'
#' @references
#' Zhou X, Zhu J, Drake C, Pang H (2024). "Causal estimators for
#' incorporating external controls in randomized trials with
#' longitudinal outcomes." *Journal of the Royal Statistical Society
#' Series A: Statistics in Society*. doi:
#' \doi{10.1093/jrsssa/qnae075}.
#'
#' @export
#'
#' @examples
#' # within-trial only (no borrowing)
#' ec_ipw(
#'   data = SyntheticData,
#'   outcomes = c("y1", "y2"),
#'   treatment = "A",
#'   trial_status = "S",
#'   covariates = c("x1", "x2", "x3", "x4", "x5"),
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   weight = 0
#' )
#'
#' # optimal data-driven weight
#' ec_ipw(
#'   data = SyntheticData,
#'   outcomes = c("y1", "y2"),
#'   treatment = "A",
#'   trial_status = "S",
#'   covariates = c("x1", "x2", "x3", "x4", "x5"),
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   weight = "optimal"
#' )
#'
#' @include EC_IPW_OPT.R
ec_ipw <- function(data,
                   outcomes,
                   treatment,
                   trial_status,
                   covariates,
                   ps_formula,
                   weight = "optimal",
                   alpha = 0.05,
                   bootstrap = NULL) {
  # validate inputs----
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_character(outcomes, min.len = 1)
  checkmate::assert_string(treatment)
  checkmate::assert_string(trial_status)
  checkmate::assert_character(covariates, min.len = 1)
  checkmate::assert_string(ps_formula)
  checkmate::assert_number(alpha, lower = 0, upper = 1)

  if (is.character(weight)) {
    checkmate::assert_choice(weight, "optimal")
    optimal_weight_flag <- TRUE
    wt <- 0
  } else {
    checkmate::assert_number(weight, lower = 0, upper = 1)
    optimal_weight_flag <- FALSE
    wt <- weight
  }

  use_bootstrap <- !is.null(bootstrap)
  if (use_bootstrap) {
    checkmate::assert_class(bootstrap, "bootstrap_obj")
  }

  # call the estimator----
  suppressWarnings(
    EC_IPW_OPT(
      data = data,
      outcome_col_name = outcomes,
      trial_status_col_name = trial_status,
      treatment_col_name = treatment,
      covariates_col_name = covariates,
      model_form_piS = ps_formula,
      optimal_weight_flag = optimal_weight_flag,
      wt = wt,
      Bootstrap = use_bootstrap,
      R = if (use_bootstrap) bootstrap@replicates else 500L,
      bootstrap_CI_type = if (use_bootstrap) bootstrap@bootstrap_CI_type else "bca",
      alpha = alpha,
      quiet = TRUE
    )
  )
}
