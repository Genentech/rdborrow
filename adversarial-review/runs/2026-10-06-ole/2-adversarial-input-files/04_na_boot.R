# mechanism: NA point estimate, finite CI from the replicates that drop the incomplete row
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)
dm <- d
dm$x1[which(dm$S == 0)[1]] <- NA
df <- ns$.build_analysis_df(dm, ycols(), "A", "S", c("x1", "x2", "x3"))
set.seed(2024)
b <- boot::boot(df, function(data, i) {
  ns$.did_ec_ipw_boot_statistic(data, i, ycols(), "S ~ x1 + x2 + x3", NULL, 2)
}, R = 200, strata = as.integer(interaction(df$S, df$A, drop = TRUE)))
cat("t0:", b$t0, "\n")
cat("finite replicates:", sum(is.finite(b$t[, 1])), "of", nrow(b$t), "\n")
ci <- boot::boot.ci(b, type = "perc", index = 1)
print(ci$percent)
cat("complete-case point estimate for comparison:\n")
print(pe(dm[complete.cases(dm), ], "ipw"))
cat("\nrun_analysis with B = 200:\n")
print(suppressWarnings(fit(dm, m_ipw(200))))
cat("\nDID-EC-OR silently changes with the NA (no warning):\n")
print(withCallingHandlers(pe(dm, "or"), warning = function(w) cat("WARN", conditionMessage(w), "\n")))
print(pe(d, "or"))
