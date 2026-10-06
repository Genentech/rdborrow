# Adversarial-input and property tester: pilot report

- **Role:** 2, adversarial-input and property tester (issue #101).
- **Scope:** `ec_ipw()`, `ec_aipw()`, `setup_analysis_primary()`, `run_analysis()`, `.build_analysis_df()`, `.ec_weights()`, `.ec_ipw_core()`, `.ec_ipw_se()`, `.ec_aipw_core()`, `.ec_aipw_se()`, both bootstrap statistics, and `.run_bootstrap()`.
- **Commit:** `6185ba9` (package version 0.0.4.2), worktree `agent-ad99b4e28fccdd97f`.
- **R:** 4.6.1 (2026-06-24), Linux.
- **Loading:** every finding was run against the installed copy (`.libPaths(c(".../scratchpad/review-lib", .libPaths())); library(rdborrow)`), and the consolidated reproducer was also run under `devtools::load_all()`. The two outputs are identical apart from the banner line (`repro_installed.txt` and `repro_dev.txt`). Finding 8 was also rerun under `load_all()`, with the same counts.
- **Data:** `SyntheticData` and `simulate_trial()` only. Seeds are set inline in each script.
- **Scripts and raw output:** `.../scratchpad/review-pilot/r2/` (`h.R` is the shared helper, `t01`–`t16` are the probes, `repro_all.R` is the consolidated reproducer). Each finding is run with `Rscript <script>`.

The helper used below:

```r
cov5 <- c("x1", "x2", "x3", "x4", "x5")
ps5  <- "S ~ x1 + x2 + x3 + x4 + x5"
of5  <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
ra <- function(m, data = SyntheticData, S = "S", A = "A", y = c("y1", "y2"), x = cov5, alpha = 0.05)
  run_analysis(setup_analysis_primary(data, S, A, y, x, m, alpha = alpha))
```

---

## Findings (most severe first)

### 1. `ec_aipw()` pairs outcome formulas with outcomes by position and ignores their left-hand side, so a reordered outcome list gives silently wrong estimates

- **Location:** `R/ec_aipw.R:206-212` (`Y0` column `t` is predicted from `outcome_formula[t]` and subtracted from `Y[, t]`). `R/ec_aipw.R:118` checks only that the lengths match. The sandwich's Psi_5 block (`R/ec_aipw.R:321-323`) uses the same mismatched residuals. Paper: Theorem 2 and Definition 2, with Y~ = Y - mu(X), mu(X) = E[Y | X, A = 0] for each time point. The Psi_5 estimating equation is in Theorem 4.
- **Reproducer** (`repro_all.R`, section F1):
  ```r
  ra(ec_aipw(ps5, of5))                         # y = (y1, y2)
  ra(ec_aipw(ps5, of5), y = c("y2", "y1"))      # formulas still (y1, y2)
  ra(ec_aipw(ps5, rev(of5)), y = c("y2", "y1"))
  ```
  ```
  aipw y=(y1,y2), f=(y1,y2)   tau = -0.546326,  0.540175 | se = 0.5306, 0.5543
  aipw y=(y2,y1), f=(y1,y2)   tau =  0.120592, -0.126743 | se = 0.5532, 0.5516
  aipw y=(y2,y1), f=(y2,y1)   tau =  0.540175, -0.546326 | se = 0.5543, 0.5306
  ```
- **Expected:** the y2 effect is 0.540 whichever order the outcomes are listed in. Each formula names its outcome on the left-hand side, and Definition 2 residualizes each Y_t by its own model mu_t(X). The package should either match formulas to outcomes by their left-hand side, or reject a formula whose left-hand side is not the corresponding outcome.
- **Actual:** with the order mismatched, y2 is residualized with the y1 model and vice versa. The run returns plausible-looking numbers (0.121 instead of 0.540, and -0.127 instead of -0.546) with no warning. The sandwich SE is also invalid in that case, because Psi_5 is evaluated at residuals that are not the fitted model's residuals.
- **Category:** implementation bug (the docs show a matched example, `c("y1 ~ ...", "y2 ~ ...")`, but never say the order must follow `outcome_col_name`).
- **Severity:** wrong (silent).
- **Proposed regression test** (`tests/testthat/test-ec_aipw.R`):
  ```r
  test_that("ec_aipw() matches outcome formulas to outcomes by name", {
    m <- ec_aipw(
      "S ~ x1 + x2 + x3 + x4 + x5",
      c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
    )
    fit <- function(y) {
      run_analysis(setup_analysis_primary(
        SyntheticData, "S", "A", y, paste0("x", 1:5), m
      ))$results$point_estimates
    }
    expect_equal(fit(c("y2", "y1")), rev(fit(c("y1", "y2"))))
  })
  ```
  If the chosen contract is to reject instead: `expect_error(fit(c("y2", "y1")), "outcome_formula")`.

### 2. External controls with `A = 1` are accepted and silently averaged into the external control mean

- **Location:** `R/analysis_class.R:61-71` validates only that S and A are 0/1, never the S x A combination. `R/ec_ipw.R:182-183` and `R/ec_aipw.R:217-222` take every `S == 0` row as an external control, whatever its `A`. Paper Section 2.1: external controls are "sampled from a distribution P_E(X, A = 0, Y(0))".
- **Reproducer** (`repro_all.R`, section F2; `t05_groups.R`):
  ```r
  d <- SyntheticData; ext <- which(d$S == 0)
  d$A[ext[1:10]] <- 1; d$y1[ext[1:10]] <- d$y1[ext[1:10]] + 50
  ra(ec_ipw(ps5, weight = 1), d)
  ra(ec_ipw(ps5, weight = 1), d[-ext[1:10], ])
  ```
  ```
  ipw w=1, 10 externals A=1 (y1 + 50)   tau = -3.21635,  0.81717 | se = 1.509, 1.060
  ipw w=1, those 10 rows dropped        tau = -1.159938, 0.831593 | se = 0.7982, 1.1610
  ```
  At the optimal weight, tau1 moves from -0.197 to -0.498 (`t05_groups.R`), and `ec_aipw()` moves similarly (-0.546 to -0.850).
- **Expected:** an error, because the estimator is undefined for treated external subjects (treated outcomes would contaminate mu00_hat).
- **Actual:** treated external subjects are included in mu00_hat, in the sandwich, and in a fourth bootstrap stratum, with no message.
- **Category:** implementation bug (missing input validation).
- **Severity:** wrong (silent).
- **Proposed regression test** (`tests/testthat/test-analysis_primary_class.R`):
  ```r
  test_that("setup_analysis_primary() rejects external controls with A = 1", {
    d <- SyntheticData
    d$A[which(d$S == 0)[1]] <- 1
    expect_error(
      setup_analysis_primary(
        d, "S", "A", c("y1", "y2"), paste0("x", 1:5),
        ec_ipw("S ~ x1 + x2 + x3 + x4 + x5")
      ),
      "external"
    )
  })
  ```

### 3. Name clashes with internal columns: a covariate named `A` or `S`, or a formula variable missing from the internal data, is silently resolved to the wrong object

- **Location:** `R/method_class.R:132-135`. `.build_analysis_df()` builds `data.frame(Y, S = ..., A = ..., data[, covariates])` with `check.names = TRUE`, so a user column called `A` or `S` is renamed `A.1` or `S.1`. Formulas are then evaluated against this internal frame (`R/ec_weights.R:12`, `R/ec_aipw.R:207`). A name that is absent from it falls through to the formula environment (the package frames, then the global environment).
- **Reproducer** (`repro_all.R`, section F4; `t13_collisions.R`; `t03_formulas.R`):
  ```r
  set.seed(21)
  d <- SyntheticData; names(d)[names(d) == "A"] <- "trt"; d$A <- rnorm(nrow(d), 50, 10)
  ra(ec_ipw("S ~ x1 + A"), d, A = "trt", x = c("x1", "A"))
  d2 <- d; names(d2)[names(d2) == "A"] <- "age"
  ra(ec_ipw("S ~ x1 + age"), d2, A = "trt", x = c("x1", "age"))
  ```
  ```
  internal df names: y1 y2 S A x1 A.1
  ipw covariate named 'A', treatment 'trt'  tau = -0.0808949, 0.4208844 | w = 0.4742
  ipw same covariate named 'age'            tau = -0.176841,  0.436313  | w = 0.4927
  ```
  The participation model silently used the treatment indicator in place of the covariate. A related case (`t03_formulas.R`): leave `x5` out of `covariates_col_name` while keeping it in `ps_formula`, with a vector `x5 <- rev(SyntheticData$x5)` in the global environment. The run succeeds with borrow weight 0.421 instead of 0.148, using the unrelated global vector. Without the global, the same call errors with `object 'x5' not found`. An outcome column named `S` with `weight = 0` returns `NaN` estimates with SE `0` (`t13_collisions.R`).
- **Expected:** a formula refers to the user's columns by the user's names. A covariate that clashes with an internal name, or a formula variable that is not in `covariates_col_name`, is an error.
- **Actual:** silently wrong models.
- **Category:** implementation bug.
- **Severity:** wrong (silent), though it needs an unlucky column name.
- **Proposed regression test** (`tests/testthat/test-method_class.R` or `test-ec_ipw.R`):
  ```r
  test_that("a covariate named A is not confused with the treatment", {
    set.seed(1)
    d <- SyntheticData
    names(d)[names(d) == "A"] <- "trt"
    d$A <- rnorm(nrow(d))
    d2 <- d
    names(d2)[names(d2) == "A"] <- "age"
    fit <- function(data, f, x) {
      run_analysis(setup_analysis_primary(
        data, "S", "trt", c("y1", "y2"), x, ec_ipw(f)
      ))$results
    }
    expect_equal(
      fit(d, "S ~ x1 + A", c("x1", "A")),
      fit(d2, "S ~ x1 + age", c("x1", "age"))
    )
  })
  ```
  For the scoping case, a formula variable outside `covariates_col_name` should error even when a global object of that name exists: `expect_error(..., "x5")`.

### 4. A trial-status column not named `S` breaks both methods (and silently uses a same-named global vector if one exists)

- **Location:** `R/ec_ipw.R:96` and `R/ec_aipw.R:117` rewrite the formula's left-hand side to the user's column name (`paste0(trial_status, " ~")`), but `.build_analysis_df()` (`R/method_class.R:133`) stores that column as `S`. The developer article `vignettes/articles/adding-a-method.Rmd:84` states the intended behavior: "`ec_ipw()` replaces the left-hand side of `ps_formula` with `S`." The same rewrite is in `R/did_ec_ipw.R:85` and `R/did_ec_aipw.R:99` (out of scope, not run). Related to #83, which describes the rewrite but not this failure.
- **Reproducer** (`t01_rename.R`, `t02_rename_global.R`, `repro_all.R` section F3):
  ```r
  d <- SyntheticData; names(d)[names(d) == "S"] <- "trial"
  ra(ec_ipw(ps5), d, S = "trial")
  ra(ec_aipw(ps5, of5), d, S = "trial")
  set.seed(2); d_shuf <- d[sample(nrow(d)), ]; trial <- d$trial
  ra(ec_ipw(ps5), d_shuf, S = "trial")
  ```
  ```
  ipw S col 'trial'                                     ERROR: object 'trial' not found
  aipw S col 'trial'                                    ERROR: object 'trial' not found
  ipw S col 'trial' + global `trial` (other row order)  tau = -0.212912, 0.403008 | w = 0.4857
  ```
  The correct values on these data are tau = -0.197197, 0.469721 and w = 0.1475. Renaming only the treatment column works, and so does `ec_ipw(weight = 0)`, which skips the participation model. No test or vignette uses a trial-status name other than `S`.
- **Expected:** renaming columns, with the matching arguments, leaves results unchanged. `trial_status_col_name` exists precisely so users can supply their own name.
- **Actual:** an error for every user whose column isn't called `S`. If a vector with that name exists in the global environment, it is silently used as the response.
- **Category:** implementation bug (the code contradicts the developer article).
- **Severity:** gap (blocks use). Wrong in the global-shadow variant.
- **Proposed regression test** (`tests/testthat/test-ec_ipw.R` and `test-ec_aipw.R`):
  ```r
  test_that("ec_ipw() and ec_aipw() accept any trial status column name", {
    d <- SyntheticData
    names(d)[names(d) == "S"] <- "trial"
    o <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
    for (m in list(ec_ipw("trial ~ x1 + x2 + x3 + x4 + x5"),
                   ec_aipw("trial ~ x1 + x2 + x3 + x4 + x5", o))) {
      fit <- function(data, s) {
        run_analysis(setup_analysis_primary(
          data, s, "A", c("y1", "y2"), paste0("x", 1:5), m
        ))
      }
      expect_equal(fit(d, "trial"), fit(SyntheticData, "S"))
    }
  })
  ```

### 5. `ps_formula = "S ~ ."` silently puts the outcomes and the treatment into the participation model

- **Location:** `R/ec_weights.R:12` fits `glm(..., data = df)`, where `df` (`R/method_class.R:132`) holds the outcomes, `S`, `A` and the covariates. Paper Theorem 1: pi_S(X) = Pr(S = 1 | X), with X the baseline covariates. `?setup_analysis_primary` documents `covariates_col_name` as "covariate column names".
- **Reproducer** (`t04_dot_and_missing.R`; `repro_all.R` section F5):
  ```
  S ~ . expands to: S ~ y1 + y2 + A + x1 + x2 + x3 + x4 + x5
  ipw 'S ~ .'                 tau = 0.0357054, 0.4028027 | w = 0.1429
  ipw 'S ~ x1 + ... + x5'     tau = -0.197197, 0.469721  | w = 0.1475
  ```
  There is no warning. `"y1 ~ ."` in `ec_aipw()` includes `y2`, `S` and `A`, and fails with a LAPACK singular error.
- **Expected:** `.` means the declared covariates, or it is rejected. Post-treatment outcomes and the treatment must never enter pi_S(X).
- **Actual:** a silently different, invalid participation model.
- **Category:** design question (what `.` should mean), plus a documentation gap.
- **Severity:** wrong (silent) for a natural formula.
- **Proposed regression test:**
  ```r
  test_that("'S ~ .' uses only the declared covariates", {
    fit <- function(f) {
      run_analysis(setup_analysis_primary(
        SyntheticData, "S", "A", c("y1", "y2"), paste0("x", 1:5), ec_ipw(f)
      ))$results
    }
    expect_equal(fit("S ~ ."), fit("S ~ x1 + x2 + x3 + x4 + x5"))
  })
  ```
  If `.` is to be rejected instead: `expect_error(fit("S ~ ."))`.

### 6. Missing values give silent `NA` estimates, cryptic errors, or an `NA` estimate next to a finite bootstrap CI

- **Location:** `R/analysis_class.R:44-72` has no missingness check for outcomes or covariates. `R/ec_ipw.R:162-163` and `183` use `colMeans()` and `colSums()` without handling `NA`. `R/ec_ipw.R:255-258` and `R/ec_aipw.R:315-325` mix the `na.omit` design matrices from `glm()`/`lm()` (N - k rows) with length-N vectors. `.run_bootstrap()` (`R/method_class.R:114-123`) passes `NA` replicates to `boot.ci()`, which drops non-finite values, while `sd_boot` becomes `NA`. The paper does not cover missing data. `vignettes/primary_analysis_workflow.Rmd:169` tells users to supply complete data.
- **Reproducer** (`t04_dot_and_missing.R`; `repro_all.R` section F6):
  ```
  ipw NA in one trial-control y1      tau = NA, 0.469721 | se = NA, NA
  ipw + bootstrap (seed 1, B = 50):   tau1 = NA  sd1 = NA  CI1 = [ -1.060079 , 0.4177658 ]
  aipw NA in one trial-control y1     ERROR: non-conformable arguments
  ipw NA in one external x5           ERROR: missing value where TRUE/FALSE needed
  ipw w=0.5 NA in one external x5     ERROR: non-conformable arguments
  ```
  `NA` in S or A is rejected cleanly ("must contain only 0 and 1").
- **Expected:** a clear error naming the column with missing values, as AGENTS.md asks (validate exported-function inputs with checkmate).
- **Actual:** depending on where the `NA` sits, the result is a partially `NA` table, an internal linear-algebra error, or a misleading bootstrap result. In that last case, the CI is computed only from replicates that happened not to draw the missing subject, so it is conditioned on excluding that subject.
- **Category:** implementation bug (missing validation). The behavior is documented only in a vignette note.
- **Severity:** misleading (bootstrap case). Gap otherwise.
- **Proposed regression test** (`tests/testthat/test-analysis_primary_class.R`):
  ```r
  test_that("setup_analysis_primary() rejects missing outcomes and covariates", {
    m <- ec_ipw("S ~ x1 + x2 + x3 + x4 + x5")
    d <- SyntheticData
    d$y1[1] <- NA
    expect_error(
      setup_analysis_primary(d, "S", "A", c("y1", "y2"), paste0("x", 1:5), m),
      "y1"
    )
    d <- SyntheticData
    d$x5[300] <- NA
    expect_error(
      setup_analysis_primary(d, "S", "A", c("y1", "y2"), paste0("x", 1:5), m),
      "x5"
    )
  })
  ```

### 7. Empty arms return `NaN` results without an error

- **Location:** `R/ec_ipw.R:159-163` and `R/ec_aipw.R:189-222` (`colMeans()` of zero-row matrices; `pi_A` equal to 0 or 1). No check in `R/analysis_class.R`. Paper Section 2.1 assumes n1, n0, m > 0, and W10 = 1/(1 - pi_A) requires pi_A < 1.
- **Reproducer** (`t05_groups.R`; `repro_all.R` section F7):
  ```
  aipw, no external controls      tau = NaN, NaN | se = NaN, NaN | w = NaN
  ipw, no trial treated           tau = NaN, NaN | se = NaN, NaN | w = 0.1499
  ipw w=1, no trial controls      tau = NaN, NaN | se = NaN, NaN | w = 1.0000
  ipw (optimal), no externals     ERROR: missing value where TRUE/FALSE needed
  ```
  A single trial control or a single external control still runs, which is acceptable.
- **Expected:** an informative error when the trial treated, trial control or external group is empty. `ec_ipw(weight = 0)` without externals is the one legitimate exception, and it works.
- **Category:** implementation bug (missing validation).
- **Severity:** gap.
- **Proposed regression test:**
  ```r
  test_that("empty arms are rejected", {
    d <- SyntheticData[!(SyntheticData$S == 1 & SyntheticData$A == 1), ]
    expect_error(run_analysis(setup_analysis_primary(
      d, "S", "A", c("y1", "y2"), paste0("x", 1:5),
      ec_ipw("S ~ x1 + x2 + x3 + x4 + x5")
    )))
  })
  ```

### 8. New evidence for #86: EC-AIPW's bootstrap has the same non-estimable-prediction problem

- **Location:** `R/ec_aipw.R:206-211`, reached through `.ec_aipw_boot_statistic()` (`R/ec_aipw.R:350-355`) and `.run_bootstrap()`. #86 asked whether the primary estimators should be audited. EC-IPW showed no warnings on the same data.
- **Reproducer** (`t08_boot_rankdef.R`, seeds 11-13; same counts under the installed package and `load_all()`). A binary covariate `z` is 1 for one external control, one trial control and 10 treated subjects, with outcomes shifted by `3 * z`. `ps = "S ~ x5 + z"`, outcome formulas `"y_t ~ x5 + z"`, and `weight = 0.5`. I drew stratified resamples by hand and called `.ec_aipw_boot_statistic()` directly:
  ```
  EC-AIPW replicates with rank-deficient prediction warnings: 52 of 400
  mean tau1 (warned replicates): -0.722  (clean): -1.437
  through run_analysis(bootstrap = 200): warnings emitted: 54
  EC-IPW same data, bootstrap = 200:     warnings emitted: 0
  ```
  The expected rate is 0.99^100 x 0.99^100 = 13.4% (both controls with z = 1 left out of their strata); the observed rate is 52 of 400 = 13.0%. In those replicates the z coefficient is `NA`, and predictions treat it as 0. Their tau sits about 0.7 away from the clean replicates, and they flow into the reported CI.
- **Expected and policy:** as in #86, still open.
- **Category:** method or implementation limitation (#86).
- **Severity:** misleading (warned, not silent).
- **Proposed regression test:** depends on the policy #86 adopts. Whatever is chosen, a replicate whose outcome model is rank-deficient must not silently contribute a finite tau:
  ```r
  test_that("EC-AIPW bootstrap statistic flags non-estimable predictions", {
    # sketch: build df with z as in t08_boot_rankdef.R (helper file), then
    # pass indices that exclude both control rows with z = 1
    expect_error(.ec_aipw_boot_statistic(df, idx, c("y1", "y2"), ps, of, 0.5))
  })
  ```

### 9. Aliased or collinear covariates give a valid point estimate but a cryptic LAPACK error from the sandwich, even when that block carries zero weight

- **Location:** `R/ec_ipw.R:237` and `R/ec_aipw.R:260` take `model.matrix(core$ps_model)`, including columns that `glm()` aliased (coefficient `NA`). That makes `A44` singular, and `solve()` fails (`R/ec_ipw.R:262`, `R/ec_aipw.R:328`). The same applies to the outcome-model blocks. At `weight = 0`, `.ec_aipw_se()` still inverts the participation block, although that block has no effect on tau.
- **Reproducer** (`t07_covariates.R`, `t16_misc.R`, `repro_all.R` section F8):
  ```
  ipw S ~ x5 + x6 (x6 = 2*x5)   ERROR: Lapack routine dgesv: system is exactly singular: U[9,9] = 0
  ipw S ~ x5                    tau = -0.229049, 0.370705 | se = 0.5194, 0.5546
  core tau with aliased x6:     -0.229049 0.3707047     (point estimate is fine)
  constant covariate 'const':   ERROR: Lapack routine dgesv: system is exactly singular
  aipw weight = 0, x5 completely separating S:
                                ERROR: system is computationally singular (tau needs no PS model at w = 0)
  aipw weight = 0, "S ~ 1", same data:  tau = -0.0264, 0.4100 (runs)
  ```
- **Expected:** aliasing doesn't change the fitted pi_S(X), so the SE should equal that of the reduced model (drop the aliased columns, `!is.na(coef(fit))`), or the error should name the aliased term. At w = 0, the w-weighted blocks should not be able to block inference.
- **Category:** implementation bug.
- **Severity:** gap.
- **Proposed regression test:**
  ```r
  test_that("aliased PS terms do not break the sandwich", {
    d <- SyntheticData
    d$x6 <- 2 * d$x5
    fit <- function(f) {
      run_analysis(setup_analysis_primary(
        d, "S", "A", c("y1", "y2"), c("x5", "x6"), ec_ipw(f)
      ))$results
    }
    expect_equal(fit("S ~ x5 + x6"), fit("S ~ x5"))
  })
  ```

### 10. EC-AIPW's sandwich fails when a covariate is large in magnitude, although the variance does not depend on covariate scale

- **Location:** `R/ec_aipw.R:328` (`solve(A_mat)` on an unscaled bread matrix). Rescaling a covariate is an affine reparametrization of beta and alpha. The target's sandwich variance is invariant to it (Theorems 3 and 4).
- **Reproducer** (`t10_scaling.R`; `repro_all.R` section F9):
  ```
  x5 * 1e4  : ok, max diff vs baseline 1.33e-15
  x5 * 1e5  : ERROR system is computationally singular: reciprocal condition number = 9.68e-17
  rcond(A_mat): 7.4e-07 at x5 * 1, 9.7e-13 at x5 * 1000
  ec_ipw at x5 * 1e5: ok, identical to baseline
  "1000 * x5 + 50, x4 / 1e4": ec_aipw errors, ec_ipw identical
  ```
  `SyntheticData$x5` ranges from 8 to 84. Values around 1e6 are plausible in raw units (for example, counts per mL, or income).
- **Expected:** results identical to the baseline, as `ec_ipw()` gives.
- **Fix direction:** solve with a scaled or QR-based method, or standardize the design matrices internally.
- **Category:** implementation bug (numerical).
- **Severity:** gap.
- **Proposed regression test:**
  ```r
  test_that("ec_aipw() is invariant to covariate scale", {
    o <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
    fit <- function(d) {
      run_analysis(setup_analysis_primary(
        d, "S", "A", c("y1", "y2"), paste0("x", 1:5),
        ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", o)
      ))$results
    }
    d <- SyntheticData
    d$x5 <- d$x5 * 1e5
    expect_equal(fit(d), fit(SyntheticData))
  })
  ```

### 11. Both sandwiches allocate N x N matrices, so memory grows as 8·N² bytes

- **Location:** `R/ec_ipw.R:244` and `R/ec_aipw.R:275` (`diag(-pi_SX * (1 - pi_SX))`), and `R/ec_aipw.R:302` (`diag((1 - A) / (1 - mean(A)))`, once per time point). Paper Section 2.1: "The available external control sample size m could potentially be large."
- **Reproducer** (`t11_large_n.R`, seed 2026):
  ```
  N = 1200: ipw 0.0 s, 169 MB | aipw 0.1 s, 187 MB
  N = 4200: ipw 0.4 s, 290 MB | aipw 1.1 s, 303 MB
  N = 8200: ipw 1.7 s, 670 MB | aipw 2.4 s, 685 MB
  ```
  Extrapolating, a registry of 30,000 external controls needs about 7 GB for one `diag()`.
- **Expected:** `crossprod(X * w, X)` gives the same matrix in O(N p²).
- **Category:** implementation (efficiency).
- **Severity:** polish (gap for large registries).
- **Proposed regression test:** none needed for the numbers, since the full-pipeline tests already lock them. Optionally `expect_lt(as.numeric(bench::mark(...)$mem_alloc), ...)` at N = 5000.

### 12. Smaller contract gaps (each executed, `t06_types.R`, `t15_boot_alpha.R`, `t03_formulas.R`)

Each of these is polish:

- **Factor or character S/A pass validation, then fail cryptically.** `factor(S)` passes the `%in% c(0, 1)` check (`R/analysis_class.R:62`) and then fails with "'sum' not meaningful for factors"; a character column fails with "invalid 'type' (character)". Logical and integer columns work and give identical results.
  Test: `expect_error(setup_analysis_primary(<S as factor>, ...), "numeric")`.
- **`bootstrap = 2` is accepted (`R/ec_ipw.R:70`) but gives nonsense.** The percentile CI for tau1 is [-0.100, 0.269], which excludes the point estimate -0.197. With `bca` it errors ("estimated adjustment 'w' is infinite").
- **`alpha` is accepted at 0 and at 1** (`R/analysis_class.R:52`). That gives infinite or zero-width normal CIs, and an `NA` upper bootstrap bound at alpha = 0. The bounds should be open: `(0, 1)`.
- **`bootstrap_ci_type` without `bootstrap` is silently ignored.**
- **An outcome formula with no left-hand side** (`"~ x1 + ..."`) fails with "incompatible dimensions".

---

## Properties tested

All of these held on `SyntheticData`, for seven method configurations: EC-IPW at the optimal weight and at w = 0, 0.3 and 1, and EC-AIPW at the optimal weight and at w = 0 and 1 (`t09_properties.R`). Rows 1, 3, 4, 5, 8, 9 and 11, plus "SE finite and positive", were also checked with quickcheck on 60 random `simulate_trial()` datasets each, with trial sizes 8-60, external sizes 5-80, treated fraction 0.3-0.8, covariate shift ±1 and random w (`t14_quickcheck.R`). All held. Tolerance was 1e-8, and observed differences were at most about 1e-13.

| # | Property | Why it should hold | Held? |
|---|---|---|---|
| 1 | Row permutation leaves estimates, SEs and w unchanged | Definitions 1 and 2 and Eq. 11 are sums over subjects, and the GLM/LM MLEs are order-free | Yes (≤4e-15) |
| 2 | Renaming the outcome, covariate and treatment columns, with the matching arguments | `*_col_name` arguments exist for this | Yes for outcomes, covariates and treatment. **No for trial status (finding 4)**, and not for names clashing with `S`/`A` (finding 3) |
| 3 | Y + c leaves tau and SE unchanged | Hajek means are location-equivariant, so differences cancel; influence functions are centered; the LM has an intercept | Yes (≤1.4e-13 at c = 1000) |
| 4 | c·Y gives c·tau and \|c\|·SE, and CIs swap when c < 0 | Linearity of Definitions 1 and 2; Eq. 11 is outcome-free | Yes for c = -2.5, 1e6, 1e-6 |
| 5 | EC-IPW at w = 0 ignores external outcomes, covariates and rows | Paper p. 796: at w = 0 it "reduces to the ... Hajek estimator using only the trial data" | Yes (exactly 0 difference). EC-AIPW at w = 0 changes, as expected by design (#92) |
| 6 | EC-IPW at w = 1 ignores trial-control outcomes (tau and SE) | (1 - w)·mu10 = 0, and the Psi_2 block has zero coefficient and no cross-terms | Yes |
| 7 | The `ps_formula` left-hand side is ignored | `?ec_ipw`: "The left-hand side is replaced internally" | Yes (`"anything ~"` and `"~ x..."` match `"S ~"`). It is **not** replaced with `S`, as the developer article says (finding 4) |
| 8 | The optimal weight is outcome-free and identical for IPW and AIPW | Eq. 11 is "estimable without any outcome data" and uses the same W00 and W10 | Yes |
| 9 | Duplicating every row leaves tau and w unchanged and divides SE by √2 | Estimators are functionals of the empirical distribution; Eq. 11's two ratios both halve; Var = Σ/N | Yes |
| 10 | EC-IPW's SE is continuous as w → 0 (the code switches sandwich branch at 0) | The Theorem 3 variance is continuous in w | Yes (relative difference 5e-9 at w = 1e-8) |
| 11 | tau(w) is affine in w | Common structure tau = mu11 - [(1 - w)·mu10 + w·mu00], with nuisances independent of w | Yes for IPW and AIPW |
| 12 | A run at the optimal weight equals a fixed-weight run at w_hat | Theorem 3 treats w as fixed | Yes (exactly) |
| 13 | Adding δ to trial-treated outcomes gives tau + δ with SE unchanged (all 7 configurations); adding c to external outcomes gives EC-IPW tau - w·c | Linearity; the AIPW outcome model is fit on A = 0 only | Yes |
| 14 | An affine rescale of a covariate leaves everything unchanged | Logistic and linear fitted values are invariant; the sandwich is invariant to reparametrizing nuisance parameters | EC-IPW yes. **EC-AIPW errors at large scale (finding 10)** |
| 15 | A factor covariate equals the equivalent dummies, and a character covariate equals the factor | Same design matrix | Yes (0 difference) |
| 16 | Integer outcomes equal double outcomes; tibble input equals data.frame input | Type-only change | Yes |
| 17 | Reordering outcomes with their formulas permutes the results | Each tau_t depends only on Y_t | Yes when formulas are reordered too. **No when only the outcomes are reordered (finding 1)** |

---

## Unexecuted suspicions

- **Bootstrap with a shadowing global vector (findings 3 and 4).** If a formula variable resolves to a global vector, `boot()` resamples `df` but not that vector, so the replicates pair covariates with the wrong subjects. In my one run (a global `trial` in the same row order), the results coincided with the correct ones. That is because stratified resampling keeps every position within its S x A stratum, so `trial[i]` still matched. I did not construct a case where this coincidence fails, though a global covariate vector would be one.
- **The DID methods share finding 4.** `R/did_ec_ipw.R:85` and `R/did_ec_aipw.R:99` use the same `paste0(trial_status, " ~")` rewrite, and `.build_analysis_df()` is shared, so a trial-status column not named `S` very likely fails there too. Not run (out of scope).
- **`data.table` input.** `data[, outcomes, drop = FALSE]` with a character variable may behave differently for a `data.table`. Not run.

## What I checked and found correct

- **S/A validation.** Values other than 0/1 (1/2, -1/1, `1 + 1e-12`, factor labels) and `NA` in S or A are rejected with clear messages. Logical and integer S/A give results identical to doubles.
- **Arm sizes and outcome counts.** Very small arms work: 4 per group with one covariate, one trial control, one external control (EC-IPW), and quickcheck trials with n = 8. A single outcome works, as do four outcomes and 40 outcomes on a 60-subject dataset (finite SEs). Duplicated outcome names give duplicate, identical rows.
- **Covariate types.** Factor and character covariates are handled. Covariates in `covariates_col_name` but not in any formula are ignored, even with `NA`. A factor level seen only among treated subjects, or a covariate constant among controls, is rejected by `lm()`/`contrasts`. That is an acceptable rejection: mu(X) = E[Y | X, A = 0] isn't estimable there, though the messages are cryptic.
- **Near and complete separation.** Separation in the participation model (external x5 shifted by 0 to 200) behaves as the method implies. `glm()` warns, the effective sample size of W00 falls to about 1, and w_hat falls toward 1/(1 + n0) ≈ 0.0099. I checked whether `binomial()$linkinv` clamping (2.2e-16 below eta = -30) could give all external controls equal weight and so inflate w_hat. It does not: the nearest external control's eta stays near -20. This is Assumption 5 (positivity), a method limitation, not a code bug.
- **Bootstrap options.** All four `bootstrap_ci_type` values work for EC-AIPW at B = 100 (#77 fixed). Bootstrap output is reproducible under `set.seed()`, and point estimates equal the sandwich run's.
- **Optimal weight.** Eq. 11 is implemented with constant W10, so its numerator is 1/n0. The bootstrap reuses the full-data w_hat, which is consistent with Theorem 3 treating w as fixed.
- **Missing-data guidance.** The vignette does tell users to supply complete data (`primary_analysis_workflow.Rmd:169`). Finding 6 is about how failures surface, not about missing support.
