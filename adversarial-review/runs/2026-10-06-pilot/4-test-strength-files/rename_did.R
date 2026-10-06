devtools::load_all("/home/matts/Documents/rdborrow/.claude/worktrees/agent-abfdf543787540182/mutator-run/pkgcopy", quiet = TRUE)
d <- SyntheticData
names(d)[names(d) == "S"] <- "trial"
m <- did_ec_ipw(ps_formula = "trial ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2)
an <- setup_analysis_OLE(
  data = d, trial_status_col_name = "trial", treatment_col_name = "A",
  outcome_col_name = c("y1", "y2", "y3", "y4"), covariates_col_name = paste0("x", 1:5),
  method_OLE_obj = m, T_cross = 2
)
r <- try(suppressWarnings(run_analysis(an)))
cat("did_ec_ipw with trial_status 'trial':", if (inherits(r, "try-error")) conditionMessage(attr(r, "condition")) else "ok", "\n")
