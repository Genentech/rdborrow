# factor treatment with the treated level first, under stratified randomization.
# glm(binomial) models P(second level), so trt_formula fits P(A = 0 | X)
# while the code uses it as P(A = 1 | X). seed 21.
# expected: same estimate as numeric A (the 0/1 check in setup accepts both).
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
set.seed(21)
n <- 300
m <- 200
N <- n + m
S <- c(rep(1, n), rep(0, m))
x2 <- rbinom(N, 1, 0.5)
x1 <- rnorm(N)
x3 <- rnorm(N)
pA <- ifelse(x2 == 1, 0.9, 0.3)
A <- c(rbinom(n, 1, pA[1:n]), rep(0, m))
Y <- sapply(1:4, \(t) {
  0.3 * t + x1 + 4 * x2 + 0.5 * S +
    ifelse(A == 1, 0.5 * t * (1 + 2 * x2), 0) + rnorm(N, sd = 0.5)
})
colnames(Y) <- ycols()
d <- data.frame(x1, x2, x3, A, S, Y)
cat("true tau_t = E_R[0.5 t (1 + 2 x2)] =", 0.5 * 3:4 * (1 + 2 * mean(x2[S == 1])), "\n")

m <- did_ec_ipw("S ~ x1 + x2 + x3", trt_formula = "A ~ x2", bootstrap = 50)
cat("numeric A\n")
show_try(fit(d, m))
dA <- d
dA$A <- factor(dA$A, levels = c(1, 0), labels = c("1", "0"))
cat("factor A, levels c('1', '0')\n")
show_try(fit(dA, m))

ma <- did_ec_aipw("S ~ x1 + x2 + x3",
  trt_formula = "A ~ x2",
  outcome_formula = forms(), bootstrap = 50
)
cat("did_ec_aipw, numeric A\n")
show_try(fit(d, ma))
cat("did_ec_aipw, factor A, levels c('1', '0')\n")
show_try(fit(dA, ma))
cat("did_ec_ipw, character A\n")
dC <- d
dC$A <- as.character(dC$A)
show_try(fit(dC, m))
