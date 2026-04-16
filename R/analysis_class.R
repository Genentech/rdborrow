#' Analysis class
#'
#' @slot method_obj Method.
#' @slot data Data frame of subject-level data.
#' @slot covariates_col_name Character vector of covariate column names.
#' @slot outcome_col_name Character vector of outcome column names.
#' @slot treatment_col_name Name of the treatment column.
#' @slot trial_status_col_name Name of the trial status column.
#' @slot alpha Significance level.
#'
#' @include method_class.R
.analysis_obj <- setClass(
  "analysis_obj",
  slots = c(
    data = "data.frame",
    covariates_col_name = "character",
    outcome_col_name = "character",
    treatment_col_name = "character",
    trial_status_col_name = "character",
    method_obj = "method_obj",
    alpha = "numeric"
  ),
  prototype = list(
    covariates_col_name = ""
  )
)

setMethod(
  f = "show",
  signature = "analysis_obj",
  definition = function(object) {
    cat("<analysis_obj>\n")
    cat("  Observations:", nrow(object@data), "\n")
    cat("  Trial status:", object@trial_status_col_name, "\n")
    cat("  Treatment:", object@treatment_col_name, "\n")
    cat("  Outcomes:", paste(object@outcome_col_name, collapse = ", "), "\n")
    cat("  Covariates:", paste(object@covariates_col_name, collapse = ", "), "\n")
    cat("  Method:", object@method_obj@method_name, "\n")
    cat("  Alpha:", object@alpha, "\n")
  }
)

#' Construct an analysis object
#'
#' @param data A data frame containing all subject-level data.
#' @param trial_status_col_name Name of the trial status column.
#' @param treatment_col_name Name of the treatment column.
#' @param outcome_col_name Character vector of outcome column names.
#' @param covariates_col_name Character vector of covariate column names.
#' @param method_obj A method object specifying the estimation method.
#' @param alpha Significance level (default 0.05).
#'
#' @return An object of class `analysis_obj`.
#' @export
#'
#' @examples
#' setup_analysis(
#'   data = SyntheticData,
#'   trial_status_col_name = "S",
#'   treatment_col_name = "A",
#'   outcome_col_name = c("y1", "y2"),
#'   covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
#'   method_obj = setup_method(method_name = "AIPW")
#' )
.validate_analysis_base <- function(data, trial_status_col_name,
                                    treatment_col_name, outcome_col_name,
                                    covariates_col_name, alpha) {
  checkmate::assert_data_frame(data)
  checkmate::assert_string(trial_status_col_name)
  checkmate::assert_string(treatment_col_name)
  checkmate::assert_character(outcome_col_name, min.len = 1)
  checkmate::assert_character(covariates_col_name, min.len = 1)
  checkmate::assert_number(alpha, lower = 0, upper = 1)
  checkmate::assert_subset(
    c(
      trial_status_col_name, treatment_col_name,
      outcome_col_name, covariates_col_name
    ),
    choices = names(data)
  )
}

setup_analysis <- function(data, trial_status_col_name, treatment_col_name,
                           outcome_col_name, covariates_col_name, method_obj,
                           alpha = 0.05) {
  .validate_analysis_base(
    data, trial_status_col_name, treatment_col_name,
    outcome_col_name, covariates_col_name, alpha
  )
  checkmate::assert_class(method_obj, "method_obj")

  analysis_obj <- .analysis_obj(
    data = data,
    covariates_col_name = covariates_col_name,
    outcome_col_name = outcome_col_name,
    treatment_col_name = treatment_col_name,
    trial_status_col_name = trial_status_col_name,
    method_obj = method_obj,
    alpha = alpha
  )
}
