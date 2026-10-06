source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
ns <- asNamespace("rdborrow")
d <- SyntheticData
set.seed(11)
# binary covariate: 1 for one external control, one trial control, and 10 treated
d$z <- 0
d$z[which(d$S == 0)[1]] <- 1
d$z[which(d$S == 1 & d$A == 0)[1]] <- 1
d$z[which(d$S == 1 & d$A == 1)[1:10]] <- 1
d$y1 <- d$y1 + 3 * d$z
d$y2 <- d$y2 + 3 * d$z
ps <- "S ~ x5 + z"
of <- c("y1 ~ x5 + z", "y2 ~ x5 + z")
cat("== full-data fits\n")
try_show(ra(ec_aipw(ps, of), d, x = c("x5", "z")))
df <- ns$.build_analysis_df(d, c("y1", "y2"), "A", "S", c("x5", "z"))
grp <- as.integer(interaction(df$S, df$A, drop = TRUE))
n_warn <- 0
B <- 400
taus <- matrix(NA, B, 2)
rankdef <- logical(B)
set.seed(12)
for (b in seq_len(B)) {
  idx <- unlist(lapply(split(seq_len(nrow(df)), grp), \(ii) ii[sample.int(length(ii), replace = TRUE)]))
  w <- FALSE
  taus[b, ] <- withCallingHandlers(
    ns$.ec_aipw_boot_statistic(df, idx, c("y1", "y2"), ps, of, 0.5),
    warning = function(cnd) { w <<- TRUE; invokeRestart("muffleWarning") }
  )
  rankdef[b] <- w
}
cat("EC-AIPW replicates with rank-deficient prediction warnings:", sum(rankdef), "of", B, "\n")
cat("mean tau1 (warned replicates):", mean(taus[rankdef, 1]), " (clean):", mean(taus[!rankdef, 1]), "\n")
cat("sd tau1 (warned):", sd(taus[rankdef, 1]), " (clean):", sd(taus[!rankdef, 1]), "\n")
cat("\n== through run_analysis with bootstrap = 200, count warnings\n")
set.seed(13)
cnt <- 0
r <- withCallingHandlers(ra(ec_aipw(ps, of, weight = 0.5, bootstrap = 200), d, x = c("x5", "z")),
  warning = function(cnd) { cnt <<- cnt + 1; invokeRestart("muffleWarning") })
cat("warnings emitted:", cnt, "\n")
show_res(r)
cat("\n== EC-IPW same data, bootstrap = 200\n")
set.seed(13)
cnt <- 0
r <- withCallingHandlers(ra(ec_ipw(ps, weight = 0.5, bootstrap = 200), d, x = c("x5", "z")),
  warning = function(cnd) { cnt <<- cnt + 1; msgs <<- conditionMessage(cnd); invokeRestart("muffleWarning") })
cat("warnings emitted:", cnt, "\n")
show_res(r)
