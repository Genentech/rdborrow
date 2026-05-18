#' Using IPW with external borrowing
#'
#' @param data A data frame containing all subject-level data.
#' @param indices Bootstrap sample indices.
#' @param outcome_col_name Character vector of outcome column names.
#' @param trial_status_col_name Name of the trial status column.
#' @param treatment_col_name Name of the treatment column.
#' @param covariates_col_name Character vector of covariate column names.
#' @param model_form_piS Formula string for the trial participation model.
#' @param optimal_weight_flag Logical. Whether to use the optimal borrowing weight.
#' @param wt Numeric fixed borrowing weight.
#'
#' @return a list containing: tau (effect size), sd.tau (standard deviation), wt (weight)
#' @noRd
#'
#' @examples
#' \dontrun{
#' EC_IPW_OPT(
#'   outcome = outcome,
#'   trial_status = trial_status,
#'   treatment = treatment,
#'   covariates = covariates,
#'   model_form_piS = model_form_piS,
#'   wt = wt,
#'   optimal_weight_flag = optimal_weight_flag,
#'   Bootstrap
#' )
#' }
EC_IPW_OPT_bootstrap <- function(data,
                                 indices,
                                 outcome_col_name,
                                 trial_status_col_name,
                                 treatment_col_name,
                                 covariates_col_name,
                                 model_form_piS = "",
                                 optimal_weight_flag = FALSE,
                                 wt = 0) {
  Y <- subset(data[indices, ], select = outcome_col_name)
  S <- subset(data[indices, ], select = trial_status_col_name)
  A <- subset(data[indices, ], select = treatment_col_name)
  X <- subset(data[indices, ], select = covariates_col_name)
  names(S) <- "S"
  names(A) <- "A"
  model_form_piS <- unlist(strsplit(model_form_piS, "~"))
  model_form_piS[1] <- "S"
  model_form_piS <- paste0(model_form_piS, collapse = "~")

  df <- data.frame(Y, S = S, A = A, X)
  N <- nrow(df)
  T_follow <- ncol(Y)
  n <- sum(df$S) # RCT sample size
  m <- sum(1 - df$S) # external control sample size
  pi.S <- n / N

  ## TODO: write running messages
  # cat("running IPW... \n")

  if ((!optimal_weight_flag) && wt == 0) {
    # estimate ATE
    ## TODO: why do use the true propensity score?
    temp <- df |>
      dplyr::filter(S == 1) |>
      dplyr::mutate(piA = sum(A) / n) |>
      dplyr::mutate(w11 = piA, w10 = 1 - piA)

    ### create outcomes: obs by T
    Ys <- as.matrix(Y[S == 1, ])

    potential <- (temp$A / temp$w11 + (1 - temp$A) / temp$w10) * Ys
    mu1 <- colSums(potential[temp$A == 1, , drop = FALSE]) / n
    mu0 <- colSums(potential[temp$A == 0, , drop = FALSE]) / n

    # print(c(mu1, mu0))
    tau <- mu1 - mu0
  } else {
    # propensity score model

    # TODO: generalize the following line to other possible models
    # piS.model = glm(as.formula(paste("S", "~", form_x)) , data = df, family = "binomial")
    piS.model <- glm(as.formula(model_form_piS), data = df, family = "binomial")

    # estimate ATE
    temp <- df |>
      dplyr::mutate(
        piA = sum(A[S == 1]) / n,
        piS = sum(S) / (n + m),
        piSX = predict(piS.model, newdata = df, type = "response"),
        rx = (piSX / (1 - piSX)) * ((1 - piS) / piS)
      ) |>
      dplyr::mutate(w11 = piA, w10 = 1 - piA, w00 = rx)

    ### create outcomes: obs * T
    Ys <- as.matrix(Y)

    potential <- (temp$S * temp$A / temp$w11 + temp$S * (1 - temp$A) / temp$w10 + (1 - temp$S) * temp$w00) * Ys
    mu1 <- colSums(potential[temp$S == 1 & temp$A == 1, , drop = FALSE]) / sum(temp$S * temp$A / temp$w11)
    mu10 <- colSums(potential[temp$S == 1 & temp$A == 0, , drop = FALSE]) / sum(temp$S * (1 - temp$A) / temp$w10)
    mu00 <- colSums(potential[temp$S == 0, , drop = FALSE]) / (sum((1 - temp$S) * temp$w00))


    ## Optimal weight as proposed in manuscript
    # fit1 = lm(as.formula(paste("Y2","~",form_x)), data = filter(temp,S==1&A==0) )
    # sigma10 = (summary(fit1)$sigma)**2
    num <- sum(temp$S * (1 - temp$A) / temp$w10^2 / (sum(temp$S * (1 - temp$A) / temp$w10))^2)
    #+ sum(temp$S*(1-temp$A))*var(temp$S*(1-temp$A)*     # nolint: line_length_linter.
    #+ predict(fit1,newdata =temp)/temp$w10/sum(temp$S*(1-temp$A)/temp$w10))

    # fit0 = lm(as.formula(paste("Y2","~",form_x)), data = filter(temp,S==0) )
    # sigma00 = (summary(fit0)$sigma)**2
    denom <- sum((1 - temp$S) * temp$w00^2 / (sum((1 - temp$S) * temp$w00))^2)
    #+ sum((1-temp$S))*var((1-temp$S)*predict(fit0,newdata =temp)*temp$w00/sum((1-temp$S)*temp$w00))
    w.opt <- num / (num + denom)
    # only use the optimal weight if we want
    if (optimal_weight_flag == TRUE) {
      wt <- w.opt
    }

    # final hybrid estimate as combination of RCT control and external control
    mu0 <- (1 - wt) * mu10 + wt * mu00
    tau <- mu1 - mu0

    names(tau) <- paste0("tau", 1:T_follow)
  }

  tau
}
