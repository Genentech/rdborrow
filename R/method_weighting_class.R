#' Method weighting class
#'
#' @slot optimal_weight_flag logical.
#' @slot wt numeric.
#' @slot model_form_mu0_ext Formula string for external control outcome model.
#' @slot model_form_mu0_rct Formula string for RCT control outcome model.
#' @slot model_form_mu1_rct Formula string for RCT treatment outcome model.
#' @slot model_form_piS Formula string for trial participation model.
#' @slot model_form_piA Formula string for treatment assignment model.
#'
#' @include method_class.R
#' @include bootstrap_class.R
.method_weighting_obj <- setClass(
  "method_weighting_obj",
  contains = "method_primary_obj",
  slots = c(
    optimal_weight_flag = "logical",
    wt = "numeric",
    model_form_piS = "character",
    model_form_piA = "character",
    model_form_mu0_ext = "character",
    model_form_mu0_rct = "character",
    model_form_mu1_rct = "character"
  ),
  prototype = list(
    method_name = "IPW",
    optimal_weight_flag = FALSE,
    wt = 0,
    bootstrap_flag = FALSE,
    bootstrap_obj = .bootstrap_obj(),
    model_form_piA = "",
    model_form_piS = "",
    model_form_mu0_ext = "",
    model_form_mu0_rct = "",
    model_form_mu1_rct = ""
  )
)

#' Construct a method_weighting object
#'
#' @param method_name character. Name of the method.
#' @param optimal_weight_flag logical. Whether to use optimal weighting.
#' @param wt numeric. The value of wt for the weighting scheme.
#' @param bootstrap_flag logical. Whether to use bootstrap for inference.
#' @param bootstrap_obj bootstrap_obj. An object of class `bootstrap_obj`
#'   containing bootstrap settings.
#' @param model_form_piS character. Model formula for the selection model (S).
#' @param model_form_mu0_ext character. Model formula for the outcome model in
#'   the external data (mu0_ext).
#' @param model_form_piA character. Model formula for the treatment model (A).
#' @param model_form_mu0_rct character. Model formula for the outcome model in
#'   the RCT data under control (mu0_rct).
#' @param model_form_mu1_rct character. Model formula for the outcome model in
#'   the RCT data under treatment (mu1_rct).
#'
#' @return An object of class `method_weighting_obj`.
#' @export
#'
#' @examples
#' setup_method_weighting(
#'   method_name = "IPW",
#'   model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
#' )
setup_method_weighting <- function(method_name = "IPW",
                                   optimal_weight_flag = FALSE,
                                   wt = 0,
                                   bootstrap_flag = FALSE,
                                   bootstrap_obj = .bootstrap_obj(),
                                   model_form_piS = "",
                                   model_form_mu0_ext = "",
                                   model_form_piA = "",
                                   model_form_mu0_rct = "",
                                   model_form_mu1_rct = "") {
  .Deprecated("ec_ipw")
  checkmate::assert_string(method_name)
  checkmate::assert_flag(bootstrap_flag)
  checkmate::assert_class(bootstrap_obj, "bootstrap_obj")
  checkmate::assert_flag(optimal_weight_flag)
  checkmate::assert_number(wt)
  checkmate::assert_string(model_form_piS)
  checkmate::assert_string(model_form_piA)
  checkmate::assert_character(model_form_mu0_ext)
  checkmate::assert_character(model_form_mu0_rct)
  checkmate::assert_character(model_form_mu1_rct)

  method_weighting_obj <- .method_weighting_obj(
    method_name = method_name,
    optimal_weight_flag = optimal_weight_flag,
    wt = wt,
    bootstrap_flag = bootstrap_flag,
    bootstrap_obj = bootstrap_obj,
    model_form_piS = model_form_piS,
    model_form_mu0_ext = model_form_mu0_ext,
    model_form_piA = model_form_piA,
    model_form_mu0_rct = model_form_mu0_rct,
    model_form_mu1_rct = model_form_mu1_rct
  )
}

#' Build the internal data frame for primary weighting estimators.
#' Combines outcome matrix Y, trial status S, treatment A, and covariates
#' into a single data frame used by all ec_ipw/ec_aipw internals.
#' @param data user-supplied data frame.
#' @param outcomes character vector of outcome column names.
#' @param treatment name of the treatment column.
#' @param trial_status name of the trial participation column.
#' @param covariates character vector of covariate column names.
#' @return data frame with columns: outcome cols, S, A, covariate cols.
#' @noRd
.build_analysis_df <- function(data, outcomes, treatment, trial_status,
                               covariates) {
  Y <- as.matrix(data[, outcomes, drop = FALSE])
  data.frame(Y, S = data[[trial_status]], A = data[[treatment]],
             data[, covariates, drop = FALSE])
}

#' Format estimation results for primary weighting methods.
#' If bootstrap is requested, runs .run_bootstrap and returns boot CIs.
#' Otherwise returns sandwich SE with normal CIs.
#' @param tau numeric vector of point estimates.
#' @param sd_tau numeric vector of sandwich standard errors.
#' @param borrow_weight numeric borrowing weight used.
#' @param n_time number of time points (length of tau).
#' @param alpha significance level.
#' @param method S4 method object (checked for bootstrap slot).
#' @param df internal data frame (passed to bootstrap statistic).
#' @param quiet logical suppress output.
#' @param statistic bootstrap statistic function.
#' @param ... additional args passed to statistic via .run_bootstrap.
#' @return list with results (data.frame) and borrow_weight.
#' @noRd
.format_primary_results <- function(tau, sd_tau, borrow_weight, n_time,
                                    alpha, method, df, quiet, statistic,
                                    ...) {
  cutoff <- qnorm(1 - alpha / 2)

  if (!is.null(method@bootstrap)) {
    if (!quiet) cat("Running bootstrap inference...\n")
    boot_res <- .run_bootstrap(
      df = df, statistic = statistic,
      n_estimates = n_time, bootstrap = method@bootstrap,
      bootstrap_ci_type = method@bootstrap_ci_type, alpha = alpha,
      borrow_wt = borrow_weight, ...
    )
    results <- data.frame(
      point_estimates = tau,
      standard_deviation = boot_res$sd_boot,
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
}
