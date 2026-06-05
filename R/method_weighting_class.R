#' Method weighting class
#'
#' @keywords internal
#' @include method_class.R
.method_weighting_obj <- setClass(
  "method_weighting_obj",
  contains = "method_primary_obj"
)

#' @noRd
.build_analysis_df <- function(data, outcomes, treatment, trial_status,
                               covariates) {
  Y <- as.matrix(data[, outcomes, drop = FALSE])
  data.frame(Y,
    S = data[[trial_status]], A = data[[treatment]],
    data[, covariates, drop = FALSE]
  )
}
