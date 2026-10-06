source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
ns <- asNamespace("rdborrow")
set.seed(21)
d <- SyntheticData
names(d)[names(d) == "A"] <- "trt"
d$A <- rnorm(nrow(d), 50, 10)
cat("== treatment column 'trt'; a covariate literally named 'A' (e.g. age)\n")
df <- ns$.build_analysis_df(d, c("y1", "y2"), "trt", "S", c("x1", "A"))
cat("internal df names:", names(df), "\n")
cat("cor(df$A, treatment) =", cor(df$A, d$trt), "; cor(df$A.1, covariate A) =", cor(df$A.1, d$A), "\n")
r_coll <- try_show(ra(ec_ipw("S ~ x1 + A"), d, A = "trt", x = c("x1", "A")))
cat("-- reference: same covariate renamed to 'age'\n")
d2 <- d; names(d2)[names(d2) == "A"] <- "age"
r_ref <- try_show(ra(ec_ipw("S ~ x1 + age"), d2, A = "trt", x = c("x1", "age")))
cat("-- ec_aipw with covariate A in outcome model\n")
try_show(ra(ec_aipw("S ~ x1", c("y1 ~ x1 + A", "y2 ~ x1 + A")), d, A = "trt", x = c("x1", "A")))
try_show(ra(ec_aipw("S ~ x1", c("y1 ~ x1 + age", "y2 ~ x1 + age")), d2, A = "trt", x = c("x1", "age")))

cat("\n== outcome column named 'A' (treatment column 'trt')\n")
d3 <- SyntheticData; names(d3)[names(d3) == "A"] <- "trt"; d3$A <- d3$y1
try_show(ra(ec_ipw("S ~ x1 + x5"), d3, A = "trt", y = c("A", "y2"), x = c("x1", "x5")))
try_show(ra(ec_ipw("S ~ x1 + x5"), d3, A = "trt", y = c("y1", "y2"), x = c("x1", "x5")))

cat("\n== outcome column named 'S' with weight = 0 (no PS model)\n")
d4 <- SyntheticData; names(d4)[names(d4) == "A"] <- "trt"; d4$S2 <- d4$S; d4$S <- d4$y1
try_show(ra(ec_ipw("S2 ~ x1", weight = 0), d4, S = "S2", A = "trt", y = c("S", "y2"), x = "x1"))

cat("\n== non-syntactic outcome name\n")
d5 <- SyntheticData; names(d5)[names(d5) == "y1"] <- "week 1"
try_show(ra(ec_ipw(ps5), d5, y = c("week 1", "y2")))
cat("\n== non-syntactic covariate name with backticks\n")
d6 <- SyntheticData; names(d6)[names(d6) == "x5"] <- "age (y)"
try_show(ra(ec_ipw("S ~ x1 + `age (y)`"), d6, x = c("x1", "age (y)")))
