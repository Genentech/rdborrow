# Adversarial review, OLE methods: numerical-validation tester (role 3)

## 1. Header

- Role: numerical-validation tester (issue #101, plan steps 1-2), scope
  `did_ec_or()`, `did_ec_ipw()`, `did_ec_aipw()`, `scm()`, `.ec_weights()`,
  `.run_bootstrap()`.
- Commit: `6185ba9` (package version 0.0.4.2), worktree
  `.claude/worktrees/agent-aff9bb4483ee6f9a3`, unmodified.
- R 4.6.1 (2026-06-24); CVXR 1.9.1, ECOSolveR 0.6.1, boot 1.3.32,
  osqp (independent SCM solver), 24 cores.
- Package loaded from the installed copy of this commit:
  `.libPaths(c(".../scratchpad/review-lib", .libPaths())); library(rdborrow)`
  (see `n3/common.R`). Internal helpers were called only to *observe*
  package behaviour (SC weights, LOOCV), never to compute an expected value.
- Specification: Zhou et al. (2024) J Biopharm Stat 34(6):893-921, Eqs 1-9,
  Remark 4, Appendix B (pages 915-916 rendered as images and read).
- Independent implementation: `3-independent-implementation.R` (base R;
  own Newton-Raphson logistic fit, own normal-equation OLS, SCM QP solved by
  OSQP with my own `P`, `q` formulation). Scripts and logs: `n3/`.
- Seeds: recorded in each script (`set.seed(1)` for single analyses;
  MC seeds `20261006 + rep + 1e5 * setting` (DID) and `30261006 + ...`
  (SCM)).

## 2. Equation-by-equation check

| Paper reference | Code location | Match? | Evidence |
|---|---|---|---|
| Eq 1 estimand: tau_t = E_R[Y_t(1,(1,1)) - Y_t(1,(0,0))], t in T2, trial population | all four `estimate()` methods return one row per Period II visit `tau{T_cross+1..T}` | Yes | DID methods average over all trial patients (OR: `colMeans` over `S == 1`, `R/did_ec_or.R:173-185`; IPW/AIPW: Hajek weights W11, W10, W0 standardize to the trial population). SCM Eq 9 uses arm means (valid by randomization). MC truth recovered (Sec 4). |
| Remark 2: Y_c,II (controls after crossover) unused | all methods | Yes | Shifting `y3` of trial controls by +100 leaves OR, IPW, AIPW unchanged (`n3/07_formula_alignment.log`); SCM uses only Period I rows of controls (`R/scm.R:177`). |
| Appendix B, B(X) = average over **all** T1 visits | `rowMeans(Y[, 1:T_cross])` `R/did_ec_ipw.R:168,170`; `R/did_ec_aipw.R:198,200`; `mean(avg_S1[1:T_cross])` `R/did_ec_or.R:187-188` | Yes | Agreement at T_cross = 1, 2, 3 (`n3/01_synthetic_compare.log`). |
| Gap carried to each Period II visit unchanged | same lines | Yes | same |
| Eq 3 / App. B DID-EC-OR: mu(X,1,(1,1),t) fit on trial treated, mubar(X,1,A1=0,T1) on trial controls, mu(X,0,(0,0),t) on externals, predictions averaged over all trial patients | `R/did_ec_or.R:156-188` | Yes | max abs diff 1.2e-14 on SyntheticData, T_cross 1-3; hand fixture F1 exact (7/6 and 7/4). |
| Eq 4 / App. B DID-EC-IPW: Hajek-normalized A W11 Y_t and (1-A) W10 Ybar(T1) within trial; W0/sum W0 (Y_t - Ybar(T1)) within externals | `R/did_ec_ipw.R:132-174` | Yes | 7e-15 (marginal pi_A), 1e-13 (with `trt_formula`); F1 exact. |
| W0(X) = p_R(X)/p_E(X) = pi_S(X)(1-pi_S)/((1-pi_S(X)) pi_S) (p. 900) | `R/ec_weights.R:14-19` | Yes | constant factor cancels in normalization; F1 saturated case gives odds ratio weights exactly (hand: 1/6, 1/6, 1/6, 1/2). |
| W11 = 1/pi_A, W10 = 1/(1-pi_A) | `R/did_ec_ipw.R:136-147` | Yes (plus extension) | `trt_formula` (pi_A(X) by logistic model) is a package extension, not in the paper; checked against own fit (1e-13). |
| Eq 5 / App. B DID-EC-AIPW: same as Eq 4 on residuals Y_t - mu(X, S=0, (0,0), t), outcome model fit on externals only | `R/did_ec_aipw.R:169-206` | Yes | 4e-15 / 1e-14; F1 exact. Double robustness confirmed by MC (Sec 4). |
| Eq 7 penalized SC (Abadie and L'Hour 2021): min ||z_i - Z w||^2 + lambda sum_j w_j ||z_i - z_j||^2, w >= 0, sum w = 1, z = (X, Y_I) | `R/scm.R:177-186` | Yes (as printed) | Closed-form fixture F2 (w_a = 0.25 - lambda/4) matched to <= 8e-5 for lambda in {0, 0.4, 0.8, 1.5}; per-subject objectives equal to OSQP to relative 1e-8 at lambda = 0.1. **But** z is unscaled, see F1. |
| Eq 7, matching variables: covariates and Period I outcomes only | `R/scm.R:115-116,177-178` (Period II rows removed) | Yes | — |
| Eq 8 SC prediction sum_j w_ij Y_jt for t in T2 | `R/scm.R:189` | Yes | — |
| Eq 9 tau = mean(Y_t, treated) - mean(SC, controls) | `R/scm.R:141-142` | Yes | SyntheticData: 2.9e-6 (lambda 0.1), 3.7e-6 (lambda 0.001); solver tolerance. lambda = 0: 4.1e-2, non-unique optimum (F3). |
| Remark 4 LOOCV over externals, squared error over t in T2 | `R/scm.R:206-229` | Yes (mean instead of sum; same argmin) | Same lambda chosen as independent code on seq(0, 1, length.out = 5) (0.25). On {0, 0.1} the choice depends on the solver (F3). |
| Theorem 1 / Sec 3.1 inference "using bootstrap" (unspecified scheme) | `.run_bootstrap()` `R/method_class.R:84-126`: patient-level rows resampled within strata `interaction(S, A)`; nuisance models refit in each replicate | Reasonable | Units are patients (wide data: one row per patient); fixed n1, n0, m mirrors the design. Percentile coverage 93-97% in MC (Sec 4). SCM refits weights but keeps the full-data lambda (F7). |
| Sec 4.1 "pi_A = 1/3 is same as the treatment to control ratio" | n/a | Paper erratum | With n1 : n0 = 2 : 1 the randomization probability is 2/3. No package impact. |

Conclusion: every DID formula in the code matches the paper and my
independent implementation to machine precision, and the SCM optimization
matches Eq 7 to solver tolerance. The findings below are about the SCM
design choices, robustness, and formula handling, not about the DID algebra.

## 3. Findings (most severe first)

### F1. SCM matches on raw, unstandardized variables, so large-unit covariates decide the synthetic control and the estimate depends on units

- Location: `R/scm.R:115-116, 177-182, 210-215`; paper Eq 7 and the text
  after it (Sec 3.2, p. 902-903).
- Reproducer: `Rscript n3/05_scm_scale.R` (log `n3/05_scm_scale.log`).

  ```
  SDs among externals:  x1 0.49  x2 0.31  x3 0.44  x4 9.65  x5 12.09  y1 3.88  y2 4.11
  mean share of ||z_i - z_j||^2:  x1 0.001  x2 0.000  x3 0.001  x4 0.240  x5 0.666  y1 0.043  y2 0.049
  original     SCM(lambda=0.1): 2.1421, 4.5941 | DID-EC-OR: 1.5689, 4.4078 | DID-EC-AIPW: 2.1300, 4.1801
  x5_div_100   SCM(lambda=0.1): 1.8149, 5.8787 | DID-EC-OR: 1.5689, 4.4078 | DID-EC-AIPW: 2.1300, 4.1801
  x4_times_12  SCM(lambda=0.1): 1.4664, 4.8468 | DID-EC-OR: 1.5689, 4.4078 | DID-EC-AIPW: 2.1300, 4.1801
  independent, raw z, LOOCV lambda 0:          tau 2.106, 3.972
  independent, z / SD(external), LOOCV lambda 0: tau 1.317, 5.270
  ```
- Expected: the paper's rationale (p. 903) is that Y_I "approximates
  matching on unmeasured covariates" and that the SC is similar to the
  control "in both X and Y_I". A change of units of a covariate should not
  change the causal estimate; the DID estimators are invariant.
- Actual: on `SyntheticData` two continuous covariates carry 91% of the
  squared distance and the Period I outcomes 9%; the binary covariates are
  effectively ignored. Recording `x5` in other units moves tau_4 from 4.59
  to 5.88; standardizing all matching variables moves it from 3.97 to 5.27
  (a shift of 1.3, larger than the SCM sampling SD of about 0.8 in the
  Monte Carlo of Sec 4.3, which has similar sample sizes). lambda is also on the raw scale, so the
  default grid means different things for different units.
- Whose problem: the code implements Eq 7 as printed (the paper also writes
  raw z_i). The gap is in the method specification and in the docs, which
  say only "matching ... on covariates and pre-crossover outcomes"
  (`R/scm.R:28-31`) with no warning about scale. (Abadie et al. 2010 use a
  diagonal V matrix and Abadie and L'Hour 2021 normalize covariates in their
  applications; I did not re-verify the latter here.)
- Category: method limitation / design question (plus documentation gap).
  Severity: misleading.
- Proposed test (documents the chosen contract; whichever behaviour is
  adopted, the test pins it):

  ```r
  test_that("scm() estimates do not depend on covariate units", {
    skip_on_cran()
    d <- SyntheticData
    d2 <- transform(d, x5 = x5 / 100)
    fit <- function(dd) {
      a <- setup_analysis_OLE(dd, "S", "A", paste0("y", 1:4),
        paste0("x", 1:5), scm(0.1, 0.1, 1, bootstrap = 2), T_cross = 2)
      set.seed(1)
      suppressWarnings(run_analysis(a))$point_estimates
    }
    expect_equal(fit(d2), fit(d), tolerance = 1e-4)
  })
  ```
  (Fails today. If the package decides to keep raw scaling, replace it with
  a documentation requirement in `?scm` and a test that standardizing is the
  user's job.)

### F2. SCM ignores the solver status: inaccurate solutions are used, and a solver failure gives a cryptic error

- Location: `R/scm.R:186-189` and `219-222` (`CVXR::psolve()` then
  `CVXR::value(w)` with no status check).
- Reproducer: `Rscript n3/09_scm_age_in_days.R`,
  `Rscript n3/09b_scm_status_probe.R`, `Rscript n3/08_scm_solver_status.R`.

  ```
  # SyntheticData with x4 (age-like, 1-32) recorded in days, scm() defaults
  Error in ec[long_term_col_name, -loocv] %*% wt_est :
    requires numeric/complex matrix/vector arguments
  # status of the LOOCV solves on that data
    lambda  k             status value_class
       0.0 14         infeasible        NULL
       0.1  1 optimal_inaccurate      matrix
       0.1 14         user_limit      matrix
  # independent OSQP solve of the same problem: sum(w) = 1, objective 1.45e8 (feasible, solved)
  # x5 * 1e3: ECOS warns "Solution may be inaccurate" (6/20 subjects), min w = -8.9e-07
  ```
- Expected: the simplex-constrained QP is always feasible. A failed solve
  should either be prevented (scale the problem) or stop with a message
  that names the problem; an inaccurate or iteration-limited solution
  should not silently enter the estimate.
- Actual: ECOS returns `infeasible` on a feasible problem when one covariate
  is in units of thousands; `value(w)` is `NULL` and the user sees a matrix
  multiplication error. `user_limit` and `optimal_inaccurate` solutions are
  used, with at most a CVXR warning (the test suite wraps SCM runs in
  `suppressWarnings()`, `tests/testthat/test-scm.R`).
- Category: implementation bug. Severity: gap (error or warning, not silent
  in the failure case; possibly inaccurate weights in the `user_limit`
  case).
- Proposed test:

  ```r
  test_that("scm() fails informatively or succeeds with large-unit covariates", {
    skip_on_cran()
    d <- transform(SyntheticData, x4 = x4 * 365.25)
    a <- setup_analysis_OLE(d, "S", "A", paste0("y", 1:4), paste0("x", 1:5),
      scm(bootstrap = 2), T_cross = 2)
    set.seed(1)
    res <- suppressWarnings(run_analysis(a))
    expect_all_true(is.finite(res$point_estimates))
  })
  ```

### F3. The default lambda grid is {0, 0.1}; at lambda = 0 Eq 7 has no unique solution, so the LOOCV choice and the estimate depend on the solver

- Location: `R/scm.R:17-19, 57-59` (defaults), `R/scm.R:206, 229`
  (grid and `which.min`); paper Sec 3.2 (penalization "addresses the issue of
  non-unique best synthetic controls"), Remark 4.
- Reproducer: `Rscript n3/02_scm_subject_compare.R`,
  `Rscript n3/06_scm_lambda0.R`, `Rscript n3/03_scm_lambda_cv.R`.

  ```
  lambda = 0: subjects with zero objective (z_i in hull of externals): 17 of 100
              subjects whose SC prediction differs between two optimal solutions by > 1e-3: 18
              largest difference in a subject's predicted Period II outcome: 1.54
              non-zero weights per subject, ECOS (package): up to 41; OSQP: up to 33
  SCM tau, lambda = 0: package (ECOS) 2.0648, 3.9432 | independent (OSQP) 2.1062, 3.9717
  LOOCV SSE  lambda 0: ECOS 3585.98, OSQP 3523.485 | lambda 0.1: 3523.49 (both)
  package LOOCV choice on default grid: 0.1; independent LOOCV choice on the same grid: 0
  ```
- Expected: the paper motivates lambda > 0 precisely because the lambda = 0
  problem has many optimal weight vectors when the target lies in the
  convex hull ("find a few external control patients", p. 901). A tuning
  grid that includes 0 should not make the result a property of the solver.
- Actual: the interior-point solver returns a central, dense solution (up to
  41 donors) for 17% of controls; another exact solver returns a different
  optimum, and the LOOCV error at lambda = 0 (and hence the selected lambda)
  depends on which one. The default grid has only two points, so "LOOCV"
  compares lambda = 0 against a single positive value whose meaning depends
  on the units of the covariates (F1). The ECOS solution is deterministic
  and invariant to row order (checked: permuting externals changes tau by
  3e-8), so results are reproducible within this solver. In the SCM Monte
  Carlo (Sec 4.3) the typical impact is small (median per-replicate
  difference between the two implementations 0.002) but 0.7% of estimates
  differ by more than 0.1, up to 1.27.
- Category: design question. Severity: gap.
- Proposed test:

  ```r
  test_that("scm() default tuning grid excludes the non-unique lambda = 0", {
    m <- scm()
    expect_gt(m@lambda_min, 0)
    expect_gte(m@nlambda, 3L)
  })
  ```

### F4. `did_ec_or()` and `did_ec_aipw()` match outcome formulas to visits by position (extends #104 to the OLE methods)

- Location: `R/did_ec_or.R:153-188` (index t of each formula list defines
  visit t, the formula's left side defines what is predicted);
  `R/did_ec_aipw.R:169-175` (`Yr <- Y - Y0`, columns of `Y` from
  `outcome_col_name`, columns of `Y0` from formula order).
- Reproducer: `Rscript n3/07_formula_alignment.R`.

  ```
  OR   in order: 1.568947  4.407834
  OR   permuted (y3, y4, y1, y2): -4.157573 -1.406035
  AIPW in order: 2.130006  4.180107
  AIPW permuted: 2.19187   4.87523
  ```
- Expected / actual: as in #104 (same estimate, or an error naming the
  mismatch); here the OR estimate even changes sign. #104 lists these two
  methods as "possibly the same pattern, not yet examined": this is the
  confirming evidence, not a new issue. Note that DID-EC-OR never reads the
  outcome columns named in `setup_analysis_OLE()`; only the formulas
  determine what is modelled.
- Category: implementation bug. Severity: wrong. Link to #104.
- Proposed test: as #104, with `did_ec_or(fp, fp, fp)` and
  `did_ec_aipw(ps, NULL, fp)` where `fp <- f[c(3, 4, 1, 2)]`;
  `expect_equal(fit(fp), fit(f))` or `expect_error(fit(fp), "formula")`.

### F5. A formula count different from the number of outcomes gives unrelated low-level errors, and half of the DID-EC-OR formulas are silently ignored

- Location: `R/did_ec_or.R:153` (`n_time <- length(outcome_formula_ext)`,
  not `length(outcomes)`), `R/did_ec_or.R:161-170`; `R/did_ec_aipw.R:169-173`.
- Reproducer: `Rscript n3/07_formula_alignment.R`.

  ```
  OR, 3 formulas for 4 outcomes:   Error in boot.out$t[, index] : subscript out of bounds
  AIPW, 3 formulas for 4 outcomes: Error in Y0_models[[t]] : subscript out of bounds
  OR, 5 formulas for 4 outcomes:   Error in data.frame(...): arguments imply differing number of rows: 3, 2
  ```
- Expected: `setup_analysis_OLE()` or the constructor checks that each
  formula vector has one formula per outcome (or matches them by left side,
  see F4) and says so. The OR point estimate is computed before the error
  in the first case (it is the bootstrap that fails), so a future change in
  `.run_bootstrap()` could make this silent.
- Also: `outcome_formula_rct_ctrl[(T_cross+1):T]` and
  `outcome_formula_rct_trt[1:T_cross]` must be supplied but are never used
  (paper Eq 3 has no such models). The roxygen says "one per time point"
  without saying which are used.
- Category: implementation bug (validation) / documentation error.
  Severity: polish.
- Proposed test:
  `expect_error(run_analysis(<OR with 3 formulas, 4 outcomes>), "formula")`.

### F6. `scm()` crashes with two external controls (missing `drop = FALSE`)

- Location: `R/scm.R:211` (`ec[..., -loocv]` becomes a vector when two
  externals remain one), also `R/scm.R:178` with a single external.
- Reproducer: `Rscript n3/04_hand_fixtures.R` (last block).
  `Error in colSums((x1 - X0)^2): 'x' must be an array of at least two dimensions`.
- Expected: either a result or a validation error ("scm() needs at least 3
  external controls"). Category: implementation bug. Severity: polish.
- Proposed test: `expect_error(run_analysis(<F2 fixture with 2 externals>), "external")`
  or `expect_all_true(is.finite(...))`.

### F7. SCM bootstrap keeps the full-data lambda fixed

- Location: `R/scm.R:146-154, 239-265`.
- Expected/actual: the bootstrap replicates re-solve Eq 7 with the lambda
  selected once on the full data, so tuning variability is not propagated.
  The paper does not say how it bootstrapped SCM. Re-running LOOCV per
  replicate would cost m x nlambda extra solves per replicate.
- Category: design question. Severity: polish (document it).

### F8. `?estimate` says it returns "a list"; OLE methods return a data frame

- Location: `R/method_class.R:54`; `R/did_ec_or.R:126-131` etc.
- Category: documentation error. Severity: polish.
- Proposed test: `expect_s3_class(estimate(did_ec_or(...), ...), "data.frame")`
  next to a corrected `@return`.

## 4. Monte Carlo

### 4.1 Pre-registered design (written before any run; file `n3/MC_PREREGISTRATION.md`)

The paper's Sec 4 does not publish its coefficients or covariate
distribution (they were fit to SUNFISH + olesoxime), so I used my own design
with the structure of Eq 11 and Settings 1, 3, 4, chosen so the nuisance
models are exactly correctly specified:

- N = 220; X1 ~ Bern(0.5), X2 ~ Bern(0.4), X3 in {2,3,4} (0.1, 0.7, 0.2),
  X4 ~ U(2, 25), X5 ~ N(45, 10^2); h(X) = (X1, X2, X3, X4, X2*X4, X5).
- logit P(S=1|X) = a + (0.5, -0.5, 0.4, 0.05, 0.03, -0.03)'(h(X) - c),
  a = 1.18839 tuned once on 1e6 covariate draws (no outcomes) to give
  P(S = 1) = 0.75; A = S x Bern(2/3). Realized mean n1, n0, m = 110.4,
  54.8, 54.8 (paper: about 110, 55, 55).
- U | S ~ N(0.6 S, 1), independent of X given S (keeps the PS exactly
  logistic and E[U | X, S] = 0.6 S).
- Y_t(0) = delta_t + m_t theta'h(X) + lambda_t U + Delta S + b + e_t,
  delta = (0, -0.5, -1, -1.5), m = (1, 1.5, 2, 2.5),
  theta = (-1, -0.8, 0.6, -0.08, -0.15, 0.03), b, e_t ~ N(0, 1).
  Treated: + tau_t at all visits; controls after crossover: + tau_{t-2}
  (unused). tau = (0.625, 1.5, 1.875, 2.5) as in Sec 4.1, so the truth is
  tau_3 = 1.875, tau_4 = 2.5.
- Settings: S1 no U, Delta = 0 (both assumptions hold); S3 lambda_t = 1,
  Delta = 1 (DID holds, SCM fails); S4 lambda_t = (0.6, 0.8, 1.2, 1.6),
  Delta = 0 (parallel trends fail, SCM assumption holds). Expected DID bias
  in S4: (lambda_t - 0.7) x 0.6 = 0.30 (t = 3), 0.54 (t = 4).
- Models: correct PS `S ~ x1 + x2 + x3 + x4 + x2:x4 + x5` and outcome
  formulas with the same right side; in S3 also misspecified variants
  (drop `x2:x4`) for OR, IPW and each AIPW nuisance model. `trt_formula`
  NULL.
- DID: R = 400 per setting, B = 199, percentile CI. SCM: R = 150, package
  defaults (`scm(bootstrap = 2)`), point estimates only.
- Tolerances: DID S1/S3 correct models and AIPW with one model wrong:
  |bias| <= 3 MCSE + 0.02; coverage in [91.7, 98.3]%; (CI width / 3.92) /
  empirical SD in [0.85, 1.15] (the pre-registration said "mean bootstrap
  SE"; `run_analysis()` does not return it, so I used the percentile-CI
  width proxy, the only deviation). S4: bias within 3 MCSE of 0.30 / 0.54,
  coverage reported. SCM: S1 |bias| <= 0.2; S4 bias > 0; S3 bias != 0.

### 4.2 DID results (`n3/10_mc_did.R`, summary `n3/12_mc_summary_did.log`)

Package and independent estimates agreed in every replicate of S1, S3, S4
for OR, IPW and AIPW: max |difference| = 4.4e-7 over 7,200 estimates
(glm convergence tolerance). No non-finite estimates or CIs.

| Setting | Method | t | Bias (MCSE) | Expected | Emp. SD | Width proxy / SD | Coverage % (MCSE) | Verdict |
|---|---|---|---|---|---|---|---|---|
| S1 | OR | 3 | 0.032 (0.016) | 0 | 0.316 | 1.02 | 95.0 (1.1) | pass |
| S1 | OR | 4 | 0.041 (0.016) | 0 | 0.312 | 1.04 | 95.8 (1.0) | pass (z = 2.6, within 3 MCSE + 0.02) |
| S1 | IPW | 3 | 0.018 (0.030) | 0 | 0.597 | 1.03 | 94.2 (1.2) | pass |
| S1 | IPW | 4 | 0.020 (0.035) | 0 | 0.701 | 1.02 | 94.2 (1.2) | pass |
| S1 | AIPW | 3 | 0.024 (0.016) | 0 | 0.325 | 1.08 | 97.2 (0.8) | pass |
| S1 | AIPW | 4 | 0.032 (0.016) | 0 | 0.317 | 1.10 | 96.8 (0.9) | pass |
| S3 | OR | 3 | -0.019 (0.017) | 0 | 0.339 | 1.09 | 96.8 (0.9) | pass |
| S3 | OR | 4 | -0.009 (0.017) | 0 | 0.348 | 1.06 | 95.0 (1.1) | pass |
| S3 | IPW | 3 | -0.039 (0.030) | 0 | 0.605 | 1.03 | 93.8 (1.2) | pass |
| S3 | IPW | 4 | -0.044 (0.034) | 0 | 0.681 | 1.05 | 95.0 (1.1) | pass |
| S3 | AIPW | 3 | -0.013 (0.018) | 0 | 0.350 | 1.15 | 97.2 (0.8) | pass (ratio at limit) |
| S3 | AIPW | 4 | -0.005 (0.018) | 0 | 0.359 | 1.13 | 96.2 (0.9) | pass |
| S3 | AIPW, OR model wrong | 3 | -0.014 (0.018) | 0 | 0.364 | 1.17 | 97.0 (0.9) | bias/coverage pass; width ratio 1.17 > 1.15 |
| S3 | AIPW, OR model wrong | 4 | -0.009 (0.020) | 0 | 0.398 | 1.11 | 97.0 (0.9) | pass |
| S3 | AIPW, PS wrong | 3 | -0.014 (0.018) | 0 | 0.349 | 1.15 | 96.8 (0.9) | pass (ratio at limit) |
| S3 | AIPW, PS wrong | 4 | -0.004 (0.018) | 0 | 0.357 | 1.12 | 96.8 (0.9) | pass |
| S3 | OR, OR model wrong | 3 | -0.042 (0.018) | none | 0.353 | 1.10 | 95.8 (1.0) | reported |
| S3 | OR, OR model wrong | 4 | -0.050 (0.020) | none | 0.392 | 1.04 | 93.5 (1.2) | reported |
| S3 | IPW, PS wrong | 3 | -0.088 (0.030) | none | 0.601 | 1.03 | 93.8 (1.2) | reported |
| S3 | IPW, PS wrong | 4 | -0.123 (0.034) | none | 0.681 | 1.04 | 93.0 (1.3) | reported |
| S4 | OR | 3 | 0.303 (0.017) | 0.30 | 0.343 | 1.08 | 87.5 (1.7) | pass |
| S4 | OR | 4 | 0.518 (0.020) | 0.54 | 0.393 | 1.05 | 76.5 (2.1) | pass |
| S4 | IPW | 3 | 0.259 (0.029) | 0.30 | 0.585 | 1.07 | 93.5 (1.2) | pass |
| S4 | IPW | 4 | 0.458 (0.035) | 0.54 | 0.708 | 1.04 | 90.2 (1.5) | pass (z = -2.3) |
| S4 | AIPW | 3 | 0.310 (0.018) | 0.30 | 0.368 | 1.10 | 88.2 (1.6) | pass |
| S4 | AIPW | 4 | 0.527 (0.021) | 0.54 | 0.420 | 1.05 | 77.5 (2.1) | pass |

Reading:

- All three DID estimators are unbiased (within tolerance) when parallel
  trends hold, with and without unmeasured confounding and a study effect,
  and the percentile bootstrap covers at 93.8-97.2%.
- Double robustness of DID-EC-AIPW (Theorem 1(3)) holds: dropping `x2:x4`
  from either nuisance model leaves bias within 1 MCSE of zero, while the
  single-model estimators with the same misspecification drift (IPW -0.12,
  z = -3.6; OR -0.05, z = -2.5).
- When parallel trends fail (S4) all three DID estimators show the
  pre-computed bias (0.30, 0.54) within 3 MCSE, and coverage falls to
  77-93%, as the method predicts. This is a method limitation, not a bug.
- The bootstrap is mildly conservative for AIPW (width proxy / SD up to
  1.17, coverage 96-97%). This is one marginal miss of a proxy tolerance
  with no corresponding coverage failure; I do not report it as a finding.
- S1 OR and AIPW both have small positive bias (0.03-0.04, z = 2.0-2.6),
  within the pre-registered allowance; the two estimators are highly
  correlated across replicates, so this is not two independent signals.

### 4.3 SCM results

`n3/11_mc_scm.R`, summary `n3/12_mc_summary_scm.log`. R = 150, package
defaults `scm(bootstrap = 2)`; "independent" = my OSQP implementation with
LOOCV on the same grid {0, 0.1}; "standardized" = independent
implementation with every matching variable divided by its external-control
SD and LOOCV on {0, 0.01, 0.1, 1}. No non-finite package estimates.

| Setting | t | Package bias (MCSE) | Emp. SD | Independent bias (MCSE) | Standardized bias (MCSE) | Pre-registered | Verdict |
|---|---|---|---|---|---|---|---|
| S1 | 3 | -0.056 (0.059) | 0.72 | -0.058 (0.059) | -0.148 (0.055) | abs(bias) <= 0.2 | pass |
| S1 | 4 | -0.054 (0.071) | 0.87 | -0.056 (0.071) | -0.169 (0.067) | abs(bias) <= 0.2 | pass |
| S3 | 3 | 0.307 (0.057) | 0.70 | 0.314 (0.058) | 0.435 (0.054) | != 0 | pass (5.4 MCSE) |
| S3 | 4 | 0.118 (0.065) | 0.79 | 0.127 (0.066) | 0.285 (0.063) | != 0 | not detected (1.8 MCSE) |
| S4 | 3 | 0.304 (0.059) | 0.72 | 0.303 (0.059) | 0.295 (0.059) | > 0 | pass |
| S4 | 4 | 0.448 (0.069) | 0.85 | 0.448 (0.069) | 0.434 (0.069) | > 0 | pass |

Reading:

- Package and independent SCM agree in distribution (mean biases within
  0.01). Per replicate the median |difference| is 0.002; 6-8% of estimates
  differ by more than 0.01 and 0.7% by more than 0.1 (max 1.27, in S3).
  The independent LOOCV picked lambda = 0 in 89-95% of replicates, so these
  rare large differences come from the non-unique lambda = 0 optimum or a
  different lambda choice (F3). Typical impact is small in this DGP.
- When the SCM assumption holds but there are only two Period I visits
  (S4), SCM carries a bias (0.30, 0.45) as large as DID's under its own
  assumption failure, with about twice DID's SD. This matches the paper's
  conclusion that SCM is biased with few pre-periods and that DID is
  preferable (Sec 4.2), and is a method limitation.
- Standardizing the matching variables changes the bias by 0.1-0.17 in S1
  and S3, again showing that the SCM estimand in practice depends on
  scaling (F1); neither scaling dominates.
- SCM SD (0.70-0.87) is about twice the OR/AIPW SD (0.31-0.42), as in
  paper Table 1 (0.35 vs 0.10-0.14).

### 4.4 Qualitative comparison with the paper's Sec 4

- Paper Table 1: DID estimators near-unbiased with coverage 94-96%; IPW has
  the largest SE; OR and AIPW are similar. Same pattern here (SD: IPW
  0.60-0.71, OR/AIPW 0.31-0.42).
- Paper Setting 4: DID bias 0.03-0.05; mine is larger (0.30-0.54) because I
  chose a stronger time variation in lambda_t to make the expected bias
  detectable. Direction and proportionality match.
- Paper: misspecification "does not increase bias significantly". With a
  larger interaction coefficient I see IPW with a wrong PS biased by -0.12
  (3.6 MCSE), while AIPW is protected, which is what Theorem 1 predicts.

## 5. Unexecuted suspicions

1. `bootstrap_ci_type = "bca"` with `scm()`: `boot.ci(type = "bca")` calls
   `empinf()`, which re-runs the statistic n times (one SCM fit per trial
   control per call); not run, runtime could be very large.
2. Rank-deficient outcome fits in the bootstrap (#86) also apply to the
   misspecification arms here; I did not count warnings because
   `pkg_fit()` suppresses them.
3. Abadie and L'Hour (2021) standardization of covariates: cited from
   memory in F1, not re-checked against that paper.
