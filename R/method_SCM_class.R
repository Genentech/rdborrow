#' method class
#'
#' @slot parallel Parallelization type for boot.
#' @slot ncpus Number of CPUs for parallel bootstrap.
#' @slot lambda.min Minimum penalty parameter.
#' @slot lambda.max Maximum penalty parameter.
#' @slot nlambda Number of lambda values for cross-validation.
#'
#' @include method_class.R
#' @include bootstrap_class.R
#' @export setup_method_SCM
#'
#' @examples
#' \dontrun{
#' method_SCM_obj <- setup_method_SCM(
#'   method_name = "SCM",
#'   bootstrap_flag = TRUE,
#'   bootstrap_obj = bootstrap_obj,
#'   lambda.min = 0,
#'   lambda.max = 1e-3,
#'   nlambda = 10,
#'   parallel = "multicore",
#'   ncpus = 4
#' )
#' }
.method_SCM_obj <- setClass(
  "method_SCM_obj",
  contains = "method_OLE_obj",
  slots = c(
    lambda.min = "numeric", # minimum value
    lambda.max = "numeric",
    nlambda = "numeric", # nfolds
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
#' @param bootstrap_obj bootstrap_obj. An object of class `bootstrap_obj` containing bootstrap settings.
#' @param lambda.min numeric. The minimum value of the regularization parameter lambda for SCM.
#' @param lambda.max numeric. The maximum value of the regularization parameter lambda for SCM.
#' @param nlambda numeric. The number of lambda values to consider for SCM.
#' @param parallel character. The type of parallelization to use for SCM (e.g., "no", "multicore", "snow").
#' @param ncpus numeric. The number of CPU cores to use for parallelization in SCM.
#'
#' @return An object of class `method_SCM_obj`.
setup_method_SCM <- function(method_name = "SCM",
                             bootstrap_flag = FALSE,
                             bootstrap_obj = .bootstrap_obj(),
                             lambda.min,
                             lambda.max,
                             nlambda = 10,
                             parallel = "no",
                             ncpus = 1) {
  # TODO: sanity check
  # correct initialization of objects
  # correct dimension compatible
  # validity
  # model_form_mu0 and the dimension of the random vector

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
