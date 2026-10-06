source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
M <- function(r) as.matrix(r$results)
meths <- list(
  ipw_opt = ec_ipw(ps5), ipw_w0 = ec_ipw(ps5, weight = 0), ipw_w03 = ec_ipw(ps5, weight = 0.3),
  ipw_w1 = ec_ipw(ps5, weight = 1),
  aipw_opt = ec_aipw(ps5, of5), aipw_w0 = ec_aipw(ps5, of5, weight = 0), aipw_w1 = ec_aipw(ps5, of5, weight = 1)
)
base <- lapply(meths, \(m) ra(m))
rep_line <- function(name, val) cat(sprintf("%-55s %s\n", name, paste(format(val, digits = 3), collapse = "  ")))

cat("P1 row permutation (5 seeds): max abs diff\n")
for (nm in names(meths)) {
  dd <- sapply(1:5, \(s) { set.seed(s); p <- sample(nrow(SyntheticData)); max(abs(M(ra(meths[[nm]], SyntheticData[p, ])) - M(base[[nm]]))) })
  rep_line(nm, max(dd))
}

cat("\nP3 shift outcomes by +1000 and -7: max abs diff of all result columns\n")
for (cc in c(1000, -7)) for (nm in names(meths)) {
  d <- SyntheticData; d$y1 <- d$y1 + cc; d$y2 <- d$y2 + cc
  r <- ra(meths[[nm]], d)
  rep_line(paste(nm, "shift", cc), max(abs(r$results[, 1:2] - base[[nm]]$results[, 1:2])))
}

cat("\nP4 scale outcomes by c: max rel err of tau/c and SE/|c|\n")
for (cc in c(-2.5, 1e6, 1e-6)) for (nm in names(meths)) {
  d <- SyntheticData; d$y1 <- d$y1 * cc; d$y2 <- d$y2 * cc
  r <- ra(meths[[nm]], d)
  e1 <- max(abs(r$results$point_estimates / cc / base[[nm]]$results$point_estimates - 1))
  e2 <- max(abs(r$results$standard_deviation / abs(cc) / base[[nm]]$results$standard_deviation - 1))
  rep_line(paste(nm, "scale", cc), c(e1, e2))
}
d <- SyntheticData; d$y1 <- -d$y1; d$y2 <- -d$y2
r <- ra(meths$ipw_opt, d)
cat("negated outcomes, lower CI == -upper CI of base:", isTRUE(all.equal(r$results$lower_CI_normal, -base$ipw_opt$results$upper_CI_normal)), "\n")

cat("\nP5 EC-IPW w = 0 ignores external outcomes/covariates/rows\n")
d <- SyntheticData; ext <- d$S == 0
set.seed(9); d$y1[ext] <- rnorm(sum(ext), 100, 50); d$y2[ext] <- rnorm(sum(ext), -100, 50)
d$x5[ext] <- d$x5[ext] * 10
rep_line("ext outcomes+x5 replaced", max(abs(M(ra(meths$ipw_w0, d)) - M(base$ipw_w0))))
rep_line("ext rows removed", max(abs(M(ra(meths$ipw_w0, SyntheticData[!ext, ])) - M(base$ipw_w0))))
cat("   (EC-AIPW w = 0 is NOT expected to be invariant, #92)\n")
d <- SyntheticData
set.seed(9); d$y1[ext] <- rnorm(sum(ext), 100, 50); d$y2[ext] <- rnorm(sum(ext), -100, 50)
rep_line("aipw_w0 ext outcomes replaced (expected to change)", max(abs(M(ra(meths$aipw_w0, d)) - M(base$aipw_w0))))

cat("\nP6 EC-IPW w = 1 ignores trial-control outcomes\n")
d <- SyntheticData; tc <- d$S == 1 & d$A == 0
set.seed(10); d$y1[tc] <- rnorm(sum(tc), 100, 50); d$y2[tc] <- rnorm(sum(tc), 100, 50)
rep_line("trial ctrl outcomes replaced: tau, SE", max(abs(M(ra(meths$ipw_w1, d)) - M(base$ipw_w1))))

cat("\nP8 optimal weight does not depend on outcomes (Eq 11)\n")
d <- SyntheticData; set.seed(11); d$y1 <- rnorm(300); d$y2 <- rexp(300)
rep_line("ipw borrow_weight diff", ra(meths$ipw_opt, d)$borrow_weight - base$ipw_opt$borrow_weight)
rep_line("aipw borrow_weight diff", ra(meths$aipw_opt, d)$borrow_weight - base$aipw_opt$borrow_weight)
rep_line("ipw vs aipw borrow_weight", base$ipw_opt$borrow_weight - base$aipw_opt$borrow_weight)

cat("\nP9 duplicate every row: tau unchanged, SE / sqrt(2)\n")
d2 <- rbind(SyntheticData, SyntheticData)
for (nm in names(meths)) {
  r <- ra(meths[[nm]], d2)
  rep_line(nm, c(max(abs(r$results$point_estimates - base[[nm]]$results$point_estimates)),
    max(abs(r$results$standard_deviation * sqrt(2) / base[[nm]]$results$standard_deviation - 1)),
    r$borrow_weight - base[[nm]]$borrow_weight))
}

cat("\nP10 EC-IPW SE continuous at w -> 0 (branch switch)\n")
for (w in c(1e-8, 1e-4)) {
  r <- ra(ec_ipw(ps5, weight = w))
  rep_line(paste("w =", w, "tau diff, SE rel diff vs w=0"),
    c(max(abs(r$results$point_estimates - base$ipw_w0$results$point_estimates)),
      max(abs(r$results$standard_deviation / base$ipw_w0$results$standard_deviation - 1))))
}

cat("\nP12 tau affine in w: tau(0.5) == (tau(0)+tau(1))/2\n")
for (fam in c("ipw", "aipw")) {
  mk <- if (fam == "ipw") \(w) ec_ipw(ps5, weight = w) else \(w) ec_aipw(ps5, of5, weight = w)
  t0 <- ra(mk(0))$results$point_estimates; t1 <- ra(mk(1))$results$point_estimates
  th <- ra(mk(0.5))$results$point_estimates
  rep_line(fam, max(abs(th - (t0 + t1) / 2)))
}

cat("\nP13 optimal-weight run == fixed-weight run at w_hat\n")
for (fam in c("ipw", "aipw")) {
  ro <- if (fam == "ipw") base$ipw_opt else base$aipw_opt
  rf <- ra(if (fam == "ipw") ec_ipw(ps5, weight = ro$borrow_weight) else ec_aipw(ps5, of5, weight = ro$borrow_weight))
  rep_line(fam, max(abs(M(ro) - M(rf))))
}

cat("\nP15 add delta = 2 to trial-treated outcomes: tau + 2, SE unchanged\n")
d <- SyntheticData; tt <- d$S == 1 & d$A == 1; d$y1[tt] <- d$y1[tt] + 2; d$y2[tt] <- d$y2[tt] + 2
for (nm in names(meths)) {
  r <- ra(meths[[nm]], d)
  rep_line(nm, c(max(abs(r$results$point_estimates - 2 - base[[nm]]$results$point_estimates)),
    max(abs(r$results$standard_deviation - base[[nm]]$results$standard_deviation))))
}

cat("\nP16 EC-IPW: add c = 5 to external outcomes: tau - w*c, SE unchanged\n")
d <- SyntheticData; e <- d$S == 0; d$y1[e] <- d$y1[e] + 5; d$y2[e] <- d$y2[e] + 5
for (nm in c("ipw_opt", "ipw_w03", "ipw_w1")) {
  r <- ra(meths[[nm]], d)
  rep_line(nm, c(max(abs(r$results$point_estimates + r$borrow_weight * 5 - base[[nm]]$results$point_estimates)),
    max(abs(r$results$standard_deviation - base[[nm]]$results$standard_deviation))))
}

cat("\nP17 affine rescale of covariate x5 -> 1000*x5 + 50 and x4 -> x4/1e4\n")
d <- SyntheticData; d$x5 <- 1000 * d$x5 + 50; d$x4 <- d$x4 / 1e4
for (nm in names(meths)) rep_line(nm, max(abs(M(ra(meths[[nm]], d)) - M(base[[nm]]))))

cat("\nInteger outcomes equal double outcomes\n")
d <- SyntheticData; d$y1 <- as.integer(round(d$y1)); d$y2 <- as.integer(round(d$y2))
dd <- d; dd$y1 <- as.numeric(dd$y1); dd$y2 <- as.numeric(dd$y2)
for (nm in c("ipw_opt", "aipw_opt", "ipw_w0")) rep_line(nm, max(abs(M(ra(meths[[nm]], d)) - M(ra(meths[[nm]], dd)))))
