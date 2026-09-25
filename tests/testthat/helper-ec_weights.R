att_weights <- function(d) {
  model <- glm(S ~ x1 + x2 + x3 + x4 + x5, data = d, family = "binomial")
  p <- predict(model, newdata = d, type = "response")
  p / (1 - p)
}

ec_covs <- c("x1", "x2", "x3", "x4", "x5")
ec_ps <- "S ~ x1 + x2 + x3 + x4 + x5"

ec_primary <- function(method, outcomes = c("y1", "y2")) {
  setup_analysis_primary(
    data = SyntheticData,
    trial_status_col_name = "S",
    treatment_col_name = "A",
    outcome_col_name = outcomes,
    covariates_col_name = ec_covs,
    method_weighting_obj = method
  )
}
