#' method class
#'
#' @slot method_name character.
#' @slot bootstrap_flag Logical indicating whether bootstrap inference is used.
#' @slot bootstrap_obj A bootstrap_obj with bootstrap settings.
#'
#' @include bootstrap_class.R
.method_obj <- setClass(
  "method_obj",
  slots = c(
    method_name = "character",
    bootstrap_flag = "logical",
    bootstrap_obj = "bootstrap_obj"
  )
)

.method_primary_obj <- setClass(
  "method_primary_obj",
  contains = "method_obj"
)

.method_OLE_obj <- setClass(
  "method_OLE_obj",
  contains = "method_obj"
)

#' Construct a method object
#'
#' @param method_name character. Name of the method.
#' @param bootstrap_flag logical. Whether to use bootstrap for inference.
#' @param bootstrap_obj bootstrap_obj. An object of class `bootstrap_obj`
#'   containing bootstrap settings.
#'
#' @return An object of class `method_obj`.
#' @export
#'
#' @examples
#' setup_method(
#'   method_name = "AIPW",
#'   bootstrap_flag = TRUE,
#'   bootstrap_obj = setup_bootstrap()
#' )
setup_method <- function(method_name = "",
                         bootstrap_flag = FALSE,
                         bootstrap_obj = .bootstrap_obj()) {
  checkmate::assert_string(method_name)
  checkmate::assert_flag(bootstrap_flag)
  checkmate::assert_class(bootstrap_obj, "bootstrap_obj")

  method_obj <- .method_obj(
    method_name = method_name,
    bootstrap_flag = bootstrap_flag,
    bootstrap_obj = bootstrap_obj
  )
}
