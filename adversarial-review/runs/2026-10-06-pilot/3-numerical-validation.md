# rdborrow pilot review: numerical-validation tester (role 3)

## 1. Header

| | |
|---|---|
| Role | 3, numerical-validation tester (issue #101), pilot scope `ec_ipw()` / `ec_aipw()` |
| Commit | worktree HEAD `6185ba9` (package code identical to `main` at 6185ba9) |
| Package | rdborrow 0.0.4.2, installed copy at `.../scratchpad/review-lib` |
| R | 4.6.1 (2026-06-24), Linux, OpenBLAS (pthread) |
| Loading | `.libPaths(c(".../scratchpad/review-lib", .libPaths())); library(rdborrow)` (file `review-pilot/n3/lib.R`); clean `Rscript` processes; no `load_all()` |
| Spec | Zhou, Zhu, Drake, Pang, JRSS-A 2025;188(3):791-818 + supplement. Equations read from rendered pages (pp. 796-802, 814-815) |
| Independent code | `review-pilot/3-independent-implementation.R` (base R + `stats`; own Newton-Raphson logistic fit, own normal-equation OLS, sandwich bread by **finite differences** of the stacked estimating functions written from Theorems 3/4, so the analytic blocks of Eq 12/15 are checked, not copied) |
| Scripts / raw output | `review-pilot/n3/`: `compare.R`, `probe1.R`, `probe2.R`, `probe3.R`, `probe_mem.R`, `mc.R`, `mcC.R`, `summarise.R`, `proposed-tests.R`, `preregistration.md`, `mc*.rds`, `mc.log`, `mcC.log` |
| Seeds | MC-A 401 (N=300) and 1301 (N=1200) via `set.seed(101 + N)`; MC-B 7; MC-boot 2026; MC-C 31; all `RNGkind("L'Ecuyer-CMRG")` + `parallel::mclapply(mc.set.seed = TRUE)`, 8-10 cores; probes: 42, 5, 20261006 |

**Proposed tests were executed** against the installed package (`n3/test-proposed.R`, `n3/test-proposed2.R` via `testthat::test_file()`). The F1, F2 and F5 tests fail on 6185ba9, as intended. The hand-fixture, independent-sandwich (F3) and Eq 11 closed-form (F6) anchor tests pass.

**Bottom line.** Every quantity in scope matches the paper and my independent implementation to machine precision: point estimates (|diff| <= 1.3e-14), W00, Eq 11 weight, and the sandwich SEs (relative diff <= 1.2e-10, limited by my finite differences). The sandwich and percentile bootstrap intervals are calibrated in pre-registered Monte Carlo studies (coverage 0.94-0.96 at N = 1200; double robustness of EC-AIPW holds). The defects I found are in the *interface around* the statistics, not in the statistics themselves: one silent wrong-answer path (F1), one hard failure for any trial-status column not named `S` (F2), and smaller items.

## 2. Equation-by-equation table

Evidence key: **C** = `n3/compare.R` output on SyntheticData (y1-y4, 5 covariates, w in {NULL, 0, 0.3, 1}) and the hand fixture; **MC** = Monte Carlo §4.

| Paper reference | Code location | Match? | Evidence |
|---|---|---|---|
| Thm 1: W11 = 1/pi_A, W10 = 1/(1 - pi_A) (constant) | `R/ec_ipw.R:162-163,187`; `R/ec_aipw.R:202-203,220-221` | Yes | Constant W11/W10 make mu11, mu10 the arm means (Hajek with constant weights). Paper says covariate-dependent W11/W10 are "optional in a completely randomized trial"; not offered (related: #84). |
| Thm 1: W00 = pi_S(X)(1 - pi_S) / ((1 - pi_S(X)) pi_S), logistic pi_S(X; alpha) | `R/ec_weights.R:10-19` | Yes | Hand fixture: W00 = (0.6, 0.6, 1.8) exactly; C: identical tau. |
| Def 1 / Eq 6 (EC-IPW estimator) | `R/ec_ipw.R:155-205` | Yes | Hand fixture tau = 153/47 = 3.2553191 (w-hat), 4 (w=0), 3.3 (w=0.5) all exact; C: max abs diff 1.2e-14. |
| "w = 0 reduces to trial-only Hajek" (p. 796) | `R/ec_ipw.R:166-171,224-232` | Yes | Equals trial difference in means and its MLE-type sandwich SE exactly (C: diff 0 / 2e-16; MC: `max_dim0 = 0` in all 4000 reps). |
| Thm 2 / Def 2 / Eq 7: Y-tilde = Y - mu(X), mu(X) = E[Y \| X, A = 0] | `R/ec_aipw.R:205-235` | Yes | Outcome model fit on all A = 0 rows (trial + external), as in Thm 2 and Psi5 of Thm 4 (by design, see #92). C: max diff 4.4e-15; also with a different formula per time point (`probe2.R`). |
| Eq 11 (optimal weight) | `R/ec_ipw.R:186-192`; `R/ec_aipw.R:225-228` | Yes | Hand fixture 25/47 exact; C: 0.14751965 both. Note: reduces to ESS_ext / (n10 + ESS_ext) since W10 is constant. |
| Eq 9/10 vs Eq 11 | docs | Doc wording | Eq 11 is an outcome-free approximation of Eq 10 assuming B = 0 and equal residual variances (App. B); see F6. |
| Thm 3 Psi_1..Psi_4 (meat) | `R/ec_ipw.R:254-259` | Yes | My Psi coded from Thm 3; meat identical (SEs agree to 1e-10); colMeans(Psi) at estimate ~ 1e-15. |
| Thm 3 / Eq 12 bread A1 (-I, -I, -E_E[W00] I, A34, A44) | `R/ec_ipw.R:240-252` | Yes | Finite-difference bread reproduces the analytic one (SEs agree to 1e-10). A34 sign/normalisation (1 - pi_S) and A33 = -mean over externals both correct. No missing block: pi_S and pi_A are treated as known, as in the paper; their derivatives have mean zero at the solution, so this is asymptotically exact. |
| Eq 13 (variance) | `R/ec_ipw.R:261-272` | **Differs from the printed formula (code is right)** | Paper prints (Sigma11 + (1-w)^2 Sigma22 + w^2 Sigma33)/(n+m), dropping cross-covariances; code uses the full linear combination c' Sigma c / (n+m). Printed formula is up to 19% too large (F3). Denominator n + m: matches. |
| Thm 4 Psi_5 = (1-A)/(1-pi_A)(Y - X'beta)X | `R/ec_aipw.R:321-323` | Yes | Code scales by 1/(1 - mean(A)) over all N instead of 1/(1 - pi_A); a constant row scaling cancels in A^-1 B A^-T (verified: my version uses pi_A, SEs agree to 1e-10). |
| Thm 4 / Eq 15 bread A2 (A1 plus -E[SA X'/(pi_S pi_A)], -E[S(1-A)X'/...], -E[(1-S)W00 X'/(1-pi_S)], 0, -E[(1-A)/(1-pi_A) XX']) | `R/ec_aipw.R:268-312` | Yes | Finite-difference bread agrees. The design matrices come from a full-data refit (F5). |
| Eq 16 (variance) | `R/ec_aipw.R:327-337` | **Differs from printed formula (code is right)** | Same as Eq 13; printed formula up to 12.5% too large for EC-AIPW (F3). |
| Variance of w-hat | `R/ec_ipw.R:110`, `R/ec_aipw.R:135` | Matches paper (fixed w) | Thm 3/4 are stated "for any fixed w"; w-hat is treated as fixed. Negligible when B = 0 (see F8). |
| Eq 14 / 17 Wald CI | `R/ec_ipw.R:107-117`; `R/ec_aipw.R:140-147` | Yes | MC coverage within tolerance. |
| Bootstrap (not in paper) | `R/method_class.R:84-126` | Self-consistent | Package CIs and SDs reproduced to 1e-10 by `boot::boot` with my independent statistic and strata 2S + A, same seed, for perc / basic / norm (`probe3.R`). Stratified on (S, A); w-hat held fixed (F8). |

## 3. Findings (most severe first)

### F1. `ec_aipw()` pairs `outcome_formula` with outcomes by position, not by left-hand side: a different order silently gives a different, wrong answer

- **Location:** `R/ec_aipw.R:118-124` (length check only), `R/ec_aipw.R:206-212` (`Yr <- Y - Y0`, column t of Y minus predictions of formula t), `R/ec_aipw.R:321-323` (meat uses `Yr[, t]` with formula t's design). Paper: Thm 2 / Def 2 define Y-tilde_t = Y_t - mu_t(X) with mu_t = E[Y_t | X, A = 0].
- **Reproducer:** `Rscript n3/probe1.R` (section P2)
  ```
  of <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
  estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", of), ...outcomes = c("y1","y2"))      # tau = -0.5463, 0.5402
  estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", rev(of)), ...outcomes = c("y1","y2")) # tau = -0.1267, 0.1206
  ```
  The proposed test below fails today: point estimates differ by a mean relative difference of 0.61.
- **Expected:** y1 is residualised with the y1 model. The LHS is the outcome name, so either match on it or reject a mismatch. A user who passes `outcome_formula = c("y2 ~ ...", "y1 ~ ...")` has stated unambiguously which model belongs to which outcome.
- **Actual:** y1 gets the y2 model's predictions. The estimate stays consistent through randomization and the PS, but it loses the outcome-model protection and efficiency the user asked for. The sandwich meat uses `(y1 - X beta_2) X`, which is not beta_2's score, so the SE is also wrong. Nothing warns.
- **Category:** implementation bug (input contract). **Severity:** wrong (silent).
- **Proposed regression test** (fails on 6185ba9):
  ```r
  test_that("ec_aipw() matches outcome formulas to outcomes by left-hand side", {
    covs <- c("x1", "x2", "x3", "x4", "x5")
    f <- c("y1 ~ x1 + x2", "y2 ~ x3 + x4 + x5")
    fit <- function(of) {
      estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", of),
        data = SyntheticData, outcomes = c("y1", "y2"), treatment = "A",
        trial_status = "S", covariates = covs
      )
    }
    expect_equal(fit(rev(f)), fit(f))
  })
  ```
  (If the fix is to error on a mismatched LHS instead, replace with `expect_error(fit(rev(f)))`.)

### F2. `ec_ipw()` (w != 0) and `ec_aipw()` error whenever the trial-status column is not literally named `S`

- **Location:** `R/ec_ipw.R:96`, `R/ec_aipw.R:117` rewrite the PS-formula LHS to the *user's* column name (`paste0(trial_status, " ~")`), but `.build_analysis_df()` (`R/method_class.R:129-136`) renames that column to `S`. So `glm()` (`R/ec_weights.R:12`) looks up a column that no longer exists. `?ec_ipw` says "The left-hand side is replaced internally".
- **Reproducer:** `Rscript n3/probe1.R` (P1, P1b)
  ```
  d <- SyntheticData; names(d)[names(d) == "S"] <- "trial"
  estimate(ec_ipw("trial ~ x1 + x2 + x3 + x4 + x5"), data = d, outcomes = c("y1","y2"),
           treatment = "A", trial_status = "trial", covariates = covs)
  #> Error in eval(predvars, data, env) : object 'trial' not found
  ```
  The documented route `setup_analysis_primary(trial_status_col_name = "trial", ...)` + `run_analysis()` gives the same error. `ec_ipw(weight = 0)` works (it skips the PS model), so the failure depends on the weight.
- **Expected:** any valid column name works. `setup_analysis_primary()` takes `trial_status_col_name` precisely so the column can have another name.
- **Actual:** a hard error for every name except `S`. All tests and vignettes use `"S"`, so nothing catches it.
- **Category:** implementation bug. **Severity:** gap (loud failure; no wrong numbers). The same `sub()` pattern is at `R/did_ec_ipw.R:85`, `R/did_ec_aipw.R:99` (out of scope, see §5).
- **Proposed regression test** (fails on 6185ba9):
  ```r
  test_that("ec_ipw() and ec_aipw() accept a trial status column not named S", {
    d <- SyntheticData
    names(d)[names(d) == "S"] <- "trial"
    covs <- c("x1", "x2", "x3", "x4", "x5")
    ref <- estimate(ec_ipw("S ~ x1 + x2 + x3 + x4 + x5"),
      data = SyntheticData, outcomes = "y1", treatment = "A",
      trial_status = "S", covariates = covs
    )
    res <- estimate(ec_ipw("trial ~ x1 + x2 + x3 + x4 + x5"),
      data = d, outcomes = "y1", treatment = "A",
      trial_status = "trial", covariates = covs
    )
    expect_equal(res, ref)
    res_aipw <- estimate(ec_aipw("trial ~ x1 + x2 + x3 + x4 + x5", "y1 ~ x1 + x2"),
      data = d, outcomes = "y1", treatment = "A",
      trial_status = "trial", covariates = covs
    )
    expect_equal(nrow(res_aipw$results), 1L)
  })
  ```

### F3. The variance formula printed in the paper (Eq 13, Eq 16) omits cross-covariances. The code correctly includes them but cites the equations as if it followed them

- **Location:** `R/ec_ipw.R:215,261-272` (comment "Eq 13 for variance"); `R/ec_aipw.R:254,327-337` ("Eq 16"). Paper p. 801 Eq 13 and p. 802 Eq 16: Var = (Sigma11 + (1-w)^2 Sigma22 + w^2 Sigma33)/(n+m).
- **Why the printed formula is incomplete:** tau = mu11 - (1-w) mu10 - w mu00. Its delta-method variance includes -2w Sigma13, -2(1-w) Sigma12 and +2w(1-w) Sigma23. Sigma13 != 0 because mu00 loads on the PS score Psi4 through A^-1, and Psi4 = (S - pi_S(X))X correlates with Psi1. In EC-AIPW all three blocks also share beta. The code applies c' Sigma c with c = (I, -(1-w)I, -wI, 0), which is the correct delta method.
- **Reproducer:** `Rscript n3/compare.R`: SE from the printed formula / package SE on SyntheticData is 0.992-1.005 (IPW) and 0.98-1.10 (AIPW). Monte Carlo (MC-A, 2000 reps; `summarise.R`, columns `se_ratio_eq13_16`, `cover_eq13_16`):

  | N = 1200 | package SE / emp SD | coverage | printed Eq 13/16 SE / emp SD | coverage |
  |---|---|---|---|---|
  | EC-IPW, w = 1, t1 | 1.002 | 0.951 | 1.194 | 0.982 |
  | EC-IPW, w-hat, t1 | 0.999 | 0.950 | 1.065 | 0.962 |
  | EC-AIPW, w-hat, t1 | 1.016 | 0.955 | 1.125 | 0.974 |
  | EC-AIPW, w = 0.5, t1 | 1.014 | 0.955 | 1.124 | 0.974 |

- **Expected:** the code should match a correct asymptotic variance. It does, and the printed equations do not. A "fix" that makes the code follow the printed Eq 13/16 would make every interval conservative (up to 19% wider) and lose power.
- **Category:** documentation error (the code comments, plus a probable erratum in the paper). **Severity:** misleading (for anyone checking the code against the paper, including future agents told to "match the paper"); the numbers are right.
- **Proposed regression test:** lock in the full-covariance form against an independent sandwich. Put `ind_logit`, `ind_ols`, `ind_design`, `ind_ec`, `ind_psi`, `ind_sandwich` from `3-independent-implementation.R` in `tests/testthat/helper-independent-sandwich.R`, then:
  ```r
  test_that("ec_ipw()/ec_aipw() SEs equal an independent finite-difference sandwich", {
    covs <- c("x1", "x2", "x3", "x4", "x5")
    ys <- c("y1", "y2")
    X <- ind_design(SyntheticData, covs)
    for (aipw in c(FALSE, TRUE)) {
      for (w in list(NULL, 0, 0.3, 1)) {
        m <- if (aipw) {
          ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", paste(ys, "~ x1 + x2 + x3 + x4 + x5"), weight = w)
        } else {
          ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", weight = w)
        }
        r <- estimate(m, data = SyntheticData, outcomes = ys, treatment = "A",
          trial_status = "S", covariates = covs)
        f <- ind_ec(SyntheticData, ys, X, X, aipw = aipw, w = w)
        s <- ind_sandwich(f, SyntheticData, ys, X, X, aipw = aipw)
        expect_equal(r$results$point_estimates, unname(f$tau), tolerance = 1e-8)
        expect_equal(r$results$standard_deviation, unname(s$se_full), tolerance = 1e-6)
      }
    }
  })
  ```
  Also amend the comments to say "delta method on the full Sigma (Eq 13 as printed omits the cross-covariance terms)".

### F4. The sandwich allocates N x N matrices: memory grows quadratically

- **Location:** `R/ec_ipw.R:244` and `R/ec_aipw.R:275` (`diag(-pi_SX * (1 - pi_SX))`), `R/ec_aipw.R:302` (`diag((1 - A) / (1 - mean(A)))`).
- **Reproducer:** `Rscript n3/probe_mem.R` (seed 20261006)
  ```
  N= 2000  ec_ipw 0.02s peak 187 MB | ec_aipw 0.14s peak 192 MB | independent 0.06s
  N= 8000  ec_ipw 0.38s peak 656 MB | ec_aipw 1.15s peak 662 MB | independent 0.07s
  N=16000  ec_ipw 1.14s peak 2119 MB | ec_aipw 3.64s peak 2127 MB | independent 0.11s
  ```
- **Expected:** O(N p^2) memory, e.g. `-crossprod(X * (pi_SX * (1 - pi_SX)), X) / N`.
- **Actual:** an N = 40,000 analysis would need about 12 GB per call. Rare-disease trials are small, so this matters mainly for `run_simulation()` with large designs or external databases.
- **Category:** implementation bug (efficiency). **Severity:** polish.
- **Proposed regression test:** the refactor is covered by the independent-sandwich test in F3 (numbers unchanged). Optionally: `expect_no_error(estimate(ec_aipw(...), data = <N = 30000 simulated>, ...))`, which currently needs about 7 GB.

### F5. EC-AIPW's sandwich rebuilds the outcome design from a full-data refit, so data-dependent bases (`ns()`, `bs()`) get a different basis than the point estimate

- **Location:** `R/ec_aipw.R:263-266` (`lm(f, data = df)` on *all* rows; comment "refit outcome models on full data (needed for sandwich, not for tau)"), `R/ec_aipw.R:286` (`model.matrix` of that refit). The point estimate's model is fit on `df[A == 0, ]` (`R/ec_aipw.R:206-208`).
- **Reproducer:** `Rscript n3/probe2.R`
  ```
  outcome_formula "y1 ~ splines::ns(x5, df = 3)", weight 0.4:
  pkg SE 0.5252020, independent SE (basis built on controls, as used for tau) 0.5248116
  ns knots on controls: 39.52 54.04; on all rows: 34.98 49.53
  ```
  With `poly()` and per-time formulas the SEs agree exactly, because `poly()` spans the same space either way.
- **Expected:** the bread and meat use the same design (same basis) as the fitted beta. That design is `model.matrix(terms(fit), model.frame(terms(fit), df))` from the control fit, which keeps its `predvars`.
- **Actual:** a 0.07% SE difference here. The size depends on how far the control and full-data knots differ. The comment says the refit is "needed", which is not true.
- **Category:** implementation bug. **Severity:** polish.
- **Proposed regression test** (fails on 6185ba9 with a difference of 0.00039):
  ```r
  test_that("ec_aipw() sandwich uses the outcome-model basis fitted on controls", {
    covs <- c("x1", "x2", "x3", "x4", "x5")
    ctrl <- SyntheticData$A == 0
    basis <- splines::ns(SyntheticData$x5[ctrl], df = 3)
    d <- SyntheticData
    b <- predict(basis, d$x5)
    d$b1 <- b[, 1]
    d$b2 <- b[, 2]
    d$b3 <- b[, 3]
    fit <- function(of, data, cv) {
      estimate(ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", of, weight = 0.4),
        data = data, outcomes = "y1", treatment = "A",
        trial_status = "S", covariates = cv
      )$results
    }
    ns_fit <- fit("y1 ~ splines::ns(x5, df = 3)", SyntheticData, covs)
    explicit <- fit("y1 ~ b1 + b2 + b3", d, c(covs, "b1", "b2", "b3"))
    expect_equal(ns_fit$point_estimates, explicit$point_estimates, tolerance = 1e-10)
    expect_equal(ns_fit$standard_deviation, explicit$standard_deviation, tolerance = 1e-10)
  })
  ```

### F6. The docs call the `weight = NULL` weight variance-minimizing; Eq 11 is an outcome-free approximation

- **Location:** `vignettes/introduction.Rmd:43` ("data-adaptive weight minimizing variance"); `?ec_ipw` / `?ec_aipw` `@param weight` ("data-adaptive optimal weight", `R/ec_ipw.R:28-29`, `R/ec_aipw.R:32-33`). Paper §3.3 and App. B: Eq 11 approximates Eq 10 assuming bias B = 0 and equal residual variances in trial and external controls, so that it can be computed without outcome data.
- **Reproducer:** `Rscript n3/probe3.R`
  ```
  EC-IPW:  Eq 11 w-hat = 0.148; argmin_w SE per outcome = 0.22, 0.14, 0.35, 0.13; SE at w-hat / min SE = 1.005, 1.000, 1.034, 1.001
  EC-AIPW: Eq 11 w-hat = 0.148; argmin_w SE per outcome = 0.25, 0.13, 0.33, 0.15; SE at w-hat / min SE = 1.010, 1.001, 1.025, 1.000
  ```
  One weight serves every outcome and both methods. It does not account for bias (the paper's MC-B analogue: w-hat = 0.55 with bias 0.28 and coverage 0.33-0.55; see §4).
- **Expected:** the docs say what Eq 11 is: "the variance-ratio weight of Zhou et al. (Eq 11), computed from the PS weights without outcome data. It approximates the variance-minimizing weight when external controls are unbiased, and does not protect against bias."
- **Category:** documentation error. **Severity:** misleading (mild). Users may read "optimal" as protection against non-exchangeable controls.
- **Proposed regression test:** none (documentation). Optionally lock w-hat to the closed form `ESS_ext / (n10 + ESS_ext)` on SyntheticData from an independent computation:
  ```r
  test_that("ec_ipw() optimal weight is Eq 11 (independent closed form)", {
    p <- fitted(glm(S ~ x1 + x2 + x3 + x4 + x5, binomial, SyntheticData))
    w00 <- (p / (1 - p))[SyntheticData$S == 0]
    ess <- sum(w00)^2 / sum(w00^2)
    n10 <- sum(SyntheticData$S == 1 & SyntheticData$A == 0)
    r <- estimate(ec_ipw("S ~ x1 + x2 + x3 + x4 + x5"), data = SyntheticData,
      outcomes = "y1", treatment = "A", trial_status = "S",
      covariates = c("x1", "x2", "x3", "x4", "x5"))
    expect_equal(r$borrow_weight, ess / (n10 + ess), tolerance = 1e-10)
  })
  ```

### F7. Citation label mismatch: code comments call the JRSS-A paper "Zhou 2024a", the vignette calls it "2024b"

- **Location:** `R/ec_ipw.R:157,215`, `R/ec_aipw.R:184,254` ("Zhou 2024a: Def 1 (Eq 6)" etc.) vs `vignettes/introduction.Rmd:37-38` (EC-IPW/EC-AIPW = "Zhou et al. (2024b)") and `:57-60` (DID/SCM = "2024a"). The JRSS-A paper is 2025;188(3) (online 2024); the roxygen says "Zhou et al. (2024)".
- **Reproducer:** `grep -n "2024a\|2024b" R/ec_*.R vignettes/introduction.Rmd`
- **Expected:** one label per paper. Someone checking "Zhou 2024a Eq 13" against the DID paper will find nothing.
- **Category:** documentation error. **Severity:** polish. **Test:** none.

### F8. Sandwich and bootstrap both treat the estimated optimal weight as fixed (design question)

- **Location:** `R/ec_ipw.R:110,129` and `R/ec_aipw.R:135,156` (`borrow_wt = borrow_weight` passed into every bootstrap resample).
- **Paper:** Thm 3/4 hold "for any fixed w"; App. B and §3.3 do not discuss the sampling variability of w-hat. Since tau(w) = mu11 - mu10 - w(mu00 - mu10), the variability of w-hat enters as (w-hat - w-bar)(mu00 - mu10). That is O_p(1/N) when B = 0, so it is negligible. It is O_p(1/sqrt N) when B != 0, but then the CI is invalid anyway because of the bias.
- **Reproducer:** `Rscript n3/probe3b.R`: EC-IPW y1 on SyntheticData, 2000 stratified resamples, bootstrap SD 0.5204 with w fixed vs 0.5211 with w re-estimated in each resample. MC-A coverage at w-hat is 0.950-0.968.
- **Expected/actual:** consistent with the paper; impact negligible under its assumptions. It is still worth one sentence in `?ec_ipw`: "With `weight = NULL` the bootstrap holds the estimated weight fixed."
- **Category:** design question. **Severity:** polish. **Test:** none.

### Checked and not a defect (to save the triager time)
- EC-AIPW at w = 0 fits its outcome model on external controls too. That is by design (#92), and it is consistent with Psi5 of Thm 4, which sums over all subjects with A = 0. MC-B (direct-effect violation): EC-AIPW w = 0 bias +0.012 (MCSE 0.005; t1) and +0.009 (0.005; t2). This is within my 3-MCSE tolerance and matches the small in-sample effect reported in #92's comments.
- `1/(1 - mean(A))` in Psi5 instead of `1/(1 - pi_A)`: a constant scaling that cancels in the sandwich (verified numerically).
- Fixing pi_S and pi_A instead of stacking their estimating equations: exact asymptotically, as in the paper.
- The bootstrap is stratified by (S, A). This is reasonable (it conditions on group sizes) and is reproduced exactly by `boot::boot`.

## 4. Monte Carlo

### 4.1 Pre-registration (written to `n3/preregistration.md` before any MC result was seen; MC-C was added after MC-A N = 300 had been seen, before MC-C was run)

- **DGP MC-A** (Supplement Table 1, Scenario A; unstated details fixed by me): X1, X2 ~ N(0,1); S ~ Bern(expit(log 2 + 0.1 X1 + 0.1 X1^2 + 0.1 X2)) (pi_S about 0.69); in the trial, exactly round(2n/3) treated, complete randomization; A = 0 for external. Y_t(0) = 0.5X1 + 0.5X1^2 + 0.5X2 + e_t, corr(e1, e2) = 0.5, unit variance; Y_t(1) = Y_t(0) + tau_t. **True tau = (1, 2).** Working models PS `S ~ x1 + x1sq + x2` and outcome `y_t ~ x1 + x1sq + x2` (both correct). N in {300, 1200}, **R = 2000** each.
- **Estimators:** EC-IPW and EC-AIPW, w in {0, NULL, 0.5, 1}; sandwich CIs. Bootstrap: percentile, B = 199, R = 400, N = 300, w in {NULL, 0.5}.
- **Tolerances:** |bias| <= 3 MCSE. Sandwich coverage in [0.935, 0.965] at N = 1200 (3 x sqrt(.95 x .05/2000)), >= 0.92 at N = 300. SE ratio (mean SE / emp SD) in [0.95, 1.05] at N = 1200. Bootstrap coverage in [0.917, 0.983]. w = 0 EC-IPW equals the trial difference in means in every rep. Package equals the independent implementation in every rep. Prediction: printed Eq 13/16 miscalibrated for EC-AIPW at w > 0, "fine for EC-IPW".
- **MC-B:** as MC-A, N = 300, R = 1000, trial Y(0) + 0.5 (direct effect of S). Expected bias = +0.5 w (+0.5 mean(w-hat) for Eq 11), 0 at w = 0; PASS within 3 MCSE.
- **MC-C** (double robustness): logit pi_S = 0.5 + 0.5X1 - 0.5X1^2 + 0.3X2, same outcome, N = 1200, R = 1000. (i) PS wrong / outcome right, (ii) PS right / outcome wrong, (iii) both wrong. Expected: EC-AIPW unbiased with coverage in 0.95 +/- 0.021 in (i) and (ii); EC-IPW biased in (i), unbiased in (ii); (iii) report only.

### 4.2 Results (MCSE in parentheses; full tables from `Rscript n3/summarise.R`, `n3/mcC.log`)

**MC-A, sandwich, N = 1200 (R = 2000). PASS on all 16 cells.**

| method | w | t | bias (MCSE) | emp SD | SE ratio | coverage (MCSE) |
|---|---|---|---|---|---|---|
| IPW | 0 | 1 / 2 | 0.0001 (0.0024) / -0.0008 (0.0024) | 0.108 / 0.109 | 0.985 / 0.980 | 0.953 / 0.943 (0.005) |
| IPW | w-hat (mean 0.562) | 1 / 2 | 0.0005 (0.0017) / -0.0002 (0.0017) | 0.077 / 0.078 | 0.999 / 0.991 | 0.950 / 0.951 |
| IPW | 0.5 | 1 / 2 | 0.0003 (0.0018) / -0.0005 (0.0018) | 0.080 / 0.080 | 0.996 / 0.985 | 0.948 / 0.951 |
| IPW | 1 | 1 / 2 | 0.0004 (0.0017) / -0.0003 (0.0018) | 0.078 / 0.079 | 1.002 / 0.984 | 0.951 / 0.959 |
| AIPW | 0 | 1 / 2 | 0.0010 (0.0016) / 0.0000 (0.0017) | 0.073 / 0.075 | 1.009 / 0.986 | 0.952 / 0.942 |
| AIPW | w-hat | 1 / 2 | 0.0002 (0.0013) / -0.0005 (0.0013) | 0.057 / 0.058 | 1.016 / 1.004 | 0.955 / 0.954 |
| AIPW | 0.5 | 1 / 2 | 0.0003 (0.0013) / -0.0005 (0.0013) | 0.058 / 0.059 | 1.014 / 0.999 | 0.955 / 0.954 |
| AIPW | 1 | 1 / 2 | -0.0004 (0.0015) / -0.0010 (0.0015) | 0.067 / 0.066 | 1.019 / 1.029 | 0.959 / 0.954 |

**MC-A, sandwich, N = 300 (R = 2000). PASS.** Coverage ranges 0.941-0.957 (all >= 0.92); max |bias|/MCSE = 1.96 (IPW w = 0, t2: -0.0094 (0.0048)); SE ratio 0.972-1.016.
In both MC-A runs, package and independent implementation agreed in every replicate: max |d tau| 9e-8, max relative d SE 1.7e-7. The tolerance comes from my Newton-Raphson stopping rule vs `glm()`'s. EC-IPW w = 0 equalled the trial difference in means exactly in all 4000 reps.

**Printed Eq 13/16 (diagonal blocks only), same reps:** SE ratio 1.03-1.19 (IPW, w > 0) and 1.02-1.13 (AIPW, w > 0); coverage 0.955-0.984. My pre-registered prediction "fine for EC-IPW" was **wrong**: the printed formula is conservative for both methods (F3).

**Bootstrap (percentile, B = 199), N = 300, R = 400. PASS.** Coverage (MCSE 0.010-0.012): IPW w-hat 0.948 / 0.955, IPW 0.5 0.940 / 0.940, AIPW w-hat 0.943 / 0.948, AIPW 0.5 0.940 / 0.955. Bias within 1.2 MCSE throughout. Mean bootstrap SD / empirical SD is 0.88-1.01; the lower values (IPW w = 0.5) come from one extreme-weight replicate (tau = -0.39, SE 0.89; robust SD 0.178 vs SD 0.182). Not pre-registered as a criterion.

**MC-B (direct effect 0.5), N = 300, R = 1000. PASS.** Bias / expected 0.5 w-bar, with z = (bias - expected)/MCSE:

| | w = 0 | w = 0.5 | w-hat (0.551) | w = 1 |
|---|---|---|---|---|
| IPW t1 | 0.005 / 0 (z 0.7) | 0.260 / 0.25 (1.9) | 0.286 / 0.276 (2.2) | 0.514 / 0.5 (2.7) |
| AIPW t1 | 0.012 / 0 (2.6) | 0.259 / 0.25 (2.3) | 0.284 / 0.276 (2.3) | 0.505 / 0.5 (1.1) |

All |z| <= 2.73 (t2 smaller). Sandwich coverage collapses with w as expected (AIPW: 0.94 at w = 0, 0.33 at w-hat, 0.05 at w = 1). This reproduces the shape of Supplement Fig 1B (bias linear in w, reaching 0.5 at w = 1).

**MC-C (double robustness), N = 1200, R = 1000. PASS.**
- (i) PS wrong / outcome right: AIPW bias -0.0009 to -0.0020 (MCSE 0.002, |z| <= 1.0), coverage 0.949-0.956; IPW bias -0.26 (w = 0.5) and -0.35 (w-hat), coverage 0.02-0.19, so the design does detect PS misspecification.
- (ii) PS right / outcome wrong: AIPW |z| <= 0.6, coverage 0.943-0.957; IPW |z| <= 0.7, coverage 0.948-0.955.
- (iii) both wrong: AIPW bias -0.22 (w = 0.5), -0.30 (w-hat).

### 4.3 Paper §5 / §6 reproduction
- **§6 (SUNFISH):** not attempted. It needs SUNFISH/olesoxime patient-level data, which is not available and is excluded by the synthetic-data rule.
- **§5:** not reproducible numerically. The DGP coefficients were "learned from the real data" and are not published.
- **Qualitative:** Supplement Fig 1 Scenarios A and B are reproduced. A: SE is U-shaped in w with its minimum near w = 0.5 (my AIPW emp SD at N = 300: 0.147 at w = 0, 0.116 at 0.5, 0.135 at 1; paper about 0.14 / 0.12 / 0.14); EC-AIPW <= EC-IPW; no bias. B: bias = 0.5w.

## 5. Unexecuted suspicions
- **Same LHS-rename bug in the OLE methods (out of scope):** `R/did_ec_ipw.R:85,88` and `R/did_ec_aipw.R:99,102` use the same `sub("^[^~]*~", paste0(trial_status, " ~"), ...)` (and the same for `treatment`). If those methods also build their data frame with renamed `S`/`A` columns, they will fail like F2. Not run.
- **Factor covariates with a level absent among controls (EC-AIPW):** the control fit gives an NA coefficient, while the full-data refit (F5) gives a column whose Y0_gamma block is all zero, so `solve(A_mat)` should fail or be singular. Not run (role 2 territory).
- **Variance of w-hat under bias:** I argued the term is O_p(1/sqrt N) * B but did not measure its contribution separately from the bias itself.
