# density-ratio weights for external controls----
#' Fit the trial-participation propensity model and form the density-ratio
#' weights used by every external-control weighting estimator.
#' shared by ec_ipw, ec_aipw, did_ec_ipw and did_ec_aipw.
#' when ps_fit is supplied the weights come from the user instead, and no
#' propensity model is available for the sandwich variance.
#' @param df internal data frame.
#' @param ps_formula propensity score formula string.
#' @param S trial participation vector.
#' @param ps_fit optional user-supplied weighting, or NULL for the internal
#'   logistic model.
#' @return list with ps_model, pi_SX, pi_S and w00. ps_model and pi_SX are
#'   NULL when ps_fit is used.
#' @noRd
.ec_weights <- function(df, ps_formula, S, ps_fit = NULL) {
  pi_S <- sum(S) / length(S)

  if (!is.null(ps_fit)) {
    return(list(
      ps_model = NULL,
      pi_SX = NULL,
      pi_S = pi_S,
      w00 = .ec_user_weights(ps_fit, df, S)
    ))
  }

  ps_model <- glm(as.formula(ps_formula), data = df, family = "binomial")
  pi_SX <- predict(ps_model, newdata = df, type = "response")

  list(
    ps_model = ps_model,
    pi_SX = pi_SX,
    pi_S = pi_S,
    w00 = (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S)
  )
}

#' Resolve a user-supplied weighting to a length-N weight vector.
#' a function is called on the current data; a WeightIt or MatchIt object is
#' re-evaluated on it via its stored call, so bootstrap resamples refit rather
#' than reusing weights computed on the full data.
#' @param ps_fit function, weightit object, or matchit object.
#' @param df internal data frame for the current (possibly resampled) data.
#' @param S trial participation vector.
#' @return numeric vector of non-negative weights, length nrow(df).
#' @noRd
.ec_user_weights <- function(ps_fit, df, S) {
  w <- if (is.function(ps_fit)) {
    ps_fit(df)
  } else {
    .ec_refit_weights(ps_fit, df)
  }

  if (!is.numeric(w) || length(w) != nrow(df)) {
    stop(
      "ps_fit must produce one weight per subject (expected ", nrow(df),
      ", got ", length(w), ").",
      call. = FALSE
    )
  }
  if (anyNA(w) || any(!is.finite(w))) {
    stop("ps_fit produced missing or non-finite weights.", call. = FALSE)
  }
  if (any(w < 0)) {
    stop("ps_fit produced negative weights.", call. = FALSE)
  }
  if (sum(w[S == 0]) <= 0) {
    stop(
      "ps_fit gave zero total weight to the external controls.",
      call. = FALSE
    )
  }

  w
}

#' Re-evaluate a WeightIt or MatchIt object's call on new data.
#' @param ps_fit weightit or matchit object.
#' @param df data to refit on.
#' @return numeric vector of weights.
#' @noRd
.ec_refit_weights <- function(ps_fit, df) {
  cl <- ps_fit$call
  if (is.null(cl)) {
    stop(
      "ps_fit object has no stored call to re-evaluate; ",
      "pass a function instead.",
      call. = FALSE
    )
  }
  cl$data <- quote(df)
  refit <- eval(cl, list(df = df), parent.frame())
  refit$weights
}
