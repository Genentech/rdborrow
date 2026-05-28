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
#' @keywords internal
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


# build_analysis_df generic----
setGeneric("build_analysis_df", function(method, data, outcomes, treatment,
                                         trial_status, covariates) {
  standardGeneric("build_analysis_df")
})

#' @noRd
setMethod("build_analysis_df", "method_weighting_obj", function(method, data,
                                                                outcomes,
                                                                treatment,
                                                                trial_status,
                                                                covariates) {
  Y <- as.matrix(data[, outcomes, drop = FALSE])
  data.frame(Y,
    S = data[[trial_status]], A = data[[treatment]],
    data[, covariates, drop = FALSE]
  )
})

# class unions----
setClassUnion("numericOrNULL", c("numeric", "NULL"))
setClassUnion("characterOrNULL", c("character", "NULL"))
