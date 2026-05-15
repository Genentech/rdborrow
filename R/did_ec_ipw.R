#' @include ec_ipw.R
NULL

# s4 class definition----
.did_ec_ipw_method <- setClass(
  "did_ec_ipw_method",
  contains = "method_OLE_obj",
  slots = c(
    ps_formula = "character",
    trt_formula = "character",
    bootstrap = "numericOrNULL",
    bootstrap_ci_type = "character"
  ),
  prototype = list(
    method_name = "DID-EC-IPW",
    ps_formula = "",
    trt_formula = "",
    bootstrap = NULL,
    bootstrap_ci_type = "perc"
  )
)

# constructor----

#' DID-EC-IPW method constructor
#'
#' Creates a method object for difference-in-differences IPW estimation
#' with external control borrowing for the open-label extension phase
#' (Zhou et al., 2024).
#'
#' @param ps_formula Formula string for the propensity score model
#'   predicting trial participation.
#' @param trt_formula Formula string for the treatment assignment model,
#'   or \code{""} for marginal probability.
#' @param bootstrap Number of bootstrap replicates (required for DID
#'   methods). Defaults to 500.
#' @param bootstrap_ci_type Bootstrap CI type. Defaults to \code{"perc"}.
#'
#' @return An S4 object of class \code{did_ec_ipw_method}.
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
#' did_ec_ipw(
#'   ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
#'   trt_formula = "A ~ x1 + x2 + x3 + x4 + x5",
#'   bootstrap = 500
#' )
did_ec_ipw <- function(ps_formula,
                       trt_formula = "",
                       bootstrap = 500L,
                       bootstrap_ci_type = NULL) {
  checkmate::assert_string(ps_formula)
  checkmate::assert_string(trt_formula)
  checkmate::assert_count(bootstrap, positive = TRUE)

  if (is.null(bootstrap_ci_type)) {
    bootstrap_ci_type <- "perc"
  }
  checkmate::assert_choice(
    bootstrap_ci_type, c("perc", "bca", "norm", "basic", "stud")
  )

  .did_ec_ipw_method(
    ps_formula = ps_formula,
    trt_formula = trt_formula,
    bootstrap = bootstrap,
    bootstrap_ci_type = bootstrap_ci_type,
    method_name = "DID-EC-IPW",
    bootstrap_flag = TRUE,
    bootstrap_obj = .bootstrap_obj(
      replicates = bootstrap,
      bootstrap_CI_type = bootstrap_ci_type
    )
  )
}

# estimate() method----

#' @rdname estimate
setMethod("estimate", "did_ec_ipw_method", function(method, data, outcomes,
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

  if (!quiet) cat("Running DID-EC-IPW estimator...\n")

  result <- .did_ec_ipw_estimate(
    df, Y, S, A, n, N, pi_S, n_time,
    T_cross, ps_formula, trt_formula
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
    statistic = .did_ec_ipw_statistic,
    outcomes = outcomes,
    ps_formula = ps_formula,
    trt_formula = trt_formula,
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
.did_ec_ipw_estimate <- function(df, Y, S, A, n, N, pi_S, n_time,
                                 T_cross, ps_formula, trt_formula) {
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

  rx <- pi_SX * (1 - pi_S) / (1 - pi_SX) / pi_S

  w11 <- 1 / pi_AX
  w10 <- 1 / (1 - pi_AX)
  w00 <- rx

  Ys <- as.matrix(Y)
  potential <- (S * A * w11 / sum(S * A * w11) +
    S * (1 - A) * w10 / sum(S * (1 - A) * w10) +
    (1 - S) * w00 / sum((1 - S) * w00)) * Ys

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

#' @noRd
.did_ec_ipw_statistic <- function(data, indices, outcomes, ps_formula,
                                  trt_formula, T_cross) {
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

  rx <- pi_SX * (1 - pi_S) / (1 - pi_SX) / pi_S
  w11 <- 1 / pi_AX
  w10 <- 1 / (1 - pi_AX)
  w00 <- rx

  potential <- (S * A * w11 / sum(S * A * w11) +
    S * (1 - A) * w10 / sum(S * (1 - A) * w10) +
    (1 - S) * w00 / sum((1 - S) * w00)) * Y

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
