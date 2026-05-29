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

  if (is(method, "ec_ipw_method") || is(method, "ec_aipw_method")) {
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
