#' Analysis primary class
#'
#' @slot method_obj A `method_primary_obj` specifying the estimation method.
#'
#' @include analysis_class.R
#' @include method_weighting_class.R
.analysis_primary_obj <- setClass(
  "analysis_primary_obj",
  contains = "analysis_obj",
  slots = c(
    method_obj = "method_primary_obj"
  )
)

setMethod(
  f = "show",
  signature = "analysis_primary_obj",
  definition = function(object) {
    cat("<analysis_primary_obj>\n")
    cat("  Observations:", nrow(object@data), "\n")
    cat("  Trial status:", object@trial_status_col_name, "\n")
    cat("  Treatment:", object@treatment_col_name, "\n")
    cat("  Outcomes:", paste(object@outcome_col_name, collapse = ", "), "\n")
    cat("  Covariates:", paste(object@covariates_col_name, collapse = ", "), "\n")
    cat("  Method:", object@method_obj@method_name, "\n")
    cat("  Alpha:", object@alpha, "\n")
  }
)

#' Construct an analysis_primary object
#'
#' @param data A data frame containing all subject-level data.
#' @param trial_status_col_name Name of the trial status column.
#' @param treatment_col_name Name of the treatment column.
#' @param outcome_col_name Character vector of outcome column names.
#' @param covariates_col_name Character vector of covariate column names.
#' @param method_weighting_obj A weighting method object of class
#'   `method_primary_obj`.
#' @param alpha Significance level (default 0.05).
#'
#' @return An object of class `analysis_primary_obj`.
#' @export
#'
#' @examples
#' setup_analysis_primary(
#'   data = SyntheticData,
#'   trial_status_col_name = "S",
#'   treatment_col_name = "A",
#'   outcome_col_name = c("y1", "y2"),
#'   covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
#'   method_weighting_obj = setup_method_weighting(method_name = "IPW")
#' )
setup_analysis_primary <- function(data, trial_status_col_name, treatment_col_name,
                                   outcome_col_name, covariates_col_name, method_weighting_obj,
                                   alpha = 0.05) {
  .validate_analysis_base(
    data, trial_status_col_name, treatment_col_name,
    outcome_col_name, covariates_col_name, alpha
  )
  checkmate::assert_class(method_weighting_obj, "method_primary_obj")

  analysis_primary_obj <- .analysis_primary_obj(
    data = data,
    covariates_col_name = covariates_col_name,
    outcome_col_name = outcome_col_name,
    treatment_col_name = treatment_col_name,
    trial_status_col_name = trial_status_col_name,
    method_obj = method_weighting_obj,
    alpha = alpha
  )
}
