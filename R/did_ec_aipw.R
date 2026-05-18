#' @include did_ec_ipw.R
NULL

# S4 class definition----
.did_ec_aipw_method <- setClass(
  "did_ec_aipw_method",
  contains = "method_DID_obj",
  slots = c(
    ps_formula = "character",
    trt_formula = "character",
    outcome_formula = "character",
    bootstrap = "numericOrNULL",
    bootstrap_ci_type = "character"
  ),
  prototype = list(
    method_name = "DID-EC-AIPW",
    ps_formula = "",
    trt_formula = "",
    outcome_formula = "",
    bootstrap = NULL,
    bootstrap_ci_type = "perc"
  )
)

#' DID-EC-AIPW method
#'
#' Creates a method object for difference-in-differences augmented IPW
#' estimation with external control borrowing for the open-label
#' extension phase (Zhou et al., 2024).
#'
#' @param ps_formula Formula string for the propensity score model
#'   predicting trial participation.
#' @param trt_formula Formula string for the treatment assignment model,
#'   or \code{""} for marginal probability.
#' @param outcome_formula Character vector of outcome model formulas,
#'   one per time point.
#' @param bootstrap Number of bootstrap replicates. Defaults to 500.
#' @param bootstrap_ci_type Bootstrap CI type. Defaults to \code{"perc"}.
#'
#' @return An S4 object of class \code{did_ec_aipw_method}.
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
#' did_ec_aipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
#'   outcome_formula = c(
#'     "y1 ~ x1 + x2 + x3 + x4 + x5",
#'     "y2 ~ x1 + x2 + x3 + x4 + x5",
#'     "y3 ~ x1 + x2 + x3 + x4 + x5",
#'     "y4 ~ x1 + x2 + x3 + x4 + x5"
#'   ),
#'   bootstrap = 500
#' )
did_ec_aipw <- function(ps_formula,
                        trt_formula = "",
                        outcome_formula,
                        bootstrap = 500L,
                        bootstrap_ci_type = NULL) {
  checkmate::assert_string(ps_formula)
  checkmate::assert_string(trt_formula)
  checkmate::assert_character(outcome_formula, min.len = 1)
  checkmate::assert_count(bootstrap, positive = TRUE)

  if (is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  checkmate::assert_choice(
    bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
  )

  .did_ec_aipw_method(
    ps_formula = ps_formula,
    trt_formula = trt_formula,
    outcome_formula = outcome_formula,
    bootstrap = bootstrap,
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "DID-EC-AIPW",
    bootstrap_flag = TRUE,
    bootstrap_obj = .bootstrap_obj(
      replicates = bootstrap,
      bootstrap_CI_type = bootstrap_ci_type
    )
  )
}

#' @rdname estimate
setMethod("estimate", "did_ec_aipw_method", function(method, data, outcomes,
                                                     treatment, trial_status,
                                                     covariates, alpha = 0.05,
                                                     quiet = TRUE,
                                                     T_cross) {
  Y <- as.matrix(data[, outcomes, drop = FALSE])
  S <- data[[trial_status]]
  A <- data[[treatment]]
  n_time <- ncol(Y)
  N <- nrow(data)
  n <- sum(S)
  pi_S <- n / N

  ps_formula <- sub("^[^~]*~", paste0(trial_status, " ~"), method@ps_formula)
  trt_formula <- method@trt_formula
  if (trt_formula != "") {
    trt_formula <- sub("^[^~]*~", paste0(treatment, " ~"), trt_formula)
  }

  df <- data.frame(Y, S = S, A = A, data[, covariates, drop = FALSE])

  if (!quiet) cat("Running DID-EC-AIPW estimator...\n")

  result <- .did_ec_aipw_core(
    df, Y, S, A, n, N, pi_S, n_time,
    T_cross, ps_formula, trt_formula,
    method@outcome_formula
  )
  tau <- result$tau

  if (!quiet) cat("Running bootstrap inference...\n")

  n_ole <- n_time - T_cross
  boot_res <- .run_bootstrap(
    df = df, statistic = .did_ec_aipw_statistic,
    n_estimates = n_ole, bootstrap = method@bootstrap,
    bootstrap_ci_type = method@bootstrap_ci_type, alpha = alpha,
    outcomes = outcomes, ps_formula = ps_formula,
    trt_formula = trt_formula, outcome_formula = method@outcome_formula,
    T_cross = T_cross
  )

  data.frame(
    point_estimates = tau,
    lower_CI_boot = boot_res$lower_ci,
    upper_CI_boot = boot_res$upper_ci,
    row.names = paste0("tau", (T_cross + 1):n_time)
  )
})

# internal helpers----

#' DID-EC-AIPW point estimate.
#' augments DID-IPW with outcome regression: uses residuals Y-mu(X)
#' instead of raw outcomes for the weighted potential outcomes.
#' @param df internal data frame.
#' @param Y outcome matrix (N x T).
#' @param S trial participation vector.
#' @param A treatment vector.
#' @param n number of RCT subjects.
#' @param N total sample size.
#' @param pi_S marginal trial participation probability.
#' @param n_time number of time points.
#' @param T_cross crossover time point.
#' @param ps_formula propensity score formula.
#' @param trt_formula treatment assignment formula.
#' @param outcome_formula character vector of outcome model formulas.
#' @return list with tau vector.
#' @noRd
.did_ec_aipw_core <- function(df, Y, S, A, n, N, pi_S, n_time,
                              T_cross, ps_formula, trt_formula,
                              outcome_formula) {
  ps_model <- glm(as.formula(ps_formula), data = df, family = "binomial")
  pi_SX <- predict(ps_model, newdata = df, type = "response")

  if (trt_formula == "") {
    pi_AX <- sum(A[S == 1]) / n
  } else {
    trt_model <- glm(as.formula(trt_formula),
      data = df[S == 1, , drop = FALSE], family = "binomial"
    )
    pi_AX <- predict(trt_model, newdata = df, type = "response")
  }

  # outcome models on external controls
  Y0_models <- lapply(outcome_formula, \(f) {
    lm(as.formula(f), data = df[S == 0, , drop = FALSE])
  })
  Y0 <- vapply(seq_len(n_time), \(t) {
    predict(Y0_models[[t]], newdata = df)
  }, numeric(N))
  Yr <- Y - Y0

  rx <- pi_SX * (1 - pi_S) / (1 - pi_SX) / pi_S
  w11 <- 1 / pi_AX
  w10 <- 1 / (1 - pi_AX)
  w00 <- rx

  potential <- (S * A * w11 / sum(S * A * w11) +
    S * (1 - A) * w10 / sum(S * (1 - A) * w10) +
    (1 - S) * w00 / sum((1 - S) * w00)) * Yr

  T_pc <- T_cross
  mu_S1A1 <- colSums(
    potential[S == 1 & A == 1, (T_pc + 1):n_time, drop = FALSE]
  )
  mu_S0A0 <- colSums(
    potential[S == 0, (T_pc + 1):n_time, drop = FALSE]
  )
  bias <- sum(rowMeans(
    potential[S == 1 & A == 0, 1:T_pc, drop = FALSE]
  )) - sum(rowMeans(
    potential[S == 0, 1:T_pc, drop = FALSE]
  ))

  tau <- mu_S1A1 - mu_S0A0 - bias
  list(tau = tau)
}

#' bootstrap statistic for DID-EC-AIPW.
#' refits PS, treatment, and outcome models on each resample.
#' @param data internal data frame.
#' @param indices bootstrap sample indices.
#' @param outcomes outcome column names.
#' @param ps_formula propensity score formula.
#' @param trt_formula treatment assignment formula.
#' @param outcome_formula outcome model formulas.
#' @param T_cross crossover time point.
#' @return numeric vector of tau estimates.
#' @noRd
.did_ec_aipw_statistic <- function(data, indices, outcomes, ps_formula,
                                   trt_formula, outcome_formula, T_cross) {
  d <- data[indices, , drop = FALSE]
  Y <- as.matrix(d[, outcomes, drop = FALSE])
  S <- d$S
  A <- d$A
  n <- sum(S)
  N <- nrow(d)
  n_time <- ncol(Y)
  pi_S <- n / N

  ps_model <- glm(as.formula(ps_formula), data = d, family = "binomial")
  pi_SX <- predict(ps_model, newdata = d, type = "response")

  if (trt_formula == "") {
    pi_AX <- sum(A[S == 1]) / n
  } else {
    trt_model <- glm(as.formula(trt_formula),
      data = d[S == 1, , drop = FALSE], family = "binomial"
    )
    pi_AX <- predict(trt_model, newdata = d, type = "response")
  }

  Y0_models <- lapply(outcome_formula, \(f) {
    lm(as.formula(f), data = d[S == 0, , drop = FALSE])
  })
  Y0 <- vapply(seq_len(n_time), \(t) {
    predict(Y0_models[[t]], newdata = d)
  }, numeric(N))
  Yr <- Y - Y0

  rx <- pi_SX * (1 - pi_S) / (1 - pi_SX) / pi_S
  w11 <- 1 / pi_AX
  w10 <- 1 / (1 - pi_AX)
  w00 <- rx

  potential <- (S * A * w11 / sum(S * A * w11) +
    S * (1 - A) * w10 / sum(S * (1 - A) * w10) +
    (1 - S) * w00 / sum((1 - S) * w00)) * Yr

  T_pc <- T_cross
  mu_S1A1 <- colSums(
    potential[S == 1 & A == 1, (T_pc + 1):n_time, drop = FALSE]
  )
  mu_S0A0 <- colSums(
    potential[S == 0, (T_pc + 1):n_time, drop = FALSE]
  )
  bias <- sum(rowMeans(
    potential[S == 1 & A == 0, 1:T_pc, drop = FALSE]
  )) - sum(rowMeans(
    potential[S == 0, 1:T_pc, drop = FALSE]
  ))

  mu_S1A1 - mu_S0A0 - bias
}
