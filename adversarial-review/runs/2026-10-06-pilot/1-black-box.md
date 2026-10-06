# rdborrow adversarial review, pilot: black-box API tester

- **Role:** 1, black-box API tester (issue #101). Scope: `ec_ipw()`, `ec_aipw()`, `setup_analysis_primary()`, `run_analysis()` and their docs.
- **Commit:** worktree at `ee5df1c` on branch `adversarial-review`, with package code identical to `main` at `6185ba9`. DESCRIPTION version 0.0.4.2.
- **R:** 4.6.1 (2026-06-24), Linux.
- **Loading:** the installed copy at `scratchpad/review-lib` (`.libPaths()` prepended, then `library(rdborrow)`), confirmed by `find.package()`. Every headline reproducer was also run under `devtools::load_all()` (`RDB_LOADALL=1`). The outputs are identical apart from the mode banner (`repro_installed.txt` vs `repro_loadall.txt`).
- **Order of work:** paper §2.3, §3.1–3.4, Appendix B and the supplement first, then the man pages, vignettes, README, AGENTS.md and articles, then black-box probing. I read the source only after each finding was fixed by black-box evidence.
- **Data and seeds:** `SyntheticData` (300 rows: 100 trial treated, 100 trial control, 100 external) and `simulate_trial()`. Seeds are recorded in each script.
- **Artifacts:** all scripts and outputs are in `scratchpad/review-pilot/bb/`: `hdr.R` (loader), `ex.R` (man-page examples), `vig.R` (vignettes), `p1.R`–`p10.R` (probes), `repro.R` (consolidated reproducer), `mc.R` (Monte Carlo), `test-proposed.R` with `run_tests.R` (proposed tests, each run against this commit).

All reproducers below assume:

```r
F5 <- "S ~ x1 + x2 + x3 + x4 + x5"
O5 <- c("y1 ~ x1 + x2 + x3 + x4 + x5", "y2 ~ x1 + x2 + x3 + x4 + x5")
covs <- c("x1", "x2", "x3", "x4", "x5")
pa <- function(m, data = SyntheticData, S = "S", A = "A", y = c("y1", "y2"), x = covs)
  run_analysis(setup_analysis_primary(data, S, A, y, x, m))
```

---

## Findings (most severe first)

### F1. `ec_aipw()`: `outcome_formula` is matched to outcomes by position while its left-hand side is honoured, so a reordered vector silently gives wrong estimates

- **Location:** `R/ec_aipw.R:206-212` (`lm(as.formula(f), data = df[A == 0, ])`, then `Yr <- Y - Y0`, where column t of `Y` is `outcomes[t]` and column t of `Y0` is a prediction from `outcome_formula[t]`). Docs: `R/ec_aipw.R:30-31` / `man/ec_aipw.Rd` ("one per time point"). Paper §3.1, Theorem 2: Ỹ = Y − μ(X), with μ(X) = E[Y | X, A = 0] for the *same* outcome.
- **Reproducer** (`repro.R`, section F1):
  ```
  pa(ec_aipw(F5, O5))          # tau -0.5463  0.5402   sd 0.5306 0.5543
  pa(ec_aipw(F5, rev(O5)))     # tau -0.1267  0.1206   sd 0.5516 0.5532   (no warning)
  pa(ec_aipw(F5, O5[c(1, 1)])) # tau -0.5463  0.1206   (y2 residualised with the y1 model)
  ```
- **Expected:** the outcome model for outcome t regresses that outcome on X (Theorem 2). If the formulas don't line up with `outcome_col_name`, the function should either match them by left-hand side or stop. Compare `ps_formula`, whose left-hand side is documented as replaced.
- **Actual:** the left-hand side decides which variable is modeled, and the position decides which outcome the prediction is subtracted from. A mismatch gives a different, plausible-looking answer with no message. Writing the formulas in a different order from `outcome_col_name` is an easy slip, for example `outcome_col_name = c("y4", "y1")` with formulas copied from another analysis.
- **Category:** implementation bug, plus a documentation gap (order and LHS semantics are undocumented). **Severity:** wrong.
- **Proposed test:**
  ```r
  test_that("outcome_formula must match outcome_col_name", {
    expect_error(run_pa(ec_aipw(f5, rev(o5))), "outcome_formula")
    expect_error(run_pa(ec_aipw(f5, o5[c(1, 1)])), "outcome_formula")
  })
  ```
  (Alternative fix: reorder by LHS, then test `expect_equal(run_pa(ec_aipw(f5, rev(o5))), run_pa(ec_aipw(f5, o5)))`.)

### F2. `ps_formula = "S ~ ."` silently puts the outcomes and the treatment into the trial-participation model. Any formula can use non-covariate columns, and covariates that aren't listed give a cryptic error

- **Location:** `R/method_class.R:129-136` (`.build_analysis_df()` returns outcomes + `S` + `A` + covariates, and the propensity model is fitted on that whole frame, `R/ec_weights.R:12`). Docs: `man/setup_analysis_primary.Rd` (`covariates_col_name`: "Character vector of covariate column names", with nothing about its role in the formulas). Paper §3.1: π_S(X) = Pr(S = 1 | X), a model in the baseline covariates X only.
- **Reproducer** (`repro.R` F2, `p4.R`):
  ```
  pa(ec_ipw(F5))                                    # tau -0.1972 0.4697  bw 0.1475
  pa(ec_ipw("S ~ ."))                               # tau  0.0357 0.4028  bw 0.1429
  pa(ec_ipw("S ~ x1 + x2 + x3 + x4 + x5 + y1 + y2 + A"))  # identical to "S ~ ."
  pa(ec_ipw("S ~ x1 + A"))                          # runs; treatment in PS model
  pa(ec_ipw("S ~ x1 + x2"), x = c("x1","x2"))      # fine
  pa(ec_ipw(F5), x = c("x1","x2"))                  # ERROR: object 'x3' not found
  pa(ec_aipw(F5, c("y1 ~ .", "y2 ~ .")))            # rank-deficient warnings, then
                                                    # ERROR: Lapack routine dgesv: system is exactly singular
  ```
- **Expected:** given `covariates_col_name`, a user reasonably reads `.` as "all covariates". Post-treatment outcomes and `A` should never enter π_S(X). The paper's model conditions on baseline X, and A = 1 implies S = 1 by design (§2.1). A formula term outside `covariates_col_name` should get an error that names the argument.
- **Actual:** `.` expands to `y1, y2, A, x1..x5`. Outcomes and `A` are accepted as PS predictors without a message, and the estimate moves from −0.197 to 0.036. A covariate that is in `data` but not listed fails with "object 'x3' not found", which doesn't tell the user to add it to `covariates_col_name`.
- **Category:** implementation bug (no validation) and documentation gap. **Severity:** wrong (for `.`), gap (for the error text).
- **Proposed test:**
  ```r
  test_that("ps_formula may only use covariates_col_name", {
    expect_equal(run_pa(ec_ipw("S ~ .")), run_pa(ec_ipw(f5)))
    expect_error(run_pa(ec_ipw("S ~ x1 + A")), "covariates_col_name")
    expect_error(run_pa(ec_ipw("S ~ x1 + y1")), "covariates_col_name")
  })
  ```

### F3. A covariate or outcome column named `A` (or `S`) collides with the renamed treatment (or trial) column and silently gives wrong results

- **Location:** `R/method_class.R:132-135`. `data.frame(Y, S = ..., A = ..., covariates)` uses `check.names = TRUE`, so a duplicated name becomes `A.1`. Formulas and `df$A` then resolve to the wrong column. Shared by all six methods.
- **Reproducer** (`repro.R` F3; the treatment column is renamed `arm` in every case):
  ```
  # reference: covariate named x4
  pa(ec_ipw(F5), data = dA, A = "arm")                       # -0.1972 0.4697  bw 0.1475
  # same data, x4 renamed "A"
  pa(ec_ipw("S ~ x1 + x2 + x3 + A + x5"), data = dc, A = "arm",
     x = c("x1","x2","x3","A","x5"))                          # -0.0299 0.5247  bw 0.1214
  # binary outcome stored twice, as "ybin" and as "A"
  pa(ec_ipw(F5), data = db, A = "arm", y = "ybin")           # -0.0027  sd 0.0675
  pa(ec_ipw(F5), data = db, A = "arm", y = "A")              #  0.9110  sd 0.0143
  ```
  For the last case, `df$A` is the outcome, so the outcome is used as the treatment indicator, and a near-zero effect becomes 0.91 with a tight CI.
- **Expected:** results depend on column contents, not names. Either the internal names are made collision-proof, or names that clash with the reserved internal names are rejected with a clear error.
- **Actual:** wrong numbers with no message. Today only `A` can collide, because of F4. Once F4 is fixed, a covariate called `S` (a natural name for sex) collides the same way.
- **Category:** implementation bug. **Severity:** wrong (realistic only for columns literally named `A` or `S`).
- **Proposed test:**
  ```r
  test_that("a covariate or outcome named A does not collide with treatment", {
    d <- SyntheticData; names(d)[names(d) == "A"] <- "arm"
    ref <- run_pa(ec_ipw(f5), data = d, A = "arm")
    dc <- d; names(dc)[names(dc) == "x4"] <- "A"
    expect_equal(run_pa(ec_ipw("S ~ x1 + x2 + x3 + A + x5"), data = dc, A = "arm",
                        covariates = c("x1", "x2", "x3", "A", "x5")), ref)
    db <- d; db$ybin <- as.numeric(db$y1 > 0); db$A <- db$ybin
    expect_equal(run_pa(ec_ipw(f5), data = db, A = "arm", outcomes = "A")$results,
                 run_pa(ec_ipw(f5), data = db, A = "arm", outcomes = "ybin")$results)
  })
  ```

### F4. `trial_status_col_name` other than `"S"` always errors for `ec_ipw()` and `ec_aipw()`, whatever the formula says

- **Location:** `R/ec_ipw.R:96` and `R/ec_aipw.R:117` rewrite the formula's left-hand side to the **user's** column name (`paste0(trial_status, " ~")`). `.build_analysis_df()` (`R/method_class.R:133`) has already renamed that column to `S`. Docs that contradict the code: `vignettes/articles/adding-a-method.Rmd:84` ("`ec_ipw()` replaces the left-hand side of `ps_formula` with `S`") and `man/ec_ipw.Rd` ("The left-hand side is replaced internally"). The same `sub()` appears in `R/did_ec_ipw.R:85` and `R/did_ec_aipw.R:99`.
- **Reproducer** (`repro.R` F4, `p8.R`; installed and `load_all()` agree):
  ```
  dS <- SyntheticData; names(dS)[names(dS) == "S"] <- "in_trial"
  pa(ec_ipw("in_trial ~ x1 + x2 + x3 + x4 + x5"), data = dS, S = "in_trial")
  #> ERROR: object 'in_trial' not found
  pa(ec_ipw(F5), data = dS, S = "in_trial")             #> same error
  pa(ec_aipw(F5, O5), data = dS, S = "in_trial")        #> same error
  pa(ec_ipw(F5, bootstrap = 20), data = dS, S = "in_trial")  #> same error
  ```
  Renaming only the treatment column (`A = "arm"`) works.
- **Expected:** `setup_analysis_primary()` documents `trial_status_col_name` as a free column name, so any name should work.
- **Actual:** every primary analysis fails unless the trial column is literally `S`. No test uses another name (`grep` of `tests/` finds only the `"not_a_col"` rejection tests). Related: #83 describes the LHS rewrite but not this failure.
- **Category:** implementation bug, with a documentation error at `adding-a-method.Rmd:84`. **Severity:** wrong, but loud (it errors), so it ranks below the silent findings.
- **Proposed test:**
  ```r
  test_that("a trial status column not named S works", {
    d <- SyntheticData; names(d)[names(d) == "S"] <- "in_trial"
    expect_equal(run_pa(ec_ipw(f5), data = d, S = "in_trial"), run_pa(ec_ipw(f5)))
    expect_equal(run_pa(ec_aipw(f5, o5), data = d, S = "in_trial"),
                 run_pa(ec_aipw(f5, o5)))
  })
  ```

### F5. The docs call `weight = NULL` "data-adaptive" and "minimizing variance", but the weight never looks at outcomes, so it does not react to conflict between trial and external controls

- **Location:** `R/ec_ipw.R:28` and `R/ec_aipw.R:32` (and both man pages): "data-adaptive optimal weight". `vignettes/introduction.Rmd:43`: "data-adaptive weight minimizing variance". `vignettes/primary_analysis_workflow.Rmd:50,121`: "Optimal weight (data-adaptive)". `AGENTS.md:46`. Paper §3.3 eq. (11) and Appendix B: an outcome-free "variance ratio" that approximates the MSE-optimal eq. (10) only under **B ≈ 0** and equal residual variances, chosen "at the design stage... without access to the outcome data".
- **Reproducer** (`repro.R` F5): external outcomes `y1` and `y2` shifted by `s`:
  ```
  s = 0   tau -0.1972  0.4697   bw 0.1475
  s = 5   tau -0.9348 -0.2679   bw 0.1475
  s = 50  tau -7.5732 -6.9063   bw 0.1475   (SE unchanged at 0.5134 / 0.5410)
  ```
- **Expected:** the docs should say what the paper says. ŵ depends only on the propensity-score weights, assumes no bias from borrowing (B = 0) and equal outcome variances, and does not guard against drift or prior-data conflict, unlike dynamic borrowing (paper §4).
- **Actual:** the code matches the paper (correct). "Data-adaptive" and "minimizing variance" suggest the weight responds to the outcome data, which invites false reassurance.
- **Category:** documentation error. The insensitivity itself is a limitation of the method by design. **Severity:** misleading.
- **Proposed test** (locks the documented behavior once the wording is fixed):
  ```r
  test_that("optimal borrow_weight does not depend on outcomes", {
    d <- SyntheticData; d$y1[d$S == 0] <- d$y1[d$S == 0] + 50
    expect_equal(run_pa(ec_ipw(f5), data = d)$borrow_weight,
                 run_pa(ec_ipw(f5))$borrow_weight)
  })
  ```

### F6. Missing values are not rejected: EC-IPW silently returns `NA`, which spreads into the other outcomes' SEs, and other paths fail cryptically

- **Location:** `.validate_analysis_base()` in `R/analysis_class.R:44-72` has no `any.missing` check. The only guidance is `vignettes/primary_analysis_workflow.Rmd:169`; there is none in the man pages.
- **Reproducer** (`repro.R` F6, `p9.R`), with `y1` set to NA in rows 1, 3, 250:
  ```
  pa(ec_ipw(F5), data = dn)
  #>      point_estimates standard_deviation lower_CI_normal upper_CI_normal
  #> tau1              NA                 NA              NA              NA
  #> tau2       0.4697209                 NA              NA              NA     <- y2 is complete
  pa(ec_aipw(F5, O5), data = dn)               #> ERROR: non-conformable arguments
  pa(ec_ipw(F5, bootstrap = 30), data = dn)    #> ERROR: missing value where TRUE/FALSE needed
  # NA in covariate x4:
  pa(ec_ipw(F5), data = dx)                    #> ERROR: missing value where TRUE/FALSE needed
  pa(ec_aipw(F5, O5), data = dx)               #> ERROR: non-conformable arguments
  ```
- **Expected:** a checkmate rejection at `setup_analysis_primary()` that names the column. AGENTS.md says to validate exported function arguments with checkmate.
- **Actual:** silent `NA`s on the sandwich EC-IPW path, including an `NA` SE for an outcome with no missing data, and unrelated low-level errors elsewhere.
- **Category:** implementation gap. **Severity:** gap.
- **Proposed test:**
  ```r
  test_that("missing values are rejected", {
    d <- SyntheticData; d$y1[1] <- NA
    expect_error(setup_analysis_primary(d, "S", "A", c("y1", "y2"), covs, ec_ipw(f5)), "missing")
    d <- SyntheticData; d$x4[2] <- NA
    expect_error(setup_analysis_primary(d, "S", "A", c("y1", "y2"), covs, ec_ipw(f5)), "missing")
  })
  ```

### F7. External controls coded as treated (`S = 0, A = 1`) are accepted. EC-IPW ignores the code, while EC-AIPW drops those rows from its outcome model

- **Location:** `R/analysis_class.R:61-71` checks only that S and A are 0/1. Paper §2.1: external controls are sampled from P_E(X, A = 0, Y(0)), and simulation eq. (20) sets A = 0 if S = 0.
- **Reproducer** (`repro.R` F7), with the first 10 external rows set to `A = 1`:
  ```
  pa(ec_ipw(F5), data = de)        # -0.1972 0.4697   (unchanged: A ignored when S = 0)
  pa(ec_aipw(F5, O5), data = de)   # -0.5485 0.5384   (was -0.5463 0.5402: rows dropped from mu(X) fit)
  ```
- **Expected:** an error. Data with treated external subjects is either miscoded or outside the method's design.
- **Actual:** accepted silently, and the two methods treat the rows inconsistently.
- **Category:** implementation gap. **Severity:** gap.
- **Proposed test:**
  ```r
  test_that("external controls must be untreated", {
    d <- SyntheticData; d$A[which(d$S == 0)[1]] <- 1
    expect_error(setup_analysis_primary(d, "S", "A", c("y1", "y2"), covs, ec_ipw(f5)), "external")
  })
  ```

### F8. `bootstrap_ci_type` without `bootstrap` is silently ignored

- **Location:** `R/ec_ipw.R:72-80`, `R/ec_aipw.R` (same block). Docs: `man/ec_ipw.Rd` ("resolves to "perc" when bootstrap is set").
- **Reproducer** (`repro.R` F8):
  ```
  m <- ec_ipw(F5, bootstrap_ci_type = "bca"); m@bootstrap_ci_type   #> "bca"
  names(pa(m)$results)  #> point_estimates standard_deviation lower_CI_normal upper_CI_normal
  ```
- **Expected:** an error or a warning that `bootstrap_ci_type` needs `bootstrap`. A user who asks for BCa intervals gets sandwich intervals instead.
- **Actual:** the value is stored and never used, with no message. The returned column names are the only clue.
- **Category:** design question / implementation gap. **Severity:** gap.
- **Proposed test:** `expect_error(ec_ipw(f5, bootstrap_ci_type = "bca"), "bootstrap")`, or `expect_warning()` if the maintainers choose a warning.

### F9. `alpha` accepts 0 and 1, which produce `NA`, infinite or zero-width intervals

- **Location:** `R/analysis_class.R:52` (`assert_number(alpha, lower = 0, upper = 1)`).
- **Reproducer** (`repro.R` F9, `p5.R`):
  ```
  alpha = 0, sandwich:   lower -Inf, upper Inf
  alpha = 0, bootstrap perc (B = 50, seed 1):  lower -1.5287, upper NA  (+ "extreme order statistics" warning)
  alpha = 1, sandwich:   lower = upper = -0.1972
  alpha = 1, bootstrap perc:  lower = upper = -0.1391 (not even the point estimate)
  ```
- **Expected:** `alpha` in the open interval (0, 1), checked with `assert_number(alpha, lower = 0, upper = 1)` plus a strict-bound check (checkmate has no open-interval flag for `assert_number`; use `alpha > 0 && alpha < 1`).
- **Category:** implementation gap. **Severity:** polish.
- **Proposed test:** `expect_error(setup_analysis_primary(SyntheticData, "S", "A", "y1", covs, ec_ipw(f5), alpha = 0), "alpha")`, and the same for `alpha = 1`.

### F10. Several invalid inputs pass validation and fail later with low-level errors

- **Location:** `R/analysis_class.R:61-71` (the `%in%` check accepts factor 0/1), `R/run_analysis.R:48` (no checkmate on `analysis_obj` or `quiet`), `R/ec_aipw.R` constructor (`assert_character(outcome_formula, min.len = 1)` allows `NA`).
- **Reproducer** (`p7.R`, `p9.R`, `p5.R`):
  ```
  S, A as factor(0/1)                -> ERROR: 'sum' not meaningful for factors
  S and A columns swapped            -> ERROR: missing value where TRUE/FALSE needed
  run_analysis(ec_ipw(F5))           -> ERROR: no slot of name "method_obj" for this object of class "ec_ipw_method"
  run_analysis(analysis, quiet = NA) -> ERROR: missing value where TRUE/FALSE needed
  ec_aipw(F5, NA_character_)         -> constructs without error
  ec_aipw(F5, c("~ x1", "~ x1"))     -> ERROR: incompatible dimensions
  ec_aipw(F5, c("y1 ~ x1 + A", ...)) -> rank-deficient warnings, then
                                        ERROR: Lapack routine dgesv: system is exactly singular
  ```
  (`A` is constant among the controls the outcome model is fitted on.)
- **Expected:** a checkmate error at the boundary that names the argument (AGENTS.md: "Validate the arguments of exported functions with checkmate").
- **Category:** implementation gap. **Severity:** polish.
- **Proposed test:**
  ```r
  test_that("invalid inputs are rejected at the boundary", {
    expect_error(ec_aipw(f5, NA_character_), "outcome_formula")
    expect_error(run_analysis(ec_ipw(f5)), "analysis_obj")
    d <- SyntheticData; d$S <- factor(d$S)
    expect_error(setup_analysis_primary(d, "S", "A", "y1", covs, ec_ipw(f5)), "S")
  })
  ```

### F11. Documentation inconsistencies in the user path (one finding, several small items)

| Item | Location | Problem |
|---|---|---|
| a | `man/ec_aipw.Rd` (`R/ec_aipw.R:41`) | `bootstrap_ci_type`: "Defaults to "perc"". The default is `NULL`, resolved to `"perc"` only when `bootstrap` is set, and the allowed values aren't listed. `ec_ipw.Rd` has it right. |
| b | `man/ec_aipw.Rd` | `ps_formula` doesn't say its left-hand side is replaced (`ec_ipw.Rd` does). `outcome_formula` doesn't say that order must match `outcome_col_name` or that the LHS is used (see F1). |
| c | `man/run_analysis.Rd` (`R/run_analysis.R:27-28`) | Says the results hold "standard errors". The column is `standard_deviation`, which is the sandwich SE, or the bootstrap SD when `bootstrap` is set. The page also doesn't say that `*_CI_normal` columns are replaced by `*_CI_boot` under bootstrap, or that rows are `tau1..tauT` in `outcome_col_name` order rather than outcome names (with `y = c("y4","y1")` the `y4` row is labeled `tau1`). The contract is spelled out only in the developer article. |
| d | `man/setup_analysis_primary.Rd` example | Prints nothing. `setup_analysis_primary()` ends in an assignment (`R/analysis_primary_class.R:78`) and returns invisibly; `withVisible(...)$visible` is `FALSE`. The `show()` method exists but never runs in the example. |
| e | `man/ec_ipw.Rd`, `man/ec_aipw.Rd` examples | Printing a method object dumps raw S4 slots (no `show` method), unlike analysis objects. |
| f | Citation year | Man pages, vignettes and code comments cite "Zhou et al. (2024)". The paper is JRSS-A 2025;188(3). `vignettes/introduction.Rmd:37-38` labels it "2024b", but `R/ec_ipw.R:157,215` and `R/ec_aipw.R:184,254` call it "Zhou 2024a", and the reference lists define neither suffix. |
| g | `vignettes/primary_analysis_workflow.Rmd` §2.3, §3.3 | Bootstrap chunks have no `set.seed()`, so rendered numbers change on every build. |
| h | `README.md:47,54` | Package citation says version 0.0.4.0; DESCRIPTION says 0.0.4.2. |
| i | `R/ec_ipw.R:100,124`, `R/ec_aipw.R:128,151` | `quiet = FALSE` progress uses `cat()`, not `message()`, so it can't be suppressed with `suppressMessages()`. AGENTS.md discourages `cat()` in package code. |
| j | `vignettes/articles/adding-a-method.Rmd:84` | Says `ec_ipw()` replaces the LHS with `S`. It uses the trial-status column name instead, which is the cause of F4. |

- **Category:** documentation error. **Severity:** polish (c is borderline misleading).
- **Proposed test:** `expect_visible(setup_analysis_primary(SyntheticData, "S", "A", "y1", covs, ec_ipw(f5)))` (item d). The rest are documentation fixes.

**Proposed tests executed:** `bb/test-proposed.R`, run via `bb/run_tests.R` (`load_all`), covers F1–F4 and F6–F11 plus the F5 lock-in. On this commit every test fails or errors except the F5 lock-in, which passes by design.

---

## Unexecuted suspicions

1. **F4 also breaks the OLE methods.** `R/did_ec_ipw.R:85` and `R/did_ec_aipw.R:99` use the same `sub()` with `trial_status`, after the same renaming to `S`. `did_ec_ipw()` and `did_ec_aipw()` probably fail for any trial column not named `S`. Out of scope; not run.
2. **F3 affects all six methods.** `.build_analysis_df()` is shared (`did_ec_*`, `scm`). Not run outside the primary methods.
3. **Variance formula vs the paper.** Paper eqs (13) and (16) give Var = Σ11 + (1−w)²Σ22 + w²Σ33, dropping cross-covariances. The code applies the full contrast `c' Σ c` (`R/ec_ipw.R:266-272`, `R/ec_aipw.R:331`), which keeps Cov(μ̂11, μ̂00) and Cov(μ̂10, μ̂00) through α̂. The code is arguably more correct than the displayed formula, but it is a deviation. I did not quantify the difference; this is for the numerical tester.
4. **Ψ5 scaling.** `R/ec_aipw.R:302,322` scales the outcome-model estimating equation by 1/(1 − mean(A)) over all N, where the paper (Theorem 4) uses 1/(1 − π_A). A constant scaling of one estimating-equation block cancels in A⁻¹BA⁻ᵀ, so this should be harmless. That rests on reasoning only; not checked numerically.

---

## Checked and found correct (or consistent with the paper)

- **Examples and vignettes.** All four man-page examples and every chunk of `introduction.Rmd`, `primary_analysis_workflow.Rmd` and the AGENTS.md example (seed 101, `bootstrap = 500`) run without errors or warnings on the installed package. The outputs match the surrounding text. The `adding-a-method.Rmd` swap to `ec_ipw(weight = 0.5)` also runs.
- **Weight contract.** -0.1, 1.1, NA, "0.5", length 2, TRUE and Inf are rejected with clear checkmate messages. 0, 0L, 1, 1L, 1e-12 and 1 − 1e-12 are accepted, and the extremes are continuous with 0 and 1.
- **Bootstrap contract.** 0, 1, 2.5, −5, "100", NA and TRUE are rejected; 2 and 3L are accepted. `"stud"`, `"PERC"`, a vector and NA are rejected for `bootstrap_ci_type`. All four types (`perc`, `bca`, `norm`, `basic`) run for both methods at B = 30 and 400, with no NA bounds, so #77 is fixed. `alpha` propagates to the bootstrap CIs: width shrinks from alpha 0.05 to 0.5 for all four types. Bootstrap results are reproducible under `set.seed()`.
- **Normal CIs** use exactly `qnorm(1 − alpha/2)`: implied z is 1.959964 at 0.05 and 1.281552 at 0.2.
- **EC-IPW at w = 0 is trial-only, as documented.** τ̂ equals the hand-computed trial difference in means (−0.02808704, 0.40959558). The SE equals sqrt(s₁²/n₁ + s₀²/n₀) with MLE variances (0.5367987, 0.5625763). Both are unchanged when external outcomes shift by +100, external x4 is tripled, or half the external rows are dropped. This matches §3.1 (Hájek IPTW at w = 0).
- **w = 1 puts full weight on external controls.** EC-IPW at w = 1 is unchanged when trial-control outcomes shift by +100, which confirms `borrow_weight` is the weight on external controls, as in eqs (6) and (10). EC-AIPW at w = 1 does change (−1.18 to −5.32), because μ̂(X) is fit on all controls. That is the paper's design (Theorem 2, μ(X) = E[Y | X, A = 0]), the mirror image of #92, and not a bug.
- **Optimal weight.** It is the same for both methods and every outcome, and it equals eq. (11): `"S ~ 1"` gives exactly 0.5 with 100 trial and 100 external controls. A fixed `weight = ŵ` reproduces `weight = NULL` exactly, for both sandwich and bootstrap with the same seed. So the bootstrap holds ŵ fixed at its full-sample value (`R/ec_ipw.R:129`), consistent with §3.3 (w chosen at design) and the "fixed w" in Theorems 3 and 4. Neither the sandwich nor the bootstrap carries ŵ's sampling variability; this is a property of the method, not flagged as a defect.
- **EC-AIPW with `"y ~ 1"`** equals EC-IPW exactly, as it should, since a constant μ cancels in the normalized means.
- **`ec_aipw(weight = 0)` docs** (#92) match the behavior.
- **Return shape.** `list(results, borrow_weight)`; columns `point_estimates, standard_deviation, lower_CI_normal, upper_CI_normal` (sandwich) or `..._CI_boot` (bootstrap); rows `tau1..tauT`; lower ≤ estimate ≤ upper in every configuration tried. This matches the contract in `adding-a-method.Rmd`. One, two, three and four outcomes all work, and outcome order is respected for EC-IPW.
- **Other validation.** Data must be a data.frame (a tibble works; a matrix is rejected). Unknown column names are rejected with the column named. S and A coded 1/2 or as character are rejected with a clear message. Logical S and A work. An OLE method object is rejected by `setup_analysis_primary()`. `outcome_formula` of the wrong length errors clearly. `quiet = FALSE` prints a progress line.
- **Small Monte Carlo** (`mc.R`, seed 20261006, 1000 reps). DGP fixed before running: n = 150 trial (100 treated / 50 control), m = 100 external; X ~ N(0, I) in the trial and N(0.5, I) externally, so the logistic PS is correct; linear outcomes shared across sources; true τ = (1, 0.5). All four configurations (IPW and AIPW, ŵ and w = 1) have |bias| < 0.011, within 2 MCSE. Normal-CI coverage is 0.927–0.944 (MCSE 0.007) and the mean sandwich SE is 3–7% below the empirical SD. That is mild finite-sample under-coverage, worst for IPW w = 1 at t2 (0.927, about 3 MCSE below 0.95). Not claimed as a defect; flagged for the numerical tester to check at larger n.
- **Paper note** (not a package issue). §3.3 says "A higher value of ŵ suggests a smaller weight assigned to the external controls", which contradicts eqs (10) and (11), where ŵ is the external weight. The package follows the equations, and its docs don't repeat the sentence.
