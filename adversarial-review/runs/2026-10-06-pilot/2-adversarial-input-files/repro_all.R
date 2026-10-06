source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
pe <- function(r) if (is.null(r)) "NULL" else paste(format(r$results$point_estimates, digits = 6), collapse = ", ")
q <- function(expr) tryCatch(suppressWarnings(expr), error = function(e) structure(list(msg = conditionMessage(e)), class = "err"))
out <- function(label, r) {
  if (inherits(r, "err")) cat(sprintf("%-60s ERROR: %s\n", label, r$msg))
  else cat(sprintf("%-60s tau = %s | se = %s | w = %.4f\n", label, pe(r),
    paste(format(r$results$standard_deviation, digits = 4), collapse = ", "), r$borrow_weight))
}
cat("F1 outcome_formula paired by position\n")
out("  aipw y=(y1,y2), f=(y1,y2)", q(ra(ec_aipw(ps5, of5))))
out("  aipw y=(y2,y1), f=(y1,y2)", q(ra(ec_aipw(ps5, of5), y = c("y2", "y1"))))
out("  aipw y=(y2,y1), f=(y2,y1)", q(ra(ec_aipw(ps5, rev(of5)), y = c("y2", "y1"))))

cat("F2 external controls with A = 1 accepted\n")
d <- SyntheticData; ext <- which(d$S == 0)
d$A[ext[1:10]] <- 1; d$y1[ext[1:10]] <- d$y1[ext[1:10]] + 50
out("  ipw w=1, 10 externals A=1 (y1 + 50)", q(ra(ec_ipw(ps5, weight = 1), d)))
out("  ipw w=1, those 10 rows dropped", q(ra(ec_ipw(ps5, weight = 1), d[-ext[1:10], ])))

cat("F3 trial status column not named S\n")
d <- SyntheticData; names(d)[names(d) == "S"] <- "trial"
out("  ipw S col 'trial'", q(ra(ec_ipw(ps5), d, S = "trial")))
out("  aipw S col 'trial'", q(ra(ec_aipw(ps5, of5), d, S = "trial")))
set.seed(2); d_shuf <- d[sample(nrow(d)), ]
trial <- d$trial
out("  ipw S col 'trial' + global `trial` (other row order)", q(ra(ec_ipw(ps5), d_shuf, S = "trial")))
rm(trial)

cat("F4 covariate named like an internal column\n")
set.seed(21)
d <- SyntheticData; names(d)[names(d) == "A"] <- "trt"; d$A <- rnorm(nrow(d), 50, 10)
out("  ipw covariate named 'A', treatment 'trt'", q(ra(ec_ipw("S ~ x1 + A"), d, A = "trt", x = c("x1", "A"))))
d2 <- d; names(d2)[names(d2) == "A"] <- "age"
out("  ipw same covariate named 'age'", q(ra(ec_ipw("S ~ x1 + age"), d2, A = "trt", x = c("x1", "age"))))

cat("F5 'S ~ .' expands over outcomes and treatment\n")
out("  ipw 'S ~ .'", q(ra(ec_ipw("S ~ ."))))
out("  ipw 'S ~ x1 + ... + x5'", q(ra(ec_ipw(ps5))))

cat("F6 missing values\n")
d <- SyntheticData; d$y1[which(d$S == 1 & d$A == 0)[1]] <- NA
out("  ipw NA in one trial-control y1", q(ra(ec_ipw(ps5), d)))
set.seed(1)
r <- q(ra(ec_ipw(ps5, bootstrap = 50), d))
cat("  ipw + bootstrap: tau1 =", r$results$point_estimates[1], " sd1 =", r$results$standard_deviation[1],
  " CI1 = [", r$results$lower_CI_boot[1], ",", r$results$upper_CI_boot[1], "]\n")
out("  aipw NA in one trial-control y1", q(ra(ec_aipw(ps5, of5), d)))
d <- SyntheticData; d$x5[which(d$S == 0)[1]] <- NA
out("  ipw NA in one external x5", q(ra(ec_ipw(ps5), d)))
out("  ipw w=0.5 NA in one external x5", q(ra(ec_ipw(ps5, weight = 0.5), d)))

cat("F7 empty arms give NaN without error\n")
out("  aipw, no external controls", q(ra(ec_aipw(ps5, of5), SyntheticData[SyntheticData$S == 1, ])))
out("  ipw, no trial treated", q(ra(ec_ipw(ps5), SyntheticData[!(SyntheticData$S == 1 & SyntheticData$A == 1), ])))
out("  ipw w=1, no trial controls", q(ra(ec_ipw(ps5, weight = 1), SyntheticData[!(SyntheticData$S == 1 & SyntheticData$A == 0), ])))

cat("F8 aliased / collinear covariates: point estimate fine, sandwich errors\n")
d <- SyntheticData; d$x6 <- 2 * d$x5
out("  ipw S ~ x5 + x6 (x6 = 2*x5)", q(ra(ec_ipw("S ~ x5 + x6"), d, x = c("x5", "x6"))))
out("  ipw S ~ x5", q(ra(ec_ipw("S ~ x5"), d, x = c("x5", "x6"))))
ns <- asNamespace("rdborrow")
df <- ns$.build_analysis_df(d, c("y1", "y2"), "A", "S", c("x5", "x6"))
cat("  core tau with aliased x6:", ns$.ec_ipw_core(df, as.matrix(df[, 1:2]), df$S, df$A, "S ~ x5 + x6", NULL)$tau, "\n")

cat("F9 EC-AIPW sandwich fails for large-magnitude covariate\n")
d <- SyntheticData; d$x5 <- d$x5 * 1e5
out("  aipw x5 * 1e5", q(ra(ec_aipw(ps5, of5), d)))
out("  ipw  x5 * 1e5", q(ra(ec_ipw(ps5), d)))
out("  aipw x5 * 1 (reference)", q(ra(ec_aipw(ps5, of5))))
