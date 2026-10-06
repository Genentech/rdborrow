# Monte Carlo pre-registration (written 2026-10-06 before any MC run)

The paper's Sec 4 does not publish its coefficients (they were fit to
SUNFISH + olesoxime data) or the covariate distribution, so I use my own
design with the same structure (Eq 11, Settings 1, 3, 4) that satisfies the
paper's assumptions exactly.

## DGP (one replicate)

- N = 220. Covariates: X1 ~ Bern(0.5), X2 ~ Bern(0.4), X3 in {2,3,4} with
  prob (0.1, 0.7, 0.2), X4 ~ U(2, 25), X5 ~ N(45, 10^2). Design vector
  h(X) = (X1, X2, X3, X4, X2*X4, X5).
- Trial participation: logit pi_S(X) = a + (0.5, -0.5, 0.4, 0.05, 0.03,
  -0.03) . (h(X) - centring), a tuned once (on a 1e6 sample, no outcomes)
  so that P(S = 1) = 0.75. S ~ Bern(pi_S(X)).
- Trial arm: A = S * Bern(2/3)  (n1 : n0 : m about 2 : 1 : 1 as in Sec 4.1).
- Unmeasured confounder: U | S ~ N(0.6 S, 1), independent of X given S.
  This keeps P(S = 1 | X) exactly logistic in h(X) and E[U | X, S] = 0.6 S,
  so the nuisance models are exactly correctly specified.
- Never-treated outcome, t = 1..4 (T1 = 2, T2 = 4):
  Y_t(0) = delta_t + m_t * theta' h(X) + lambda_t U + Delta S + b + e_t,
  delta = (0, -0.5, -1, -1.5), m = (1, 1.5, 2, 2.5),
  theta = (-1, -0.8, 0.6, -0.08, -0.15, 0.03), b ~ N(0, 1), e_t ~ N(0, 1).
  The time-varying m_t makes covariate adjustment necessary.
- Observed: trial treated Y_t = Y_t(0) + tau_t for all t; trial controls
  Y_t = Y_t(0) for t <= 2 and Y_t(0) + tau_{t-2} for t > 2 (crossed over;
  unused by every method per Remark 2); externals Y_t = Y_t(0).
  tau = (0.625, 1.5, 1.875, 2.5) as in Sec 4.1.
- True estimand (Eq 1): tau_3 = 1.875, tau_4 = 2.5 (constant effect, so the
  trial-population ATE equals the arm-level effect).

## Settings

| Setting | U | lambda_t | Delta | DID Assumption 3 | SCM Assumption 4 |
|---|---|---|---|---|---|
| S1 | absent (lambda = 0) | 0 | 0 | holds | holds |
| S3 | present | 1,1,1,1 | 1 | holds | fails (study effect) |
| S4 | present | 0.6,0.8,1.2,1.6 | 0 | fails | holds |

Expected DID bias in S4 (all three DID estimators, large-sample):
(lambda_t - mean(lambda_1, lambda_2)) * (E[U|S=1] - E[U|S=0])
= (1.2 - 0.7) * 0.6 = 0.30 at t = 3 and (1.6 - 0.7) * 0.6 = 0.54 at t = 4.

## Models given to the package

- ps_formula = "S ~ x1 + x2 + x3 + x4 + x2:x4 + x5" (correct), trt_formula =
  NULL (marginal; randomization is simple), outcome formulas
  "y_t ~ x1 + x2 + x3 + x4 + x2:x4 + x5" (correct) for all three OR groups
  and for AIPW.
- Misspecification arm (S3 only): drop x2:x4 from the outcome model
  (AIPW-mis-OR, OR-mis), or from the PS model (AIPW-mis-PS, IPW-mis).

## Budget

- DID: R = 400 replicates per setting, B = 199, percentile CI, seed 20261006
  + replicate index. Methods: did_ec_or, did_ec_ipw, did_ec_aipw (S1, S3,
  S4) plus the misspecified variants in S3.
- SCM: R = 150 replicates per setting (S1, S3, S4), package defaults
  (lambda grid {0, 0.1}, LOOCV), bootstrap = 2 (minimum; CIs ignored).

## Expected behaviour and pass/fail tolerances

- DID, S1 and S3, correctly specified models: |bias| <= 3 * MCSE + 0.02
  (0.02 allows O(1/n) ratio-estimator bias). Percentile coverage in
  [91.7%, 98.3%] (95% +/- 3 MCSE at R = 400). Mean bootstrap SE / empirical
  SD in [0.85, 1.15].
- DID, S3, AIPW with one model misspecified: same bias and coverage
  tolerances (double robustness, Theorem 1(3)). OR with misspecified outcome
  model and IPW with misspecified PS: no prediction, reported only.
- DID, S4: bias within 3 MCSE of (0.30, 0.54); coverage expected below 95%
  (reported, no tolerance).
- SCM: point-estimate bias only. Paper Table 1 reports SCM bias 0.04-0.17
  even when Assumption 4 holds (few pre-periods). Expectations:
  S1 |bias| <= 0.2; S4 bias > 0 (incomplete proxying of U by 2 noisy
  pre-period outcomes leaves part of the E[U|S=1] > E[U|S=0] confounding,
  which pushes tau-hat up); S3 bias != 0 (direction not predicted).
