devtools::load_all("/home/matts/Documents/rdborrow/.claude/worktrees/agent-abfdf543787540182", quiet = TRUE)
d <- SyntheticData
names(d)[names(d) == "S"] <- "trial"
names(d)[names(d) == "A"] <- "trt"
m <- ec_ipw(ps_formula = "trial ~ x1 + x2 + x3 + x4 + x5")
an <- setup_analysis_primary(
  data = d, trial_status_col_name = "trial", treatment_col_name = "trt",
  outcome_col_name = c("y1", "y2"), covariates_col_name = paste0("x", 1:5),
  method_weighting_obj = m
)
print(try(run_analysis(an)))
m2 <- ec_aipw(
  ps_formula = "trial ~ x1 + x2 + x3 + x4 + x5",
  outcome_formula = c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
)
an2 <- setup_analysis_primary(
  data = d, trial_status_col_name = "trial", treatment_col_name = "trt",
  outcome_col_name = c("y1", "y2"), covariates_col_name = paste0("x", 1:5),
  method_weighting_obj = m2
)
print(try(run_analysis(an2)))
