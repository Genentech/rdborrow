source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
d <- SyntheticData
ext <- d$S == 0
tc <- d$S == 1 & d$A == 0
tt <- d$S == 1 & d$A == 1
res <- function(m, data = d, ...) run_analysis(mk(m, data = data, ...))
cat("## EC-IPW w = 0 vs hand difference in means and Welch-type SE (MLE variances)\n")
r0 <- res(ec_ipw(F5, weight = 0))$results
for (y in c("y1", "y2")) {
  dm <- mean(d[[y]][tt]) - mean(d[[y]][tc])
  v <- function(x) mean((x - mean(x))^2)
  se <- sqrt(v(d[[y]][tt]) / sum(tt) + v(d[[y]][tc]) / sum(tc))
  cat(y, ": hand tau", dm, " hand se", se, "\n")
}
print(r0)
cat("\n## w = 0 invariance to external data\n")
d2 <- d
d2$y1[ext] <- d2$y1[ext] + 100
d2$x4[ext] <- d2$x4[ext] * 3
print(res(ec_ipw(F5, weight = 0), data = d2)$results)
d3 <- d[!ext | seq_len(nrow(d)) %% 2 == 0, ]
print(res(ec_ipw(F5, weight = 0), data = d3)$results)
cat("\n## w = 1 invariance to trial-control outcomes\n")
d4 <- d
d4$y1[tc] <- d4$y1[tc] + 100
print(res(ec_ipw(F5, weight = 1))$results)
print(res(ec_ipw(F5, weight = 1), data = d4)$results)
print(res(ec_aipw(F5, O5, weight = 1))$results)
print(res(ec_aipw(F5, O5, weight = 1), data = d4)$results)
cat("\n## optimal weight vs external outcome shift (prior-data conflict)\n")
for (shift in c(0, 5, 50)) {
  d5 <- d
  d5$y1[ext] <- d5$y1[ext] + shift
  d5$y2[ext] <- d5$y2[ext] + shift
  r <- res(ec_ipw(F5), data = d5)
  ra <- res(ec_aipw(F5, O5), data = d5)
  cat("shift", shift, ": IPW bw", r$borrow_weight, "tau", round(r$results$point_estimates, 3),
      "| AIPW bw", ra$borrow_weight, "tau", round(ra$results$point_estimates, 3), "\n")
}
cat("\n## fixed weight = optimal weight: same results?\n")
r_opt <- res(ec_ipw(F5))
r_fix <- res(ec_ipw(F5, weight = r_opt$borrow_weight))
print(all.equal(r_opt, r_fix))
set.seed(5); b_opt <- res(ec_ipw(F5, bootstrap = 200))
set.seed(5); b_fix <- res(ec_ipw(F5, weight = r_opt$borrow_weight, bootstrap = 200))
print(b_opt$results); print(b_fix$results)
set.seed(5); ba_opt <- res(ec_aipw(F5, O5, bootstrap = 200))
set.seed(5); ba_fix <- res(ec_aipw(F5, O5, weight = r_opt$borrow_weight, bootstrap = 200))
print(ba_opt$results); print(ba_fix$results)
