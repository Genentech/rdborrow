#' Setup method weighting (Deprecated)
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function has been removed. Use [ec_ipw()] for inverse
#' probability weighting or [ec_aipw()] for augmented inverse
#' probability weighting.
#'
#' @param ... Ignored.
#'
#' @export
setup_method_weighting <- function(...) {
  .Deprecated(msg = paste(
    "'setup_method_weighting' has been removed.",
    "Use ec_ipw() or ec_aipw() instead."
  ))
  stop(
    "setup_method_weighting() is no longer functional. ",
    "Use ec_ipw() or ec_aipw().",
    call. = FALSE
  )
}
