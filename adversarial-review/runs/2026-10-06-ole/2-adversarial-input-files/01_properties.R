# properties of the DID point estimates (no bootstrap). seed 1 for the data.
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")

d <- make_ole(seed = 1)
yc <- ycols()
pre <- yc[1:2]
post <- yc[3:4]
methods <- c("ipw", "aipw", "or")
base <- sapply(methods, \(w) pe(d, w))
cat("base estimates (true tau3 = 1.5, tau4 = 2)\n")
print(round(base, 4))

check <- function(label, d2, expected = base, tol = 1e-8) {
  got <- sapply(methods, \(w) pe(d2, w))
  dev <- max(abs(got - expected))
  cat(sprintf("%-55s max|dev| = %.3g  %s\n", label, dev,
              if (dev < tol) "HOLDS" else "FAILS"))
  invisible(got)
}

# P1 row permutation
set.seed(11)
check("P1 permute rows", d[sample(nrow(d)), ])

# P2 add constant to all outcomes, all visits, all subjects
d2 <- d; d2[yc] <- d2[yc] + 100
check("P2 +100 to every outcome", d2)

# P3 scale all outcomes by k scales tau by k
d2 <- d; d2[yc] <- d2[yc] * 3
check("P3 outcomes * 3 -> tau * 3", d2, expected = 3 * base)

# P4 constant shift to external controls at every visit
d2 <- d; d2[d2$S == 0, yc] <- d2[d2$S == 0, yc] + 7
check("P4 EC outcomes + 7 at every visit", d2)

# P5 time-varying shift to ECs in period II only: tau_t moves by -delta_t
d2 <- d; d2[d2$S == 0, post] <- sweep(as.matrix(d2[d2$S == 0, post]), 2, c(1, 3), "+")
check("P5 EC period II + (1, 3) -> tau - (1, 3)", d2,
      expected = base - matrix(c(1, 3), 2, 3))

# P6 shift trial-control period I by c: tau moves by -c
d2 <- d; d2[d2$S == 1 & d2$A == 0, pre] <- d2[d2$S == 1 & d2$A == 0, pre] + 2
check("P6 trial-control period I + 2 -> tau - 2", d2, expected = base - 2)

# P7 shift EC period I by c: tau moves by +c
d2 <- d; d2[d2$S == 0, pre] <- d2[d2$S == 0, pre] + 2
check("P7 EC period I + 2 -> tau + 2", d2, expected = base + 2)

# P8 treated-arm period I outcomes are not used (paper Remark 2)
d2 <- d; set.seed(12); d2[d2$A == 1, pre] <- rnorm(sum(d2$A == 1) * 2, 50, 10)
check("P8 scramble treated-arm period I", d2)

# P9 trial-control period II outcomes are not used (paper Remark 2)
d2 <- d; set.seed(13); d2[d2$S == 1 & d2$A == 0, post] <- rnorm(30 * 2, -50, 10)
check("P9 scramble trial-control period II", d2)

# P10 affine transform of a covariate (linear models are equivariant)
d2 <- d; d2$x1 <- 1e4 * d2$x1 + 5e5
check("P10 x1 -> 1e4 * x1 + 5e5", d2, tol = 1e-6)

# P11 duplicate every row
check("P11 stack two copies of the data", rbind(d, d))

# P12 within-period permutation of visit order in period I (average is symmetric)
d2 <- d; d2[pre] <- d2[rev(pre)]
check("P12 swap y1 and y2 (period I is averaged)", d2)

# P13 shift treated period II by c -> tau + c
d2 <- d; d2[d2$A == 1, post] <- d2[d2$A == 1, post] + 1.5
check("P13 treated period II + 1.5 -> tau + 1.5", d2, expected = base + 1.5)

# P14 NA in unused cells (trial-control period II) should not matter
d2 <- d; d2[d2$S == 1 & d2$A == 0, post] <- NA
check("P14 NA in trial-control period II (unused cells)", d2)
d2 <- d; d2[d2$A == 1, pre] <- NA
check("P15 NA in treated period I (unused cells)", d2)
