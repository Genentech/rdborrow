#' @include did_ec_ipw.R
NULL

# s4 class definition----
.did_ec_or_method <- setClass(
  "did_ec_or_method",
  contains = "method_OLE_obj",
  slots = c(
    outcome_formula_ext = "character",
    outcome_formula_rct_ctrl = "character",
    outcome_formula_rct_trt = "character",
    bootstrap = "numericOrNULL",
    bootstrap_ci_type = "character"
  ),
  prototype = list(
    method_name = "DID-EC-OR",
    outcome_formula_ext = "",
    outcome_formula_rct_ctrl = "",
    outcome_formula_rct_trt = "",
    bootstrap = NULL,
    bootstrap_ci_type = "perc"
  )
)

# constructor----

#' DID-EC-OR method constructor
#'
#' Creates a method object for difference-in-differences outcome
#' regression estimation with external control borrowing for the
#' open-label extension phase (Zhou et al., 2024).
#'
#' @param outcome_formula_ext Character vector of outcome model formulas
#'   for external controls, one per time point.
#' @param outcome_formula_rct_ctrl Character vector of outcome model
#'   formulas for RCT control subjects, one per time point.
#' @param outcome_formula_rct_trt Character vector of outcome model
#'   formulas for RCT treated subjects, one per time point.
#' @param bootstrap Number of bootstrap replicates. Defaults to 500.
#' @param bootstrap_ci_type Bootstrap CI type. Defaults to \code{"perc"}.
#'
#' @return An S4 object of class \code{did_ec_or_method}.
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
#' model_forms <- c(
#'   "y1 ~ x1 + x2 + x3 + x4 + x5",
#'   "y2 ~ x1 + x2 + x3 + x4 + x5",
#'   "y3 ~ x1 + x2 + x3 + x4 + x5",
#'   "y4 ~ x1 + x2 + x3 + x4 + x5"
#' )
#' did_ec_or(
#'   outcome_formula_ext = model_forms,
#'   outcome_formula_rct_ctrl = model_forms,
#'   outcome_formula_rct_trt = model_forms,
#'   bootstrap = 500
#' )
did_ec_or <- function(outcome_formula_ext,
                      outcome_formula_rct_ctrl,
                      outcome_formula_rct_trt,
                      bootstrap = 500L,
                      bootstrap_ci_type = NULL) {
  checkmate::assert_character(outcome_formula_ext, min.len = 1)
  checkmate::assert_character(outcome_formula_rct_ctrl, min.len = 1)
  checkmate::assert_character(outcome_formula_rct_trt, min.len = 1)
  checkmate::assert_count(bootstrap, positive = TRUE)

  if (is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  checkmate::assert_choice(
    bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
  )

  .did_ec_or_method(
    outcome_formula_ext = outcome_formula_ext,
    outcome_formula_rct_ctrl = outcome_formula_rct_ctrl,
    outcome_formula_rct_trt = outcome_formula_rct_trt,
    bootstrap = bootstrap,
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "DID-EC-OR",
    bootstrap_flag = TRUE,
    bootstrap_obj = .bootstrap_obj(
      replicates = bootstrap,
      bootstrap_CI_type = bootstrap_ci_type
    )
  )
}

# estimate() method----

#' @rdname estimate
setMethod("estimate", "did_ec_or_method", function(method, data, outcomes,
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

  df <- data.frame(Y, S = S, A = A, data[, covariates, drop = FALSE])

  if (!quiet) cat("Running DID-EC-OR estimator...\n")

  result <- .did_ec_or_estimate(
    df, S, A, n, n_time, T_cross,
    method@outcome_formula_ext,
    method@outcome_formula_rct_ctrl,
    method@outcome_formula_rct_trt
  )
  tau <- result$tau

  if (!quiet) cat("Running bootstrap inference...\n")
  group_id <- as.integer(interaction(df$S, df$A, drop = TRUE))

  boot_ci_type_long <- switch(method@bootstrap_ci_type,
    norm = "normal",
    bca = "bca",
    stud = "student",
    perc = "percent",
    basic = "basic"
  )

  boot_out <- boot::boot(
    data = df,
    statistic = .did_ec_or_statistic,
    outcomes = outcomes,
    outcome_formula_ext = method@outcome_formula_ext,
    outcome_formula_rct_ctrl = method@outcome_formula_rct_ctrl,
    outcome_formula_rct_trt = method@outcome_formula_rct_trt,
    T_cross = T_cross,
    R = method@bootstrap,
    strata = group_id
  )

  n_ole <- n_time - T_cross

  lower_ci <- vapply(seq_len(n_ole), \(i) {
    ci <- boot::boot.ci(boot_out,
      conf = 1 - alpha,
      type = method@bootstrap_ci_type, index = i
    )
    ci[[boot_ci_type_long]][4]
  }, numeric(1))

  upper_ci <- vapply(seq_len(n_ole), \(i) {
    ci <- boot::boot.ci(boot_out,
      conf = 1 - alpha,
      type = method@bootstrap_ci_type, index = i
    )
    ci[[boot_ci_type_long]][5]
  }, numeric(1))

  data.frame(
    point_estimates = tau,
    lower_CI_boot = lower_ci,
    upper_CI_boot = upper_ci,
    row.names = paste0("tau", (T_cross + 1):n_time)
  )
})

# internal helpers----

#' @noRd
.did_ec_or_estimate <- function(df, S, A, n, n_time, T_cross,
                                outcome_formula_ext,
                                outcome_formula_rct_ctrl,
                                outcome_formula_rct_trt) {
  T_pc <- T_cross

  # external outcome models
  model_list_ext <- lapply(seq_len(n_time), \(t) {
    lm(as.formula(outcome_formula_ext[t]), data = df[S == 0, , drop = FALSE])
  })

  # rct outcome models: control for placebo period, treated for OLE period
  model_list_rct_pc <- lapply(seq_len(T_pc), \(t) {
    lm(as.formula(outcome_formula_rct_ctrl[t]),
      data = df[S == 1 & A == 0, , drop = FALSE]
    )
  })
  model_list_rct_cr <- lapply((T_pc + 1):n_time, \(t) {
    lm(as.formula(outcome_formula_rct_trt[t]),
      data = df[S == 1 & A == 1, , drop = FALSE]
    )
  })
  model_list_rct <- c(model_list_rct_pc, model_list_rct_cr)

  rct_data <- df[S == 1, , drop = FALSE]

  # predicted outcomes for RCT subjects from external models
  mu_S0A0 <- vapply(seq_len(n_time), \(t) {
    predict(model_list_ext[[t]], newdata = rct_data)
  }, numeric(n))
  avg_S0A0 <- colMeans(mu_S0A0)

  # predicted outcomes for RCT subjects from RCT models
  mu_S1 <- vapply(seq_len(n_time), \(t) {
    predict(model_list_rct[[t]], newdata = rct_data)
  }, numeric(n))
  avg_S1 <- colMeans(mu_S1)

  tau <- (avg_S1[(T_pc + 1):n_time] - mean(avg_S1[1:T_pc])) -
    (avg_S0A0[(T_pc + 1):n_time] - mean(avg_S0A0[1:T_pc]))

  list(tau = tau)
}

#' @noRd
.did_ec_or_statistic <- function(data, indices, outcomes,
                                 outcome_formula_ext,
                                 outcome_formula_rct_ctrl,
                                 outcome_formula_rct_trt,
                                 T_cross) {
  d <- data[indices, , drop = FALSE]
  S <- d$S
  A <- d$A
  n <- sum(S)
  n_time <- length(outcomes)
  T_pc <- T_cross

  model_list_ext <- lapply(seq_len(n_time), \(t) {
    lm(as.formula(outcome_formula_ext[t]), data = d[S == 0, , drop = FALSE])
  })
  model_list_rct_pc <- lapply(seq_len(T_pc), \(t) {
    lm(as.formula(outcome_formula_rct_ctrl[t]),
      data = d[S == 1 & A == 0, , drop = FALSE]
    )
  })
  model_list_rct_cr <- lapply((T_pc + 1):n_time, \(t) {
    lm(as.formula(outcome_formula_rct_trt[t]),
      data = d[S == 1 & A == 1, , drop = FALSE]
    )
  })
  model_list_rct <- c(model_list_rct_pc, model_list_rct_cr)

  rct_data <- d[S == 1, , drop = FALSE]

  mu_S0A0 <- vapply(seq_len(n_time), \(t) {
    predict(model_list_ext[[t]], newdata = rct_data)
  }, numeric(n))
  avg_S0A0 <- colMeans(mu_S0A0)

  mu_S1 <- vapply(seq_len(n_time), \(t) {
    predict(model_list_rct[[t]], newdata = rct_data)
  }, numeric(n))
  avg_S1 <- colMeans(mu_S1)

  (avg_S1[(T_pc + 1):n_time] - mean(avg_S1[1:T_pc])) -
    (avg_S0A0[(T_pc + 1):n_time] - mean(avg_S0A0[1:T_pc]))
}
