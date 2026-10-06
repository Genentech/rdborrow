# outcome formula order, length, and left-hand sides for did_ec_aipw() and did_ec_or()
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
d <- SyntheticData
y <- c("y1", "y2", "y3", "y4")
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
pt <- function(m, ...) {
  r <- show(suppressWarnings(ole(m, ...)))
  if (!is.null(r)) r$point_estimates
}
fy <- f5(y)

cat("\n## eq 5 by hand (aipw, mu fit on external controls only)\n")
S <- d$S; A <- d$A
pis <- fitted(glm(as.formula(ps), data = d, family = binomial))
w0 <- pis / (1 - pis)
pa <- mean(A[S == 1])
mu <- sapply(1:4, function(t) predict(lm(as.formula(fy[t]), data = d[S == 0, ]), newdata = d))
yt <- as.matrix(d[, y]) - mu
yt1 <- rowMeans(yt[, 1:2])
hand <- sapply(3:4, function(t) {
  r <- S == 1; e <- S == 0
  (sum((A * yt[, t])[r]) / sum(A[r]) - sum(((1 - A) * yt1)[r]) / sum((1 - A)[r])) -
    sum((w0 * (yt[, t] - yt1))[e]) / sum(w0[e])
})
cat("hand:    ", hand, "\n")
cat("package: ", pt(did_ec_aipw(ps, outcome_formula = fy, bootstrap = 2)), "\n")

cat("\n## did_ec_aipw: formula order\n")
cat("y1..y4 order:     ", pt(did_ec_aipw(ps, outcome_formula = fy, bootstrap = 2)), "\n")
cat("y4,y3,y2,y1 order:", pt(did_ec_aipw(ps, outcome_formula = rev(fy), bootstrap = 2)), "\n")
cat("y2,y1,y4,y3 order:", pt(did_ec_aipw(ps, outcome_formula = fy[c(2, 1, 4, 3)], bootstrap = 2)), "\n")
cat("\n## did_ec_aipw: formula lengths\n")
for (k in c(1, 2, 3, 5)) {
  ff <- rep(fy, 2)[seq_len(k)]
  cat("length", k, ": ")
  print(pt(did_ec_aipw(ps, outcome_formula = ff, bootstrap = 2)))
}
cat("\n## did_ec_aipw: LHS not an outcome\n")
print(pt(did_ec_aipw(ps, outcome_formula = c(fy[1:3], "x1 ~ x2 + x3"), bootstrap = 2)))

cat("\n## did_ec_or: order of each formula vector\n")
cat("baseline:        ", pt(did_ec_or(fy, fy, fy, bootstrap = 2)), "\n")
cat("ext reversed:    ", pt(did_ec_or(rev(fy), fy, fy, bootstrap = 2)), "\n")
cat("rct_ctrl reversed:", pt(did_ec_or(fy, rev(fy), fy, bootstrap = 2)), "\n")
cat("rct_trt reversed:", pt(did_ec_or(fy, fy, rev(fy), bootstrap = 2)), "\n")
cat("\n## did_ec_or: lengths\n")
cat("rct_trt only post visits (y3, y4):\n")
print(pt(did_ec_or(fy, fy, fy[3:4], bootstrap = 2)))
cat("rct_ctrl only pre visits (y1, y2):\n")
print(pt(did_ec_or(fy, fy[1:2], fy, bootstrap = 2)))
cat("ext of length 3:\n")
print(pt(did_ec_or(fy[1:3], fy, fy, bootstrap = 2)))
cat("all of length 5:\n")
print(pt(did_ec_or(c(fy, fy[1]), c(fy, fy[1]), c(fy, fy[1]), bootstrap = 2)))
cat("all of length 1:\n")
print(pt(did_ec_or(fy[1], fy[1], fy[1], bootstrap = 2)))
cat("\n## did_ec_or: formulas used only where the paper needs them?\n")
cat("rct_trt formulas for y1, y2 replaced by nonsense LHS x1:\n")
print(pt(did_ec_or(fy, fy, c("x1 ~ x2", "x1 ~ x2", fy[3:4]), bootstrap = 2)))
cat("rct_ctrl formulas for y3, y4 replaced by nonsense LHS x1:\n")
print(pt(did_ec_or(fy, c(fy[1:2], "x1 ~ x2", "x1 ~ x2"), fy, bootstrap = 2)))
