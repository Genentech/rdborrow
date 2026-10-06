# Pre-registered Monte Carlo design (written before any MC results were seen)

## DGP (MC-A: assumptions hold; Supplement Table 1, Scenario A)
- X1, X2 iid N(0, 1)
- S ~ Bernoulli(expit(log 2 + 0.1 X1 + 0.1 X1^2 + 0.1 X2))  (pi_S about 0.69)
- in the trial, complete randomization with exactly round(2/3 n) treated; A = 0 for external
- Y_t(0) = 0.5 X1 + 0.5 X1^2 + 0.5 X2 + e_t, t = 1, 2; corr(e_1, e_2) = 0.5, var 1
- Y_t(1) = Y_t(0) + tau_t, true tau = (1, 2)
- working models: PS S ~ x1 + x1sq + x2 (correct); outcome y_t ~ x1 + x1sq + x2 (correct)
- sample sizes N = n + m in {300, 1200}

## Estimators
EC-IPW and EC-AIPW, each with weight in {0, NULL (Eq 11), 0.5, 1}.

## Inference
1. Sandwich (package default), R = 2000 replicates per N (seed 101 + N).
2. Percentile bootstrap (B = 199), R = 400 replicates at N = 300 only, for
   EC-IPW and EC-AIPW at weight NULL and 0.5 (seed 2026).

## Expected behavior and pass/fail tolerances
- Bias: true tau is (1, 2) for every estimator (all are consistent here).
  PASS if |bias| <= 3 MCSE (MCSE = empirical SD / sqrt(R)).
- Sandwich 95% coverage: N = 1200, PASS if within 0.95 +/- 3 * sqrt(0.95 * 0.05 / 2000) = [0.935, 0.965].
  N = 300, PASS if >= 0.92 (some finite-sample under-coverage of Wald sandwich intervals is expected and not a defect).
- SE calibration: mean(sandwich SE) / empirical SD of tau-hat; N = 1200 PASS if in [0.95, 1.05].
- Paper's printed Eq 13 / Eq 16 (diagonal blocks only) computed with my independent code alongside;
  my prediction: it is miscalibrated for EC-AIPW at w > 0 (cross-covariances non-zero), fine for EC-IPW.
- Bootstrap percentile coverage: PASS if within 0.95 +/- 3 * sqrt(0.95 * 0.05 / 400) = [0.917, 0.983].
- Property: ec_ipw(weight = 0) equals the trial-only difference in means in every replicate (to 1e-10).
- Agreement: package tau and SE equal my independent implementation in every replicate (rel tol 1e-6).

## MC-B (bias check; Supplement Scenario B, direct effect of trial participation)
Same as MC-A, N = 300, R = 1000 (seed 7), but trial subjects' Y(0) gets + 0.5 (direct effect of S).
Expected bias of tau-hat(w) = +0.5 * w for fixed w (mu00 is 0.5 below the trial control mean),
and approximately 0.5 * mean(w-hat) for the Eq 11 weight. w = 0 unbiased. PASS if within 3 MCSE.

## MC-C (added before running it, after MC-A N = 300 results were seen): double robustness (Theorem 2 / Theorem 4)
DGP: as MC-A but with stronger selection so that misspecification matters:
  logit pi_S = 0.5 + 0.5 X1 - 0.5 X1^2 + 0.3 X2;  Y_t(0) = 0.5 X1 + 0.5 X1^2 + 0.5 X2 + e_t; tau = (1, 2).
N = 1200, R = 1000, seed 31. Fixed weight w = 0.5 and Eq 11 weight. Sandwich CIs.
Cells:
  (i)   PS misspecified (S ~ x1 + x2), outcome correct (y ~ x1 + x1sq + x2)
  (ii)  PS correct, outcome misspecified (y ~ x1 + x2)
  (iii) both misspecified
Expected:
  EC-AIPW unbiased in (i) and (ii) (|bias| <= 3 MCSE) with coverage within 0.95 +/- 0.021;
  EC-IPW biased in (i) (|bias| > 3 MCSE; this shows the DGP is sensitive), unbiased in (ii).
  (iii): no prediction; report only.
