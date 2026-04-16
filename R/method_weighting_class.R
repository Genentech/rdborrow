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
  .validate_method_base(method_name, bootstrap_flag, bootstrap_obj)
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
