#' Method SCM class
#'
#' @slot parallel Parallelization type for boot.
#' @slot ncpus Number of CPUs for parallel bootstrap.
#' @slot lambda.min Minimum penalty parameter.
#' @slot lambda.max Maximum penalty parameter.
#' @slot nlambda Number of lambda values for cross-validation.
#'
#' @keywords internal
#' @include method_class.R
#' @include bootstrap_class.R
.method_SCM_obj <- setClass(
  "method_SCM_obj",
  contains = "method_OLE_obj",
  slots = c(
    lambda.min = "numeric",
    lambda.max = "numeric",
    nlambda = "numeric",
    parallel = "character",
    ncpus = "numeric"
  ),
  prototype = list(
    nlambda = 10,
    parallel = "no",
    ncpus = 1
  )
)

