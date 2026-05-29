#' Method DID class
#'
#' @slot model_form_mu0_ext Formula string for external control outcome model.
#' @slot model_form_mu0_rct Formula string for RCT control outcome model.
#' @slot model_form_mu1_rct Formula string for RCT treatment outcome model.
#' @slot model_form_piS Formula string for trial participation model.
#' @slot model_form_piA Formula string for treatment assignment model.
#'
#' @keywords internal
#' @include method_class.R
#' @include bootstrap_class.R
.method_DID_obj <- setClass(
  "method_DID_obj",
  contains = "method_OLE_obj",
  slots = c(
    bootstrap_flag = "logical",
    bootstrap_obj = "bootstrap_obj",
    model_form_piS = "character",
    model_form_piA = "character",
    model_form_mu0_ext = "character",
    model_form_mu0_rct = "character",
    model_form_mu1_rct = "character"
  ),
  prototype = list(
    bootstrap_flag = FALSE,
    bootstrap_obj = .bootstrap_obj(),
    model_form_piA = "",
    model_form_piS = "",
    model_form_mu0_ext = "",
    model_form_mu0_rct = "",
    model_form_mu1_rct = ""
  )
)

