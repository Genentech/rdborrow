# compare point estimates with direct transcriptions of Zhou et al. (2024)
# Eq. 3-5 / Appendix B, written from the paper only
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
d <- SyntheticData
y <- c("y1", "y2", "y3", "y4")
T1 <- 1:2
T2 <- 3:4
S <- d$S
A <- d$A
X <- d[, paste0("x", 1:5)]
ybar1 <- rowMeans(d[, y[T1]])
pt <- function(m) suppressWarnings(ole(m)$point_estimates)

# eq 4: did-ec-ipw, marginal pi_A
hand_ipw <- function(ps_form, trt_form = NULL) {
  pis <- fitted(glm(as.formula(ps_form), data = d, family = binomial))
  w0 <- pis / (1 - pis)
  if (is.null(trt_form)) {
    pa <- rep(mean(A[S == 1]), nrow(d))
  } else {
    pa <- predict(glm(as.formula(trt_form), data = d[S == 1, ], family = binomial),
                  newdata = d, type = "response")
  }
  w11 <- 1 / pa
  w10 <- 1 / (1 - pa)
  r <- S == 1
  e <- S == 0
  sapply(T2, function(t) {
    yt <- d[[y[t]]]
    dtrial <- sum((A * w11 * yt)[r]) / sum((A * w11)[r]) -
      sum(((1 - A) * w10 * ybar1)[r]) / sum(((1 - A) * w10)[r])
    dec <- sum((w0 * (yt - ybar1))[e]) / sum(w0[e])
    dtrial - dec
  })
}

# eq 3: did-ec-or
hand_or <- function(rhs) {
  r <- S == 1
  fit <- function(t, rows) {
    predict(lm(as.formula(paste(y[t], rhs)), data = d[rows, ]), newdata = d[r, ])
  }
  mu10 <- rowMeans(sapply(T1, fit, rows = r & A == 0))
  mu0_1 <- rowMeans(sapply(T1, fit, rows = S == 0))
  sapply(T2, function(t) {
    mean(fit(t, r & A == 1) - mu10 - (fit(t, S == 0) - mu0_1))
  })
}

cat("\n## unadjusted DID by hand\n")
r <- S == 1
unadj <- sapply(T2, function(t) {
  (mean(d[[y[t]]][r & A == 1]) - mean(ybar1[r & A == 0])) -
    (mean(d[[y[t]]][S == 0]) - mean(ybar1[S == 0]))
})
print(unadj)
cat("did_ec_ipw(S ~ 1):          ", pt(did_ec_ipw("S ~ 1", bootstrap = 2)), "\n")
cat("did_ec_or(all ~ 1):         ", pt(did_ec_or(paste(y, "~ 1"), paste(y, "~ 1"), paste(y, "~ 1"), bootstrap = 2)), "\n")
cat("did_ec_aipw(S ~ 1, y ~ 1):  ", pt(did_ec_aipw("S ~ 1", outcome_formula = paste(y, "~ 1"), bootstrap = 2)), "\n")

cat("\n## did_ec_ipw with covariates, marginal pi_A\n")
ps <- "S ~ x1 + x2 + x3 + x4 + x5"
cat("hand eq 4: ", hand_ipw(ps), "\n")
cat("package:   ", pt(did_ec_ipw(ps, bootstrap = 2)), "\n")
cat("\n## did_ec_ipw with trt_formula (W11 = 1/pi_A(X))\n")
tf <- "A ~ x1 + x2 + x3 + x4 + x5"
cat("hand eq 4: ", hand_ipw(ps, tf), "\n")
cat("package:   ", pt(did_ec_ipw(ps, trt_formula = tf, bootstrap = 2)), "\n")

cat("\n## did_ec_aipw with intercept-only outcome models equals did_ec_ipw (eq 5 -> eq 4)\n")
cat("aipw: ", pt(did_ec_aipw(ps, outcome_formula = paste(y, "~ 1"), bootstrap = 2)), "\n")
cat("ipw:  ", pt(did_ec_ipw(ps, bootstrap = 2)), "\n")

cat("\n## did_ec_or with covariates (eq 3, average over trial population R)\n")
cat("hand eq 3: ", hand_or("~ x1 + x2 + x3 + x4 + x5"), "\n")
cat("package:   ", pt(did_ec_or(f5(y), f5(y), f5(y), bootstrap = 2)), "\n")
