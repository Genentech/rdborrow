source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
set.seed(101)
method <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  weight = NULL,
  bootstrap = 500,
  bootstrap_ci_type = NULL
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

w(print(run_analysis(analysis)))
cat("## adding-a-method article: ec_ipw weight = 0.5 swap\n")
analysis@method_obj <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5", weight = 0.5)
w(print(run_analysis(analysis)))
