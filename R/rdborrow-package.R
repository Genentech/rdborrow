#' The rdborrow package
#'
#' rdborrow is a package that implements causal inference methods for 
#' analyzing and designing clinical trials with external controls.
#'
#' @rdname rdborrow-package
#' @name rdborrow-package
#' @keywords rdborrow
#' @aliases rdborrow
#'
#' @importFrom methods is new setClass setMethod setValidity show
#' @importFrom stats as.formula coef glm lm model.matrix predict qnorm rbinom rmultinom rnorm var
#'
#' @section Authors:
#' The following authors contribute to the development and maintainance of the package:
#' 
#' - Lei Shi, University of California Berkeley, \href{mailto:leishi1998@gmail.com}{leishi1998@gmail.com}
#' 
#' - Herbert Pang, Genentech Inc. \href{mailto:pathwayrf@gmail.com}{pathwayrf@gmail.com}
#' 
#' - Chen Chen, Genentech Inc.
#' 
#' - Jiawen Zhu, Genentech Inc.
#' 
#' - Matthew Secrest, Genentech Inc.
#' 
#' @section See Also: 
#' 
#' Useful links:
#' 
#' - GitHub Repo for rdborrow: \url{https://github.com/Genentech/rdborrow}
#' 
#' - Estimating treatment effect in randomized trial after control to treatment crossover using external controls: \url{https://www.tandfonline.com/doi/full/10.1080/10543406.2024.2330209}
#' 
#' - Causal estimators for incorporating external controls in randomized trials with longitudinal outcomes. In submission.
NULL