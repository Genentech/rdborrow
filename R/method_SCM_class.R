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

#' Construct a method_SCM object
#'
#' @param method_name character. Name of the method.
#' @param bootstrap_flag logical. Whether to use bootstrap for inference.
#' @param bootstrap_obj bootstrap_obj. An object of class `bootstrap_obj`
#'   containing bootstrap settings.
#' @param lambda.min numeric. Minimum value of the regularization parameter.
#' @param lambda.max numeric. Maximum value of the regularization parameter.
#' @param nlambda numeric. Number of lambda values for cross-validation.
#' @param parallel character. Parallelization type (`"no"`, `"multicore"`, or
#'   `"snow"`).
#' @param ncpus numeric. Number of CPU cores to use for parallelization.
#'
#' @return An object of class `method_SCM_obj`.
#' @export
#'
#' @examples
#' setup_method_SCM(
#'   lambda.min = 0,
#'   lambda.max = 1e-3
#' )
setup_method_SCM <- function(method_name = "SCM",
                             bootstrap_flag = FALSE,
                             bootstrap_obj = .bootstrap_obj(),
                             lambda.min,
                             lambda.max,
                             nlambda = 10,
                             parallel = "no",
                             ncpus = 1) {
  .Deprecated("scm")
  checkmate::assert_string(method_name)
  checkmate::assert_flag(bootstrap_flag)
  checkmate::assert_class(bootstrap_obj, "bootstrap_obj")
  checkmate::assert_number(lambda.min)
  checkmate::assert_number(lambda.max)
  if (lambda.max < lambda.min) {
    stop("lambda.max must be greater than or equal to lambda.min")
  }
  checkmate::assert_count(nlambda, positive = TRUE)
  checkmate::assert_choice(parallel, choices = c("no", "multicore", "snow"))
  checkmate::assert_count(ncpus, positive = TRUE)

  method_SCM_obj <- .method_SCM_obj(
    method_name = method_name,
    bootstrap_flag = bootstrap_flag,
    bootstrap_obj = bootstrap_obj,
    lambda.min = lambda.min,
    lambda.max = lambda.max,
    nlambda = nlambda,
    parallel = parallel,
    ncpus = ncpus
  )
}
