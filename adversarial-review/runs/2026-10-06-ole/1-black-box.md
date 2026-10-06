# OLE adversarial review, role 1: black-box API tester

- **Role:** black-box API tester for `did_ec_ipw()`, `did_ec_aipw()`, `did_ec_or()`, `scm()`, `setup_analysis_OLE()`, `run_analysis()` and their docs.
- **Commit:** worktree `agent-a0c92496bd7f92298`, package code identical to main at 6185ba9 (rdborrow 0.0.4.2).
- **R:** 4.6.1 (2026-06-24). CVXR 1.9.1, ECOSolveR 0.6.1, boot 1.3.32, checkmate 2.3.4.
- **Loading:** every script sources `bb/setup.R`, which loads the installed copy from `scratchpad/review-lib` (default) or `devtools::load_all()` when `LOAD=dev`. I re-ran scripts 03, 06, 11, 12, 13, 14 and 16 with `LOAD=dev`. They cover findings 1, 2 (the k = 100 failure), 3, 4, 8, 9 (DID part), 10 and 12, and the #103/#104/#105/#108 evidence. The output was identical to the installed run (`*_dev.out`).
- **Order of work:** paper §2-3 and Appendices A-B, then all man pages and vignettes, then black-box runs. I read the source only after forming each finding.
- **Scripts and outputs:** `scratchpad/review-ole/bb/NN_*.R` with matching `NN_*.out`. Seeds are set inside every script.

All `file:line` references are to the worktree.

---

## Findings (most severe first)

### 1. A `T_cross` that is an integer only up to floating point silently gives a different estimate, or copies one visit's CI to another

- **Location:** `R/analysis_OLE_class.R:100` (`checkmate::assert_int(T_cross, lower = 1)` accepts an integer within tolerance, does not coerce, and the slot is `numeric`). The value is then used in `:` and `seq_len()`: `R/did_ec_ipw.R:98,111,159-171`, `R/did_ec_aipw.R:114,128`, `R/did_ec_or.R:114,130,161-188`, `R/scm.R:109,146,160`, and `R/method_class.R:113` (`seq_len(n_estimates)`).
- **Reproducer:** `bb/13_tcross_float.R` (output `13_tcross_float.out`, same under `LOAD=dev`).
  ```r
  m <- did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 200)
  set.seed(1); ole(m, T_cross = 3L)          # tau4  3.816  [0.716, 6.842]
  set.seed(1); ole(m, T_cross = 0.6 / 0.2)   # tau4  1.507  [0.047, 3.121]   <- wrong, no message
  set.seed(1); ole(m, T_cross = 2 + 1e-9)
  #                point_estimates lower_CI_boot upper_CI_boot
  # tau3.000000001        2.323352     0.5064161      4.506462
  # tau4.000000001        4.632520     0.5064161      4.506462   <- tau3's CI, recycled
  ```
  `0.6 / 0.2` is `2.9999999999999996`, and `checkmate::test_int()` returns `TRUE` for it. `did_ec_aipw()` behaves the same way (3.374 becomes 1.324). `did_ec_or()` fails with `subscript out of bounds`.
- **Expected:** the docs say "Integer crossover time point ... Must be a positive integer". A value accepted as an integer should be used as that integer: `T_cross = 3`, tau4 = 3.816. Otherwise it should be rejected.
- **Actual:** `(T_cross + 1):n` and `1:T_cross` use R's fuzzy `:`, while `seq_len()` and matrix indexing truncate. The Period I/II split then differs from the one the user asked for. With `2 + 1e-9`, `seq_len(1.999999999)` computes one CI, and `data.frame()` recycles it into the second row.
- **Category:** implementation bug. **Severity:** wrong.
- **Proposed test (`test-analysis_OLE_class.R`):**
  ```r
  test_that("setup_analysis_OLE() stores T_cross as an integer", {
    a <- setup_analysis_OLE(SyntheticData, "S", "A", paste0("y", 1:4), paste0("x", 1:5),
      did_ec_ipw("S ~ x1", bootstrap = 2), T_cross = 0.6 / 0.2)
    expect_identical(a@T_cross, 3L)
  })
  ```
  Fix: `T_cross <- checkmate::assert_int(T_cross, lower = 1, coerce = TRUE)`.

### 2. `scm()` fails on valid data in other units, and uses solver output without checking it

- **Location:** `R/scm.R:186-189` (`.scm_subject_sc`) and `R/scm.R:219-222` (`.scm_lambdacv`). `CVXR::psolve()` status is never checked, and `CVXR::value(w)` is used even when it is `NULL` or inaccurate.
- **Reproducer:** `bb/10_scm_equivariance.R <k>` multiplies every covariate and every outcome by `k`, then runs `scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2)`, seed 7. `bb/09_scm_more.R scale` rescales `x5` only.

  | k | tau / k | messages |
  |---|---|---|
  | 0.01 | 2.0681, 3.9399 | 4x "Solution may be inaccurate" |
  | 0.1 | 2.0649, 3.9408 | - |
  | 1 | 2.0648, 3.9432 | - |
  | 10 | 2.0654, 3.9414 | **90x** "Solution may be inaccurate" |
  | 100 | **ERROR: requires numeric/complex matrix/vector arguments** | |

  `x5 * 100` (x5 ranges 8-84, so up to 8,400) gives the same error. So does `y * 1000` (`ERROR: Solver "ECOS" failed`). `16_scm_fail_trace.R` places the failure in `.scm_lambdacv()`, so it happens even with `nlambda = 1`.
- **Expected:** multiplying all of z = (X, Y_I) and Y_II by k multiplies both terms of Eq. 7 by k², so the weights and tau / k cannot change (Zhou et al. 2024, Eq. 7-9). Data recorded as, for example, MFM 0-100 or age in months must work. A solver failure should give an error that names the cause.
- **Actual:** the estimate changes in the third decimal across equivalent scalings. Data on a plausible clinical scale fails with an unrelated `%*%` error. Inaccurate solutions are averaged into the estimate, with only a CVXR warning.
- **Category:** implementation bug (numerical robustness). **Severity:** wrong (fails on valid data) and misleading (inaccurate solves are used).
- **Proposed test (`test-scm.R`, `skip_on_cran()`):**
  ```r
  test_that("scm() is equivariant to a common rescaling of covariates and outcomes", {
    cols <- c(paste0("x", 1:5), paste0("y", 1:4))
    d <- SyntheticData; d[cols] <- d[cols] * 100
    m <- scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2)
    fit <- \(data) run_analysis(setup_analysis_OLE(data, "S", "A", paste0("y", 1:4),
      paste0("x", 1:5), m, T_cross = 2))$point_estimates
    set.seed(1); ref <- fit(SyntheticData)
    set.seed(1); expect_equal(fit(d) / 100, ref, tolerance = 1e-4)
  })
  ```
  Possible fixes: standardize z internally and rescale the result, which is exact under Eq. 7 only for a common factor. Also check `prob$status` / `result$status` and stop with a clear message.

### 3. Missing values: nothing validates them, and each method and arm handles them differently, some silently

- **Location:** `R/analysis_class.R:44-72` (no NA check). `R/ec_weights.R:12-13` (`glm` drops NA rows; `predict(newdata=)` returns NA). `R/did_ec_or.R:156-170` (`lm` drops NA rows).
- **Reproducer:** `bb/12_na.R`, `bb/11_data.R` (sections "missing ...").
  ```
  NA in x5, trial rows 1,3,5 : did_ec_ipw 2.284 4.484 | complete cases 2.333 4.508   (silent)
  NA in x5, trial rows 2,4,6 : did_ec_ipw 2.330 4.651 | complete cases 2.253 4.665   (silent)
  NA in x5, external rows    : ERROR: missing value where TRUE/FALSE needed
  NA in x5, any rows         : did_ec_aipw / did_ec_or ERROR: missing value where TRUE/FALSE needed
  NA in y3, trial rows 1,3,5 : did_ec_or 1.615 4.408 (silent) | did_ec_ipw, did_ec_aipw ERROR (same cryptic message)
  ```
- **Expected:** the paper assumes complete data (§2.1, O_i fully observed), and the docs say nothing about NA. The setup function should reject NA in the mapped columns, or the docs should define one rule.
- **Actual:** `did_ec_ipw()` with NA covariates in trial rows drops those rows from the participation model but keeps them in Δtrial. The result is neither complete-case nor an error. `did_ec_or()` silently fits each visit's model on the available rows. The other paths fail with a message that does not mention missing data.
- **Category:** implementation gap. **Severity:** misleading (silently different answers).
- **Proposed test (`test-analysis_OLE_class.R`):** `d <- SyntheticData; d$x5[1] <- NA; expect_error(setup_analysis_OLE(d, ...), "missing")`, and the same with `d$y3[1] <- NA`.

### 4. `did_ec_aipw()` and `did_ec_or()` do not check the number of outcome formulas; `did_ec_or()` needs formulas it never uses

- **Location:** `R/did_ec_aipw.R:169-174` (`Y0_models[[t]]` for `t in seq_len(n_time)`). `R/did_ec_or.R:153` (`n_time <- length(outcome_formula_ext)`, not `length(outcomes)`) and `R/did_ec_or.R:161-170` (`rct_ctrl[1:T_cross]`, `rct_trt[(T_cross+1):n_time]`). Docs: `man/did_ec_aipw.Rd`, `man/did_ec_or.Rd` ("one per time point").
- **Reproducer:** `bb/06_formulas.R`.
  ```
  did_ec_aipw, 1/2/3 formulas for 4 outcomes : ERROR: subscript out of bounds
  did_ec_aipw, 5 formulas for 4 outcomes     : silently accepted (2.130 4.180)
  did_ec_or, rct_trt of length 2 (y3, y4)    : ERROR: invalid formula NA_character_: not a call
  did_ec_or, rct_ctrl of length 2 (y1, y2)   : accepted (1.569 4.408)
  did_ec_or, ext of length 3                 : ERROR: subscript out of bounds
  did_ec_or, all of length 5                 : ERROR: arguments imply differing number of rows: 3, 2
  did_ec_or, rct_trt[1:2] = "x1 ~ x2"        : accepted, unchanged (never used)
  did_ec_or, rct_ctrl[3:4] = "x1 ~ x2"       : accepted, unchanged (never used)
  ```
- **Expected:** Eq. 3 needs μ(X, S=1, A=(1,1), t) only for t in T2, μ(X, S=1, A1=0, t) only for t in T1, and μ(X, S=0, t) for all t. The docs ask for "one per time point" for all three. `vignettes/articles/adding-a-method.Rmd` says formula counts are validated in `estimate()`, as `ec_aipw()` does. A mismatch should stop with a message about the count.
- **Actual:** errors that do not explain the problem, a too-long vector that is silently accepted, and an asymmetric requirement in `did_ec_or()` that the docs do not describe.
- **Category:** implementation gap and documentation error. **Severity:** gap.
- **Proposed test:** `expect_error(run_analysis(setup_analysis_OLE(..., did_ec_aipw(ps, outcome_formula = f[1:3]), T_cross = 2)), "one outcome formula per outcome")`. Add the same test for each `did_ec_or()` vector, and a test that `length(formulas) > length(outcomes)` errors.

### 5. The vignette's `scm()` chunk reports a "95% CI" from 3 bootstrap replicates, and the chunk options hide the warning

- **Location:** `vignettes/OLE_analysis_workflow.Rmd:119-139` (`bootstrap = 3`, chunk `warning=FALSE`). `man/scm.Rd` example (`bootstrap = 50`). The defaults `nlambda = 2L` and `lambda_max = 0.1` give the grid {0, 0.1}.
- **Reproducer:** `bb/01_vignette.R` runs every chunk as written and surfaces hidden conditions:
  ```
  run_analysis(analysis)   # scm chunk
  WARNING: extreme order statistics used as endpoints   (x2, hidden in the vignette)
       point_estimates lower_CI_boot upper_CI_boot
  tau3        2.064756     0.6126673      3.738756
  tau4        3.943234     3.0094341      6.193249
  ```
  The DID chunks also hide warnings, but they produced none at B = 50.
- **Expected:** a reader copies the vignette. An interval made from the extreme values of 3 replicates is not a 95% CI. The text should say so, or the chunk should use a meaningful B with `eval = FALSE`, or with precomputed output.
- **Actual:** the vignette presents it as an ordinary result, with no caveat about B or runtime. One default SCM run with B = 200 needs about 10,000 conic solves on SyntheticData; B = 2 already takes about 20 s.
- **Category:** documentation. **Severity:** misleading.
- **Proposed test:** none in testthat. Add a vignette-lint check that no OLE chunk sets `warning=FALSE` together with a bootstrap of fewer than 50 replicates.

### 6. `scm()` lambda grid: contradictory or invalid settings are accepted, and the selected lambda is never reported

- **Location:** `R/scm.R:64-66` (validation), `R/scm.R:204-230` (`.scm_lambdacv`, `seq(lambda_min, lambda_max, length.out = nlambda)`), `man/scm.Rd`.
- **Reproducer:** `bb/07_scm_args.R`, `bb/08_scm_run.R grid`.
  ```
  scm(lambda_min = 0, lambda_max = 0.1, nlambda = 1) -> accepted; result identical to lambda = 0 (2.0648 3.9432)
  scm(lambda_min = 0, lambda_max = Inf)               -> accepted; run_analysis: ERROR: 'to' must be a finite number
  scm(lambda_min = 0.05, lambda_max = 0.05, nlambda = 5) -> accepted (5 identical CV fits)
  ```
  With `nlambda = 1`, the leave-one-out CV still solves m problems (100 on SyntheticData) and selects nothing.
- **Expected:** Remark 4 chooses λ by leave-one-out CV on the external controls. The docs ("Minimum/Maximum penalty parameter for LOOCV") do not say that the grid is linear, that `nlambda = 1` means `lambda_min`, or what the CV criterion is. `lambda_max = Inf` and `lambda_max > lambda_min` with `nlambda = 1` should be rejected. The chosen λ should be returned, or at least printed when `quiet = FALSE`.
- **Category:** implementation gap and documentation. **Severity:** gap.
- **Proposed test (`test-scm.R`):** `expect_error(scm(lambda_max = Inf))` and `expect_error(scm(lambda_min = 0, lambda_max = 0.1, nlambda = 1))`. The second could instead warn.

### 7. `scm()` fails on factor covariates, which the DID methods accept

- **Location:** `R/scm.R:115-116` (`t(as.matrix(df[..., c(covariates, outcomes)]))` gives a character matrix).
- **Reproducer:** `bb/15_factor.R`. With `x3` as a factor, `did_ec_ipw()` and `did_ec_or()` return the numeric-x3 values (2.323 4.633; 1.569 4.408). `scm()` gives `ERROR: Cannot convert object of class <matrix/array> to a CVXR Expression.`
- **Expected:** `covariates_col_name` is documented only as "Character vector of covariate column names". Either `scm()` handles factors (`model.matrix`) or the docs and `setup_analysis_OLE()` require numeric covariates with a clear error. Related design question: Eq. 7 matches on raw z, and the paper does not say whether to standardize. Covariate units therefore weight the match (`x5 * 10` changes tau3 from 2.065 to 1.989, `09_scale.out`), and the docs should say so.
- **Category:** implementation gap, documentation, design question. **Severity:** gap.
- **Proposed test:** `expect_error(run_analysis(<scm analysis with factor x3>), "numeric")`, or `expect_no_error()` if factors are supported.

### 8. `alpha = 0` and `alpha = 1` are accepted and give an NA or a degenerate interval

- **Location:** `R/analysis_class.R:52` (`assert_number(alpha, lower = 0, upper = 1)`, a closed interval).
- **Reproducer:** `bb/03_ci.R` (alpha section).
  ```
  alpha = 0 : tau3 2.323  [-0.608, NA]      (+ "extreme order statistics" warnings)
  alpha = 1 : tau3 2.323  [2.355, 2.355]    (an interval that excludes its own estimate)
  ```
- **Expected:** a significance level lies in (0, 1).
- **Category:** implementation gap. This is shared with `setup_analysis_primary()`. **Severity:** gap.
- **Proposed test:** `expect_error(setup_analysis_OLE(..., alpha = 0))` and `expect_error(setup_analysis_OLE(..., alpha = 1))`.

### 9. The minimum `bootstrap = 2` gives meaningless intervals, and `bca` with B < n is slow or fails

- **Location:** `R/did_ec_ipw.R:56`, `R/did_ec_aipw.R`, `R/did_ec_or.R:71`, `R/scm.R:69` (`lower = 2`). `R/method_class.R:113-121`.
- **Reproducer:** `bb/03_ci.R`, `bb/17_bca.R did`.
  ```
  did_ec_or(bootstrap = 2): tau4 4.408  [3.876, 4.106]   (estimate outside its "95% CI")
  did_ec_aipw(bootstrap = 2): tau3 2.130 [-0.790, 0.334]
  did_ec_ipw(bootstrap = 2, bootstrap_ci_type = "bca"): ERROR: estimated adjustment 'w' is infinite
  did_ec_ipw(bootstrap = 10, "bca"): 3.0 s  vs  bootstrap = 400, "bca": 2.0 s   (B < n triggers n = 300 jackknife refits)
  ```
  For `scm()`, `norm` with B = 4 took 54 s and `basic` took 43 s. `bca` with B = 4 had not finished after about 23 minutes and was killed by `timeout 1500` (exit 124; `17_bca_scm.out`), because each of the 300 jackknife refits runs one optimization per trial control.
- **Expected:** the docs say only "at least 2". Either raise the minimum, or warn when B is too small for the chosen `conf` and type. The docs should state that `bca` needs B > n (or warn about the jackknife cost, especially for `scm()`).
- **Category:** design question and documentation. **Severity:** gap.
- **Proposed test:** `expect_warning(run_analysis(<did_ec_ipw, bootstrap = 10>), "bootstrap")`, if a warning is adopted.

### 10. The data contract is not checked: empty arms and duplicated outcomes

- **Location:** `R/analysis_class.R:44-72`, `R/analysis_OLE_class.R:89-119`.
- **Reproducer:** `bb/11_data.R`.
  ```
  no trial controls (S==1 & A==0 removed): did_ec_ipw ERROR: missing value where TRUE/FALSE needed
                                           did_ec_or  ERROR: 0 (non-NA) cases
  outcome_col_name = c("y1", "y1", "y3", "y4"): accepted silently, tau3 3.100 tau4 5.409 (vs 2.323 4.633)
  ```
- **Expected:** Eq. 3-5 need all three groups (trial treated, trial control, external). An empty group, or duplicated outcome columns (Period I would then be visit 1 twice), should be rejected in `setup_analysis_OLE()` with a clear message.
- **Category:** implementation gap. **Severity:** gap.
- **Proposed test:** `expect_error(setup_analysis_OLE(..., outcome_col_name = c("y1", "y1", "y3", "y4"), ...), "unique")`, plus a test that removes each group.

### 11. The OLE result is underspecified: positional row names, no SE, no SCM diagnostics

- **Location:** `R/did_ec_ipw.R:107-112`, `R/did_ec_aipw.R:124-129`, `R/did_ec_or.R:126-131`, `R/scm.R:156-161`. `R/method_class.R:123` computes `sd_boot`, which the OLE methods drop. `man/run_analysis.Rd` (`\value`).
- **Reproducer:** `bb/02_tcross.R`. With `outcome_col_name = c("y2", "y3", "y4")` and `T_cross = 1`, the rows are named `tau2` and `tau3`, but they are the effects at columns `y3` and `y4`.
- **Expected:** `?run_analysis` says only "a data frame of point estimates and bootstrap confidence intervals". The row names are 1-based positions in `outcome_col_name`, which should either be documented or replaced by the outcome names. The paper reports SEs (Table 1). The primary bootstrap result includes `standard_deviation`, and the OLE methods compute it but discard it. For `scm()`, the selected λ is not returned.
- **Category:** documentation and design question. **Severity:** polish. Row names could mislead.
- **Proposed test:** `expect_named(res, c("point_estimates", "standard_deviation", "lower_CI_boot", "upper_CI_boot"))` and `expect_identical(rownames(res), c("y3", "y4"))`, if adopted.

### 12. `run_analysis()` does not validate its arguments

- **Location:** `R/run_analysis.R:48-49`. AGENTS.md says to "Validate the arguments of exported functions with checkmate".
- **Reproducer:** `bb/11_data.R`: `run_analysis(a, quiet = "no")` gives `ERROR: invalid argument type`.
- **Expected:** `checkmate::assert_class(analysis_obj, "analysis_obj")` and `checkmate::assert_flag(quiet)`.
- **Category:** implementation gap. **Severity:** polish.
- **Proposed test:** `expect_error(run_analysis(a, quiet = "no"), "quiet")`.

### 13. Smaller documentation gaps (all docs, all polish)

- `trt_formula` (`man/did_ec_ipw.Rd`, `man/did_ec_aipw.Rd`) does not say that the model is fit on trial subjects only and replaces W11 = 1/π_A of Eq. 4 with 1/π_A(X). It also does not say when to use it. The vignette uses it without comment.
- `did_ec_aipw(outcome_formula)` does not say that the models are fit on external controls only (μ(X, S=0, A=(0,0), t), Eq. 5). A user who adds `S` or `A` to the right side gets rank-deficient fits.
- `bootstrap_ci_type` lists no allowed values (`perc`, `bca`, `norm`, `basic`). `"stud"` and `"all"` are rejected.
- No man page example runs an OLE analysis. `?run_analysis` shows only `ec_ipw()`, and the `did_*` and `scm` examples only build method objects.
- `man/SyntheticData.Rd` documents no columns, no DGP and no true effects. It also does not mention the `T_cross` column in the data, which appears in error messages (`11_data.out`).
- Method objects print as raw S4 slot dumps (`00_examples.out`), while `analysis_OLE_obj` has a `show()` method.
- `README.md` cites "R package version 0.0.4.0", but `DESCRIPTION` is 0.0.4.2.
- Citation labels disagree: `introduction.Rmd` calls the DID paper "Zhou et al. (2024a)", while the source comments (`R/did_ec_*.R`, `R/scm.R:112`) call it "Zhou 2024b".

---

## New evidence on known issues

- **#104 (formulas matched by position): confirmed for `did_ec_aipw()` and `did_ec_or()`** (`bb/06_formulas.R`, `bb/14_or_outcomes.R`; same under `load_all`).
  - `did_ec_aipw()`, `R/did_ec_aipw.R:169-174`. Formulas y1..y4 give `2.130 4.180`, `rev()` gives `2.566 4.501`, and order (y2, y1, y4, y3) gives `1.871 4.439`. A formula whose left side is not an outcome (`"x1 ~ x2 + x3"` in place of y4) is accepted and changes tau4 to `4.343`.
  - `did_ec_or()`, `R/did_ec_or.R:153-170`. Reversing `ext` gives `2.997 4.924`, reversing `rct_ctrl` gives `-1.797 1.041`, and reversing `rct_trt` gives `0.532 -1.307` (baseline `1.569 4.408`).
  - New twist: in `did_ec_or()`, `outcome_col_name` does not set which column is which visit. The formula left sides and their order do. `outcome_col_name = rev(c("y1", ..., "y4"))` gives output identical to the vignette, whereas `did_ec_ipw()` returns `-2.066 -4.058`. The two methods therefore read the time ordering from different arguments.
- **#105 (`.` in formulas): `did_ec_or()` is also affected, and it is not in #105's list.** `did_ec_or(paste(y, "~ ."), ...)` puts the other outcomes, `S` and `A` into each model. It gives `1.167 4.265` (vs `1.569 4.408`) with 32 rank-deficient prediction warnings. `trt_formula = "A ~ ."` gives `2.207 4.107` (vs `2.076 4.389` for x1..x5), with 4 rank-deficient warnings (`11_data.out`).
- **#103 (trial-status name): the `trt_formula` side is confirmed.** With the treatment column renamed to `arm`, every non-NULL `trt_formula` fails with `object 'arm' not found`, whether its left side is `arm` or `A`. `did_ec_ipw()` without `trt_formula`, `did_ec_aipw()` without it, and `did_ec_or()` all work (`11_data.out`).
- **#108 (external controls with A = 1):** all three DID methods select external controls by `S` only. Setting `A = 1` for 20 external controls leaves every estimate unchanged: `2.323 4.633`, `2.130 4.180`, `1.569 4.408`. So, unlike `ec_aipw()`, the DID methods treat them consistently as untreated, but they never check. `scm()` also selects external controls with `S == 0` only (`R/scm.R:116`); this is from reading the code, not executed.
- **#86 (rank-deficient bootstrap fits): it also occurs in a plain `run_analysis()` on the shipped `SyntheticData`, not only in the simulation fixture.** With `did_ec_or(..., bootstrap = 2000, bootstrap_ci_type = "norm")` and `set.seed(42)`, I saw 26 "prediction from rank-deficient fit" warnings. `did_ec_aipw()` in the same script gave 0 (`04_bootbias.out`). In that run the implied bootstrap bias was small for all three methods (|bias| ≤ 0.18 against an SE of about 1.0-1.6).
- **#79 (scm coverage): now exercised by black-box runs:** the default grid (`nlambda = 2`, {0, 0.1}); `parallel = "multicore"` and `"snow"` with `ncpus = 2`, which give results identical to serial for the same seed (`09_par.out`); `bootstrap_ci_type = "norm"` and `"basic"`; and `T_cross = 1` and `3`. `bca` is very slow when B < n (finding 9). Untested paths that misbehave are findings 2, 6 and 7.

---

## Unexecuted suspicions

- **The vignette needs a Suggests package without a guard.** `scm()` stops when `ECOSolveR` (Suggests) is missing (`R/scm.R:98-104`). The tests use `skip_if_not_installed("ECOSolveR")`, but the `scm()` chunk in `vignettes/OLE_analysis_workflow.Rmd:119-139` has no `eval = requireNamespace("ECOSolveR", quietly = TRUE)`. A check without Suggests would fail the vignette build. My attempt to simulate a missing package with `trace()` did not intercept the call (`20_no_ecos.out`), so this is not demonstrated.
- **The `scm()` bootstrap holds λ fixed.** λ is selected once on the full data and reused in every replicate (`R/scm.R:124-153`), so the CI ignores the uncertainty of the λ selection. This is a design question; the paper (Remark 4, §4.2) does not say whether to re-tune.
- **The `scm()` bootstrap may be biased upward.** With B = 60 (`09_bigB.out`), the normal-interval centre implies a bootstrap mean about 0.30 above t0 for both visits (SE about 0.8, so roughly 3 Monte Carlo SEs). This may be a property of resampling a non-smooth matching estimator rather than a bug. It needs a larger B to confirm.
- **Other entry points share the `T_cross` code path.** I demonstrated finding 1 through `setup_analysis_OLE()` for the DID methods. `scm()` (`R/scm.R:109,146,160`) and `setup_simulation_OLE()` (out of scope) look likely to share the problem, but I did not run them.
- **`estimate()` is exported** (`NAMESPACE:8`). A user can call it directly and bypass every `setup_analysis_OLE()` check. I did not explore this further.

---

## Checked and found correct

- **Point estimates match the paper.** Direct transcriptions of Eq. 3, 4 and 5 / Appendix B, written from the paper only, match the package to all printed digits on `SyntheticData` (`05_hand.out`, `06_formulas.out`):
  - DID-EC-IPW with marginal π_A: `2.323352 4.63252`.
  - DID-EC-IPW with `trt_formula` (W11 = 1/π_A(X), Hajek-normalized): `2.075926 4.389438`.
  - DID-EC-AIPW: `2.130006 4.180107`.
  - DID-EC-OR, averaged over the whole trial population R: `1.568947 4.407834`.
- **Algebraic identities hold:** `did_ec_ipw("S ~ 1")`, `did_ec_or(all "~ 1")` and `did_ec_aipw("S ~ 1", "~ 1")` all equal the hand-computed unadjusted DID (`2.158304 5.803578`). DID-EC-AIPW with intercept-only outcome models equals DID-EC-IPW, as Eq. 5 implies.
- **Many visits:** with 8 visits, `T_cross = 4`, a DGP satisfying Assumption 3 (study effect Δ = 2, covariate shift) and 40 replicates at n = 2000 + 2000, the mean bias of all three DID estimators lies within 2.3 Monte Carlo SEs of 0 at every OLE visit. The tolerance of 3 SEs was set before running (`19_many_visits_mc.out`).
- **`T_cross` validation:** 0, -1, 2.5, "2", NA, `c(1, 2)`, and values ≥ the number of outcomes are all rejected with clear messages. `T_cross = 1` and a single OLE visit work. tau3 is identical whether or not y4 is supplied, and estimates do not depend on later visits.
- **CI options:** `bootstrap_ci_type` validation is correct, and `perc`, `norm`, `basic` and `bca` (B ≥ 10) all run for the DID methods. Intervals narrow monotonically as alpha grows, and lower ≤ upper in every run. Bootstrap counts below 2 and non-integer, `NA`, character and logical values are rejected.
- **Reproducibility:** the same seed gives identical results, and the parallel modes match serial exactly.
- **Arguments and inputs accepted or rejected correctly:** `setup_analysis_OLE()` rejects primary method objects and `setup_analysis_primary()` rejects OLE ones, both with clear messages. A logical treatment column works, factor or 1/2 coding is rejected with a clear message, and tibble input works.
- **`scm()` matches the paper (by reading):** the penalty λ Σ_j w_j‖z_i − z_j‖², the simplex constraints, matching on (X, Y_I), the leave-one-out CV over external controls on T2 outcomes (Remark 4), and the ATE in Eq. 9 all match `R/scm.R:176-230`.
- **Examples and vignette:** all man-page examples for the six in-scope topics, and every chunk of `vignettes/OLE_analysis_workflow.Rmd`, run without error with the installed package. The only hidden condition is the one in finding 5.
