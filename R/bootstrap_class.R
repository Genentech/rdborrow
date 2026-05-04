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
    ci_type <- switch(object@bootstrap_CI_type,
      norm = "Normal approximation",
      bca = "Bias-corrected accelerated (BCa)",
      stud = "Studentized",
      perc = "Percentile",
      basic = "Basic"
    )
    cat("<bootstrap_obj>\n")
    cat("  Replicates:", object@replicates, "\n")
    cat("  CI type:", ci_type, "\n")
  }
)

#' Construct a bootstrap object
#'
#' @param replicates Number of bootstrap replicates.
#' @param bootstrap_CI_type Type of bootstrap CI. One of \code{"bca"},
#'   \code{"norm"}, \code{"basic"}, \code{"stud"}, or \code{"perc"}.
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
  # validity----
  checkmate::assert_count(replicates, positive = TRUE)
  checkmate::assert_choice(bootstrap_CI_type,
    choices = c("bca", "norm", "basic", "stud", "perc")
  )

  # constructor----
  bootstrap_obj <- .bootstrap_obj(
    replicates = replicates,
    bootstrap_CI_type = bootstrap_CI_type
  )
}
