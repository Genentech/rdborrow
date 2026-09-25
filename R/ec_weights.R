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

#' Re-run a WeightIt or MatchIt object's call against new data.
#' the object's class determines which function produced it, so the call head
#' is rewritten to the namespaced function rather than resolved from wherever
#' the user happened to build the object. remaining arguments are evaluated
#' against the global environment.
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

  cl[[1]] <- if (inherits(ps_fit, "weightit")) {
    quote(WeightIt::weightit)
  } else {
    quote(MatchIt::matchit)
  }
  cl$data <- quote(df)

  refit <- tryCatch(
    eval(cl, list2env(list(df = df), parent = globalenv())),
    error = function(e) {
      stop(
        "Could not re-run the ps_fit object's call on a bootstrap resample: ",
        conditionMessage(e), "\n",
        "This happens when the stored call refers to variables that are not ",
        "in the global environment. Pass a function of the data instead, for ",
        "example ps_fit = \\(d) WeightIt::weightit(S ~ x, d)$weights",
        call. = FALSE
      )
    }
  )
  if (is.null(refit$weights)) {
    stop("Re-running the ps_fit object produced no weights.", call. = FALSE)
  }
  refit$weights
}

#' Validate the propensity-model arguments shared by ec_ipw and ec_aipw.
#' exactly one of ps_formula and ps_fit must be given; user-supplied weights
#' have no propensity model, so the sandwich variance is unavailable and
#' bootstrap inference is required.
#' @param ps_formula propensity score formula string, or NULL.
#' @param ps_fit user-supplied weighting, or NULL.
#' @param bootstrap number of bootstrap replicates, or NULL.
#' @return invisible NULL, called for its side effect of erroring.
#' @noRd
.check_ps_args <- function(ps_formula, ps_fit, bootstrap) {
  if (is.null(ps_formula) && is.null(ps_fit)) {
    stop("Supply either ps_formula or ps_fit.", call. = FALSE)
  }
  if (!is.null(ps_formula) && !is.null(ps_fit)) {
    stop(
      "Supply either ps_formula or ps_fit, not both.",
      call. = FALSE
    )
  }
  if (!is.null(ps_fit)) {
    if (!is.function(ps_fit) && !inherits(ps_fit, c("weightit", "matchit"))) {
      stop(
        "ps_fit must be a function of the data, or a WeightIt or MatchIt ",
        "object.",
        call. = FALSE
      )
    }
    if (is.null(bootstrap)) {
      stop(
        "ps_fit requires bootstrap inference. The sandwich variance needs ",
        "the propensity model score, which user-supplied weights do not ",
        "provide. Set bootstrap to a number of replicates.",
        call. = FALSE
      )
    }
  }
  invisible(NULL)
}
