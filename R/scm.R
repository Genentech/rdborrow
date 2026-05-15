#' @include did_ec_ipw.R
NULL

# s4 class definition----
.scm_method <- setClass(
  "scm_method",
  contains = "method_SCM_obj",
  slots = c(
    lambda_min = "numeric",
    lambda_max = "numeric",
    nlambda = "integer",
    parallel = "character",
    ncpus = "integer",
    bootstrap = "numeric",
    bootstrap_ci_type = "character"
  ),
  prototype = list(
    method_name = "SCM",
    lambda_min = 0,
    lambda_max = 0.1,
    nlambda = 2L,
    parallel = "no",
    ncpus = 1L,
    bootstrap = 100L,
    bootstrap_ci_type = "perc"
  )
)

# constructor----

#' SCM method constructor
#'
#' Creates a method object for synthetic control estimation with
#' external control borrowing for the open-label extension phase
#' (Zhou et al., 2024). The SCM method constructs a weighted
#' combination of external controls that matches each RCT control
#' subject on covariates and pre-crossover outcomes.
#'
#' @param lambda_min Minimum penalty parameter for LOOCV.
#' @param lambda_max Maximum penalty parameter for LOOCV.
#' @param nlambda Number of lambda values to evaluate in LOOCV.
#' @param parallel Parallelization type for bootstrap (\code{"no"},
#'   \code{"multicore"}, or \code{"snow"}).
#' @param ncpus Number of CPUs for parallel bootstrap.
#' @param bootstrap Number of bootstrap replicates. Defaults to 200.
#' @param bootstrap_ci_type Bootstrap CI type. Defaults to \code{"perc"}.
#'
#' @return An S4 object of class \code{scm_method}.
#'
#' @references
#' Zhou et al. (2024). Estimating treatment effect in randomized trial
#' after control to treatment crossover using external controls.
#' \emph{Journal of Biopharmaceutical Statistics}.
#' \doi{10.1080/10543406.2024.2444222}
#'
#' @export
#'
#' @examples
#' scm(lambda_min = 0, lambda_max = 0.001, nlambda = 2, bootstrap = 50)
scm <- function(lambda_min = 0,
                lambda_max = 0.1,
                nlambda = 2L,
                parallel = "no",
                ncpus = 1L,
                bootstrap = 200L,
                bootstrap_ci_type = NULL) {
  checkmate::assert_number(lambda_min, lower = 0)
  checkmate::assert_number(lambda_max, lower = lambda_min)
  checkmate::assert_count(nlambda, positive = TRUE)
  checkmate::assert_choice(parallel, c("no", "multicore", "snow"))
  checkmate::assert_count(ncpus, positive = TRUE)
  checkmate::assert_count(bootstrap, positive = TRUE)

  if (is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  checkmate::assert_choice(
    bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
  )

  .scm_method(
    lambda_min = lambda_min,
    lambda_max = lambda_max,
    nlambda = as.integer(nlambda),
    parallel = parallel,
    ncpus = as.integer(ncpus),
    bootstrap = as.integer(bootstrap),
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "SCM",
    bootstrap_flag = TRUE,
    bootstrap_obj = .bootstrap_obj(
      replicates = as.integer(bootstrap),
      bootstrap_CI_type = bootstrap_ci_type
    )
  )
}

# estimate() method----

#' @rdname estimate
setMethod("estimate", "scm_method", function(method, data, outcomes,
                                             treatment, trial_status,
                                             covariates, alpha = 0.05,
                                             quiet = TRUE,
                                             T_cross) {
  SCM(
    data = data,
    outcome_col_name = outcomes,
    trial_status_col_name = trial_status,
    treatment_col_name = treatment,
    covariates_col_name = covariates,
    T_cross = T_cross,
    Bootstrap = TRUE,
    R = method@bootstrap,
    bootstrap_CI_type = method@bootstrap_ci_type,
    alpha = alpha,
    lambda.min = method@lambda_min,
    lambda.max = method@lambda_max,
    nlambda = method@nlambda,
    parallel = method@parallel,
    ncpus = method@ncpus,
    quiet = quiet
  )
})
