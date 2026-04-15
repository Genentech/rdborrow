#' Bootstrap class
#'
#' @slot replicates Number of bootstrap replicates.
#' @slot bootstrap_CI_type Type of bootstrap confidence interval.
#'
#' @include method_class.R
.bootstrap_obj <- setClass(
  "bootstrap_obj",
  slots = c(
    replicates = "numeric",
    bootstrap_CI_type = "character"
  ),
  prototype = list(
    replicates = 5e2,
    bootstrap_CI_type = "bca"
  )
)

setMethod(
  f = "show",
  signature = "bootstrap_obj",
  definition = function(object) {
    # "norm","basic", "stud", "perc", "bca"
    boot.ci.type <- switch(object@bootstrap_CI_type,
      norm = "normal approximation",
      bca = "bias-corrected",
      stud = "studentized",
      perc = "percentile",
      basic = "basic"
    )
    cat("Running Bootstrap: ", ifelse(object@bootstrap_flag, "Yes", "No"), "\n")
    cat("Number of Replicates: ", as.character(object@replicates), "\n")
    cat("Type of bootstrap confidence interval: ", boot.ci.type)
  }
)

#' Construct a bootstrap object
#'
#' @param replicates Number of bootstrap replicates.
#' @param bootstrap_CI_type Type of bootstrap CI (e.g. \code{"bca"}, \code{"perc"}).
#'
#' @return A bootstrap object.
#' @export
#'
#' @examples
#' bootstrap_obj <- setup_bootstrap(
#'   replicates = 2e3,
#'   bootstrap_CI_type = "perc"
#' )
setup_bootstrap <- function(replicates = 5e2,
                            bootstrap_CI_type = "bca") {
  # TODO: sanity check
  # correct initialization of objects
  # correct dimension compatible
  # validity
  # length of long_term_marker the same as outcome dimension
  # if long_term_flag = FALSE, then long_term_marker should all be F

  bootstrap_obj <- .bootstrap_obj(
    replicates = replicates,
    bootstrap_CI_type = bootstrap_CI_type
  )
}
