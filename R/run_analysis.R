#' Run an analysis with external control borrowing
#'
#' Estimates treatment effects by combining randomized trial data with
#' external controls. Choose a method, wrap it in an analysis object,
#' and pass it here.
#'
#' Six borrowing methods are available:
#' \describe{
#'   \item{\code{\link{ec_ipw}}}{Inverse probability weighting (primary
#'     analysis).}
#'   \item{\code{\link{ec_aipw}}}{Augmented inverse probability weighting
#'     (primary analysis).}
#'   \item{\code{\link{did_ec_ipw}}}{Difference-in-differences with IPW
#'     (open-label extension).}
#'   \item{\code{\link{did_ec_aipw}}}{Difference-in-differences with AIPW
#'     (open-label extension).}
#'   \item{\code{\link{did_ec_or}}}{Difference-in-differences with outcome
#'     regression (open-label extension).}
#'   \item{\code{\link{scm}}}{Synthetic control method (open-label
#'     extension).}
#' }
#'
#' @param analysis_obj An analysis object created by
#'   \code{\link{setup_analysis_primary}} or \code{\link{setup_analysis_OLE}}.
#' @param quiet Logical. If \code{TRUE}, suppress printed output.
#'
#' @return For primary methods, a list with \code{results} (data frame of
#'   point estimates, standard errors, and confidence intervals) and
#'   \code{borrow_weight}. For OLE methods, a data frame of point estimates
#'   and bootstrap confidence intervals.
#'
#' @seealso \code{\link{run_simulation}} for evaluating operating
#'   characteristics via Monte Carlo simulation.
#'
#' @include legacy_DID_EC_IPW.R
#' @include legacy_DID_EC_AIPW.R
#' @include legacy_DID_EC_OR.R
#' @include legacy_SCM.R
#'
#' @export
#'
#' @examples
#' method <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")
#' analysis <- setup_analysis_primary(
#'   data = SyntheticData,
#'   trial_status_col_name = "S",
#'   treatment_col_name = "A",
#'   outcome_col_name = c("y1", "y2"),
#'   covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
#'   method_weighting_obj = method
#' )
#' run_analysis(analysis)
run_analysis <- function(analysis_obj, quiet = TRUE) {
  # sanity check
  ## TODO:
  # correct initialization of objects
  # correct dimension compatible
  #

  data <- analysis_obj@data
  outcome_col_name <- analysis_obj@outcome_col_name
  trial_status_col_name <- analysis_obj@trial_status_col_name
  treatment_col_name <- analysis_obj@treatment_col_name
  covariates_col_name <- analysis_obj@covariates_col_name
  alpha <- analysis_obj@alpha
  method <- analysis_obj@method_obj
  Bootstrap <- method@bootstrap_obj

  bootstrap_flag <- method@bootstrap_flag
  R <- Bootstrap@replicates
  bootstrap_CI_type <- Bootstrap@bootstrap_CI_type

  method_type <- is(method)[1]
  if (is(analysis_obj)[1] == "analysis_OLE_obj") {
    T_cross <- analysis_obj@T_cross
  }

  if (method_type == "method_DID_obj") {
    ## TODO: implement OLE analysis
    if (!quiet) {
      cat("Estimating long term causal effects using DID methods... \n")
    }

    name <- method@method_name
    model_form_piS <- method@model_form_piS
    model_form_piA <- method@model_form_piA
    model_form_mu0_ext <- method@model_form_mu0_ext
    model_form_mu0_rct <- method@model_form_mu0_rct
    model_form_mu1_rct <- method@model_form_mu1_rct


    if (name == "IPW") {
      res <- DID_EC_IPW(
        data = data,
        outcome_col_name = outcome_col_name,
        trial_status_col_name = trial_status_col_name,
        treatment_col_name = treatment_col_name,
        covariates_col_name = covariates_col_name,
        T_cross = T_cross,
        model_form_piS = model_form_piS,
        model_form_piA = model_form_piA,
        Bootstrap = bootstrap_flag,
        R = R,
        bootstrap_CI_type = bootstrap_CI_type,
        alpha = alpha, quiet = quiet
      )
    } else if (name == "AIPW") {
      res <- DID_EC_AIPW(
        data = data,
        outcome_col_name = outcome_col_name,
        trial_status_col_name = trial_status_col_name,
        treatment_col_name = treatment_col_name,
        covariates_col_name = covariates_col_name,
        T_cross = T_cross,
        model_form_piS = model_form_piS,
        model_form_piA = model_form_piA,
        model_form_mu0_ext = model_form_mu0_ext,
        Bootstrap = bootstrap_flag,
        R = R,
        bootstrap_CI_type = bootstrap_CI_type,
        alpha = alpha, quiet = quiet
      )
    } else if (name == "OR") {
      res <- DID_EC_OR(
        data = data,
        outcome_col_name = outcome_col_name,
        trial_status_col_name = trial_status_col_name,
        treatment_col_name = treatment_col_name,
        covariates_col_name = covariates_col_name,
        T_cross = T_cross,
        model_form_mu0_ext = model_form_mu0_ext,
        model_form_mu0_rct = model_form_mu0_rct,
        model_form_mu1_rct = model_form_mu1_rct,
        Bootstrap = bootstrap_flag,
        R = R,
        bootstrap_CI_type = bootstrap_CI_type,
        alpha = alpha, quiet = quiet
      )
    } else {
      stop("No such method is defined!")
    }
  } else if (method_type == "method_SCM_obj") {
    if (!quiet) {
      cat("Estimating long term causal effects using synthetic control methods... \n")
    }

    name <- method@method_name
    lambda.min <- method@lambda.min
    lambda.max <- method@lambda.max
    nlambda <- method@nlambda
    parallel <- method@parallel
    ncpus <- method@ncpus

    if (name == "SCM") {
      res <- SCM(
        data = data,
        trial_status_col_name = trial_status_col_name,
        treatment_col_name = treatment_col_name,
        outcome_col_name = outcome_col_name,
        covariates_col_name = covariates_col_name,
        T_cross = T_cross,
        Bootstrap = Bootstrap,
        R = R,
        bootstrap_CI_type = bootstrap_CI_type,
        alpha = alpha,
        lambda.min = lambda.min,
        lambda.max = lambda.max,
        nlambda = nlambda,
        parallel = parallel,
        ncpus = ncpus, quiet = quiet
      )
    } else {
      stop("No such method is defined!")
    }
  } else if (is(method, "ec_ipw_method") || is(method, "ec_aipw_method")) {
    res <- estimate(method,
      data = data,
      outcomes = outcome_col_name,
      treatment = treatment_col_name,
      trial_status = trial_status_col_name,
      covariates = covariates_col_name,
      alpha = alpha,
      quiet = quiet
    )
  } else if (is(method, "did_ec_ipw_method") ||
    is(method, "did_ec_aipw_method") ||
    is(method, "did_ec_or_method") ||
    is(method, "scm_method")) {
    res <- estimate(method,
      data = data,
      outcomes = outcome_col_name,
      treatment = treatment_col_name,
      trial_status = trial_status_col_name,
      covariates = covariates_col_name,
      alpha = alpha,
      quiet = quiet,
      T_cross = T_cross
    )
  } else {
    stop("No such method type is defined!")
  }

  res
}
