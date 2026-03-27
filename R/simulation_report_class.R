#' Simulation class
#'
#' @slot method_description
#' @slot bias
#' @slot variance
#' @slot mse
#' @slot coverage
#' @slot type_I_error
#' @slot power
#'
#' @include method_class.R
#' @export setup_simulation
#'
.simulation_report_obj <- setClass(
  "simulation_report_obj",
  slots = c(
    method_description = "character",
    bias = "numeric",
    variance = "numeric",
    mse = "numeric",
    coverage = "numeric",
    type_I_error = "numeric",
    power = "numeric"
  ),
  prototype = c(
    power = numeric(0),
    type_I_error = numeric(0)
  )
)

## the show method
setMethod(
  f = "show",
  signature = "simulation_report_obj",
  definition = function(object) {
    full_data <- data.frame(
      method_description = object@method_description,
      bias = object@bias,
      variance = object@variance,
      mse = object@mse,
      coverage = object@coverage
    )
    if (length(object@type_I_error) != 0) {
      full_data$type_I_error <- object@type_I_error
    }
    if (length(object@power) != 0) {
      full_data$power <- object@power
    }
    print(full_data)
  }
)

#' setup_simulation_report
#'
#' @param method_description Character vector of method labels.
#' @param bias Numeric vector of bias estimates.
#' @param variance Numeric vector of variance estimates.
#' @param mse Numeric vector of MSE estimates.
#' @param coverage Numeric vector of coverage probabilities.
#' @param type_I_error Numeric vector of type I error rates.
#' @param power Numeric vector of power estimates.
#'
#' @return A \code{simulation_report_obj}.
#' @export
setup_simulation_report <- function(method_description,
                                    bias,
                                    variance,
                                    mse,
                                    coverage,
                                    type_I_error = numeric(0),
                                    power = numeric(0)) {
  # TODO: sanity check
  # correct initialization of objects
  # correct dimension compatible
  # validity

  simulation_report_obj <- .simulation_report_obj(
    method_description = method_description,
    bias = bias,
    variance = variance,
    mse = mse,
    coverage = coverage,
    type_I_error = type_I_error,
    power = power
  )
}
