# OLE adversarial review, tester 2: adversarial inputs and properties

## Header

- **Role:** adversarial-input and property tester (issue #101, role 2), OLE module.
- **Scope:** `did_ec_ipw()`, `did_ec_aipw()`, `did_ec_or()`, `scm()` through
  `setup_analysis_OLE()` and `run_analysis()`, plus their internals.
- **Commit:** 6185ba9 (package code identical to `main`), rdborrow 0.0.4.2.
- **R:** 4.6.1 (2026-06-24). CVXR 1.9.1, ECOSolveR 0.6.1, boot 1.3.32.
- **Package loaded from:** the installed copy at
  `scratchpad/review-lib` (`.libPaths(c(<review-lib>, .libPaths())); library(rdborrow)`),
  in a clean `Rscript` process per script. Internals reached with
  `asNamespace("rdborrow")`.
- **Specification:** Zhou et al. (2024) JBS 34(6):893-921, Eq. 3-9, Remarks 2-4
  and 8-9, Appendix B (read from the PDF page images, because `pdftotext` drops
  the equations).
- **Data:** synthetic only. `r2/helper.R::make_ole()` simulates the
  Eq. 2 linear model (time-constant study effect `delta_s`, EC covariate shift,
  true period-II effects tau3 = 1.5, tau4 = 2), plus `SyntheticData`. Every
  script sets its seeds, and each output is saved next to it (`r2/NN_*.out`).
- **Scripts:** `r2/01_properties.R` ... `r2/21_synthetic_repros.R`,
  `r2/proposed_tests.R` (all proposed tests in one file; **all 10 fail on
  6185ba9**, see `r2/proposed_tests.out`; run it with
  `testthat::test_file("proposed_tests.R", reporter = "progress")` to see the
  failure messages that this report quotes for `SyntheticData`).

In the reproducers below, `LIB` stands for
`.libPaths(c("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-lib", .libPaths())); library(rdborrow)`.

## Findings (most severe first)

### F1. A factor treatment column with levels `c("1", "0")` silently reverses the treatment model in `did_ec_ipw()` and `did_ec_aipw()`

- **Location:** `R/analysis_class.R:67` (the 0/1 check accepts factors);
  `R/did_ec_ipw.R:140-143`, `R/did_ec_aipw.R:162-165` (`glm(binomial)` on the
  treatment column).
- **Reproducer:** `r2/14_factor_A_strat.R` (stratified randomization, seed 21),
  and on `SyntheticData`:
  ```r
  LIB
  m <- did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5",
    trt_formula = "A ~ x1 + x2 + x3 + x4 + x5", bootstrap = 2)
  fit <- function(d) { set.seed(1); run_analysis(setup_analysis_OLE(d, "S", "A",
    c("y1","y2","y3","y4"), c("x1","x2","x3","x4","x5"), m, 2))$point_estimates }
  d_f <- SyntheticData; d_f$A <- factor(d_f$A, levels = c(1, 0))
  fit(SyntheticData)  #> 2.08 4.39
  fit(d_f)            #> 2.59 4.88
  ```
- **Expected:** the same estimate as 0/1 numeric coding, or an error.
  `setup_analysis_OLE()` documents no type requirement and accepts the column
  because `factor(...) %in% c(0, 1)` matches on labels.
- **Actual:** for a binomial factor response, `glm()` models P(second level),
  that is P(A = 0 | X), and the code uses it as `pi_AX` = P(A = 1 | X)
  (`w11 <- 1 / pi_AX`). Under stratified randomization (P(A = 1) = 0.9 if
  x2 = 1, otherwise 0.3; truth tau3 = 3.15, tau4 = 4.20):

  | Method | Numeric A | Factor A, levels `c("1", "0")` |
  |---|---|---|
  | `did_ec_ipw` | 3.35, 4.46 | **8.00, 9.53** (CI 7.55 to 8.37) |
  | `did_ec_aipw` | 3.15, 4.25 | **4.42, 5.97** |

  No warning. With `trt_formula = NULL`, the same data gives
  `'sum' not meaningful for factors`. `did_ec_or()` and `scm()` give the correct
  answer (they only use `A == 1`). A factor S fails in `sum(S)` with the same
  unclear error, except in `scm()`, which works.
- **Category:** implementation bug (input validation). **Severity:** wrong
  (silent).
- **Proposed test:** `r2/proposed_tests.R`, "F1 a factor treatment column is
  rejected or matches 0/1 coding". Fix: require numeric or logical S and A in
  `.validate_analysis_base()` (`checkmate::assert_numeric`/`assert_integerish`),
  or coerce to integer 0/1 in `.build_analysis_df()`.

### F2. Missing values are accepted; the methods then differ, and two give an NA estimate with a finite confidence interval

- **Location:** `R/analysis_class.R:44-72` (no missing-value check);
  `R/method_class.R:104-121` (`.run_bootstrap()` passes non-finite replicates
  to `boot.ci()`, which drops them without a message).
- **Reproducer:** `r2/21_synthetic_repros.R`, `r2/03_did_data.R` (M1-M4),
  `r2/04_na_boot.R`:
  ```r
  LIB
  d <- SyntheticData; d$x5[which(d$S == 0)[1]] <- NA
  a <- setup_analysis_OLE(d, "S", "A", c("y1","y2","y3","y4"),
    c("x1","x2","x3","x4","x5"),
    did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 200), 2)
  set.seed(1); run_analysis(a)
  #>      point_estimates lower_CI_boot upper_CI_boot
  #> tau3              NA     0.2858187      4.965522
  #> tau4              NA     1.3777771      7.559315
  ```
- **Expected:** the paper and the docs define no missing-data handling, so
  `setup_analysis_OLE()` should stop with an error that names the column. NA
  in cells that no method uses is the exception: treated-arm period-I outcomes
  and trial-control period-II outcomes (paper, Remark 2: "Y_c,II are not
  utilized"). All four methods already ignore those correctly (P14, P15 below).
- **Actual:**
  - `did_ec_ipw`/`did_ec_aipw`: the point estimate is NA, but the CI is
    finite. In `r2/04_na_boot.R`, only 71 of 200 replicates are finite (the
    resamples that happen to leave out the incomplete patient), and `boot.ci()`
    builds the CI from those 71 without a message.
  - `did_ec_or`: `lm()` drops the incomplete row from each per-visit model
    independently (complete-case analysis per visit), and the estimate changes
    without a warning: `SyntheticData` 1.569, 4.408 becomes 1.714, 4.513.
  - `scm`: `Problem data "b" contains NaN values` (a CVXR error that does not
    name the column).
- **Category:** implementation bug. **Severity:** misleading (a finite CI with
  an NA estimate; OR silently changes the analysis population per visit).
- **Proposed tests:** "F2 missing values in used columns are rejected by
  setup_analysis_OLE()" and "F2 .run_bootstrap() does not drop non-finite
  replicates silently" (a mock statistic that returns NA when row 1 is
  resampled).

### F3. `scm()` estimates depend on the units of the covariates

- **Location:** `R/scm.R:115-116` and `:177-182` (covariates and period-I
  outcomes stacked unscaled into one L2 distance); paper Eq. 7.
- **Reproducer:** `r2/11_scm_units_mc.R` (Monte Carlo, R = 40, seeds
  1001-1040, lambda = 0.01). The DGP meets the SCM assumption (Eq. 6: an
  unmeasured U with time-varying loading and no study effect). An irrelevant
  covariate "age" is expressed in years, then in days:

  | | bias tau3 | bias tau4 |
  |---|---|---|
  | age in years | 0.430 (MCSE 0.066) | 0.555 (0.075) |
  | age in days | **0.909** (0.080) | **1.130** (0.094) |

  On `SyntheticData` (`r2/21_synthetic_repros.R`): `x5 * 10` changes the
  estimates from 2.34, 4.07 to 2.45, 4.65. In `r2/05_scm_props.R` (S8),
  `x1 * 1000` moves the estimate by up to 0.89.
- **Expected:** Eq. 7 is written as an unweighted L2 distance on the stacked
  vector z_i = (X_i, Y_i,T1), so the paper does not promise unit invariance,
  and the package follows the paper. The consequence is that matching is
  dominated by whichever variable has the largest numeric range. Matching on the
  period-I outcomes, which proxy U (Section 3.2, "the performance of SCM hinges
  on how well Y_I can approximate U"), is then lost. Abadie et al. (2010) weight
  predictors through a V matrix. Neither the paper nor `?scm` says anything
  about scaling.
- **Actual:** the estimate and its bias change with the covariate units, and no
  message tells the user.
- **Category:** method limitation and documentation gap (design question:
  standardize covariates internally, or document that users must).
  **Severity:** misleading.
- **Proposed test:** "F3-F4 scm() is unaffected by the units of a covariate" in
  `r2/proposed_tests.R`. It currently fails with an ECOS error (see F4), which
  shows that F3 and F4 share one fix: standardize the stacked features before
  the solve.

### F4. `scm()` does not check the solver status: large covariates give negative weights or an unclear solver failure

- **Location:** `R/scm.R:186-188` and `:219-221` (`CVXR::psolve()` status is
  ignored; `CVXR::value(w)` is used as is).
- **Reproducer:** `r2/06_scm_edges.R` (L1), `r2/12_scm_large_cov.R`, and
  `r2/proposed_tests.R` (F4):
  - `x1 * 1e6`: one control's weights include **-0.061**, which violates the
    `w >= 0` constraint of Eq. 7 and Remark 8. The only signal is CVXR's
    generic "Solution may be inaccurate" warning. The estimate is used.
  - `x1 * 1e8`, a platelet count covariate (`rnorm(250000, 50000)`), or
    `SyntheticData$x4 * 365`: `run_analysis()` stops in `.scm_lambdacv()` with
    `Solver "ECOS" failed. Try another solver`. `scm()` offers no solver
    choice.
- **Expected:** either valid convex weights, or an error that tells the user to
  rescale the covariates.
- **Category:** implementation bug (unchecked solver status) and method
  limitation (scaling). **Severity:** misleading (negative weights) or gap
  (unclear error).
- **Proposed test:** for a 1e6-scale covariate, assert
  `all(w > -1e-6)` and `abs(sum(w) - 1) < 1e-6` on `.scm_subject_sc()` output,
  or `expect_error(..., "rescale")`. Also "F3-F4" in `r2/proposed_tests.R`.

### F5. `estimate()` is exported but does not validate `T_cross`; `T_cross = 0` returns placebo-phase "effects"

- **Location:** `R/method_class.R:67` (exported generic); the OLE `estimate()`
  methods (`R/did_ec_ipw.R:75`, `R/did_ec_aipw.R:89`, `R/did_ec_or.R:93`,
  `R/scm.R:93`) trust `T_cross`; `R/method_class.R:54` documents
  "@return A list" (OLE methods return a data frame).
- **Reproducer:** `r2/16_known_and_estimate.R`, `r2/02_did_edges.R` (E5):
  ```r
  LIB
  f <- paste0(c("y1","y2","y3","y4"), " ~ x1")
  set.seed(1)
  estimate(did_ec_or(f, f, f, bootstrap = 20), data = SyntheticData,
    outcomes = c("y1","y2","y3","y4"), treatment = "A", trial_status = "S",
    covariates = "x1", T_cross = 0)
  #> rows tau1 ... tau4, tau1 = 0 (CI 0 to 0); no error
  ```
  `1:T_cross` becomes `c(1, 0)`, so y1 alone serves as period I, and every
  visit is reported as an OLE effect. `T_cross = 2.5` returns a row
  `tau3.5` for `did_ec_ipw` and `subscript out of bounds` for `did_ec_or`.
  `T_cross = 4` gives `invalid formula NA_character_`. `estimate()` also skips
  the 0/1 checks: S coded 1/2 gives `0 (non-NA) cases`.
- **Expected:** `AGENTS.md` says to validate the arguments of exported
  functions with checkmate. `setup_analysis_OLE()` does
  (`R/analysis_OLE_class.R:100-107`), but `estimate()` bypasses it.
- **Category:** implementation bug and documentation error (return type).
  **Severity:** misleading (silent through `T_cross = 0`), limited to direct
  `estimate()` calls.
- **Proposed test:** "F5 estimate() validates T_cross" in
  `r2/proposed_tests.R`. Alternatively, stop exporting `estimate()`.

### F6. Column names that are not syntactic fail with unclear errors

- **Location:** `R/method_class.R:132` (`data.frame(Y, ...)` with the default
  `check.names = TRUE` renames columns, and later code indexes by the original
  names). The same line causes #106.
- **Reproducer:** `r2/10_names.R`:
  - outcomes `"week 26"`, `"week 52"`, ...: `undefined columns selected`
    (`did_ec_ipw`, `scm`)
  - covariate `"smn2-copies"` with a backticked formula:
    `object 'smn2-copies' not found` (`did_ec_ipw`), `undefined columns
    selected` (`scm`)
  - outcomes `"1y"`, ...: `object '1y' not found` (`did_ec_or`)
- **Expected:** these names are common in clinical data, and
  `setup_analysis_OLE()` accepts them, so they should work, or setup should
  reject them with a clear message. Tibbles work (N4).
- **Category:** implementation bug. **Severity:** gap (unclear error). Through
  #107, a backticked name that also exists in the R session could resolve to
  the session object (not executed).
- **Proposed test:** "F6 non-syntactic outcome names work" in
  `r2/proposed_tests.R` (`data.frame(..., check.names = FALSE)` should fix
  it).

### F7. Setup does not check that the trial has both arms and that external controls exist; the treatment column is not defined as the randomized arm

- **Location:** `R/analysis_OLE_class.R:51` (`@param treatment_col_name` "Name
  of the treatment column."), `:95-107` (no arm checks).
- **Reproducer:** `r2/02_did_edges.R` (E7, E8):
  - every trial patient has A = 1 (for example, a user who codes the OLE-period
    treatment, under which every trial patient is treated):
    `did_ec_ipw`/`did_ec_aipw` give `missing value where TRUE/FALSE needed`,
    from `boot.ci()` because the point estimate is NaN; `did_ec_or` gives
    `0 (non-NA) cases`.
  - no external controls: the same errors.
- **Expected:** the paper's A_i1 is the period-I randomized assignment
  (Section 2.1). The setup docs should say so, and should say that external
  controls must have A = 0 (#108). Setup should stop with an error such as
  "the trial must contain treated and control patients".
- **Category:** documentation error and implementation gap. **Severity:** gap.
- **Proposed test:** "F7 setup_analysis_OLE() requires both trial arms and
  external controls" in `r2/proposed_tests.R`.

### F8. `scm()` fails with two or fewer external controls, and with factor covariates

- **Location:** `R/scm.R:211` (`ec[..., -loocv]` without `drop = FALSE`; with
  m = 2, one column remains and is dropped to a vector, so `colSums()` fails);
  `R/scm.R:178` (the same pattern with m = 1); `R/scm.R:115-116`
  (`as.matrix()` of a data frame that contains a factor gives a character
  matrix).
- **Reproducer:** `r2/06_scm_edges.R`:
  - m = 1: `Shape dimensions must be positive.`
  - m = 2: `'x' must be an array of at least two dimensions`
  - factor covariate: `Cannot convert object of class <matrix/array> to a CVXR
    Expression.` The DID methods accept factors and character covariates (F1-F2
    in `r2/03_did_data.R`).
- **Expected:** m = 2 is degenerate but well defined (each leave-one-out fit
  puts weight 1 on the remaining control). For a factor, either dummy-code it
  or reject it with a clear message. `?scm` does not say that covariates must be
  numeric.
- **Category:** implementation bug (`drop`) and documentation gap.
  **Severity:** gap.
- **Proposed test:** "F8 scm() runs with two external controls" in
  `r2/proposed_tests.R`, plus
  `expect_error(..., "numeric")` for a factor covariate.

### F9. `alpha = 0` and `alpha = 1` are accepted

- **Location:** `R/analysis_class.R:52`
  (`assert_number(alpha, lower = 0, upper = 1)`).
- **Reproducer:** `r2/02_did_edges.R` (E11): `alpha = 0` gives
  `upper_CI_boot = NA` (only boot's "extreme order statistics" warning).
  `alpha = 1` gives a zero-width CI.
- **Expected:** `alpha` should lie in the open interval (0, 1).
- **Category:** implementation bug. **Severity:** polish.
- **Proposed test:** "F9 alpha must lie strictly between 0 and 1".

### F10. The bootstrap floor of 2 and degenerate replicates

- **Location:** `R/did_ec_ipw.R:56` and equivalents (`assert_int(bootstrap,
  lower = 2)`); `R/method_class.R:113-121`.
- **Reproducer:** `r2/02_did_edges.R` (E10), `r2/06_scm_edges.R`,
  `r2/19_const_boot.R`:
  - `bootstrap = 2`: the CI is the minimum and maximum of two replicates, with
    only a boot warning. `scm(bootstrap = 2, bootstrap_ci_type = "bca")` gives
    `estimated adjustment 'w' is infinite`.
  - If every replicate equals the same non-zero value (for example, all treated
    patients at the scale ceiling and all others at the floor at one OLE visit),
    `boot.ci()` prints "All values of t are equal to 32" to stdout and returns
    `NULL`, and then `vapply()` fails with `values must be length 2, but
    FUN(X[[2]]) result is length 0`.
- **Expected:** a clear error or warning, for example "bootstrap distribution
  is degenerate for tau4", and no printed output from package code. The floor
  of 2 is legal, but any CI it produces is meaningless.
- **Category:** implementation gap. **Severity:** polish.
- **Proposed test:** mock a constant statistic in `.run_bootstrap()` and
  `expect_error(..., "degenerate")`.

## Properties tested

Point estimates were computed through the core functions, which are the same
code `estimate()` runs before the bootstrap. Each DID property was run on one
dataset (`r2/01_properties.R`) and then on 200 random datasets
(`r2/15_property_sweep.R`: seeds 1-200, T2 from 2 to 6, T_cross from 1 to
T2 - 1, random arm sizes and shifts). The table gives the worst deviation over
the 200 datasets for the three DID methods. SCM was tested at lambda = 0 and
0.01 (`r2/05_scm_props.R`).

| # | Property | Why it should hold | DID (IPW, AIPW, OR) | SCM |
|---|---|---|---|---|
| P1 | Permuting rows leaves the estimate unchanged | every estimator is a function of the empirical distribution (Appendix B sums, Eq. 7-9) | holds (5e-15) | holds (5e-11), including at lambda = 0, where the weights need not be unique |
| P2 | Adding c to all outcomes at all visits leaves tau unchanged | DID: c cancels in each difference (Eq. 3-5, with an intercept in the outcome models). SCM: sum(w) = 1, so c cancels in the distance and in Eq. 8-9 | holds (6e-14) | holds (4e-7, solver tolerance) |
| P3 | Scaling the outcomes by k scales tau by k | DID: linear in Y | holds | not promised: Eq. 7 mixes unscaled covariates and outcomes. Fails (0.15); holds when covariates and outcomes are scaled together (1e-5) |
| P4 | Adding c to EC outcomes at every visit leaves tau unchanged | Delta_EC differences out c for IPW and AIPW (normalized W0) and OR (refitted intercept). Remark 9: DID allows a constant study gap | holds (3e-14) | not expected: SCM does not allow a study effect (Remark 3, Remark 9) |
| P5 | Adding delta_t to EC period-II outcomes changes tau_t by -delta_t | Delta_EC is linear in Y_t,EC. SCM: sum(w) = 1, and the LOOCV error is invariant | holds (4e-15) | holds (5e-13) |
| P6 | Adding c to trial-control period-I outcomes changes tau by -c | Ybar(T1) for trial controls enters Delta_trial with coefficient -1 | holds (4e-14) | n/a |
| P7 | Adding c to EC period-I outcomes changes tau by +c | the same, through Delta_EC | holds | n/a |
| P8 | Treated-arm period-I outcomes are unused | Eq. 3-5, Eq. 9: only Y_t,II of the treated enters | holds (exactly 0) | holds (0) |
| P9 | Trial-control period-II outcomes are unused | Remark 2 | holds (0) | holds (0) |
| P10 | An affine change of a covariate leaves tau unchanged | linear logistic and linear outcome models are affine-equivariant | holds (`x1 * 1e4 + 5e5`, 3e-14) | not promised (F3) |
| P11 | Duplicating every row leaves tau unchanged | glm and lm coefficients and normalized weights are unchanged | holds (6e-15) | not tested |
| P12 | Swapping visits within period I leaves tau unchanged | period I enters only through its average Ybar(T1) | holds (0) | not tested |
| P13 | Adding c to treated period-II outcomes changes tau by +c | Delta_trial is linear | holds | not tested |
| P14-15 | NA in unused cells (treated period I, control period II) is harmless | follows from P8 and P9 | holds | holds |
| X1 | With intercept-only nuisance models, IPW = OR = AIPW = raw DID of means | Eq. 3-5 reduce to the same expression when W0 is constant and mu is constant | holds (`r2/09_cross_method.R`) | n/a |
| X2 | AIPW with intercept-only outcome models equals IPW | the residuals shift each Delta by the same per-visit constant | holds | n/a |
| X3 | `trt_formula = "A ~ 1"` equals the marginal default | an intercept-only glm predicts mean(A) in the trial | holds | n/a |
| W1 | SC weights are nonnegative and sum to 1 | Eq. 7 constraints | n/a | holds to 1e-10 at ordinary scale; **fails at 1e6 scale** (F4) |
| W2 | A trial control with an exact twin in the EC pool gets weight 1 on the twin when lambda > 0 | the penalty is 0 only at the twin, and the loss is 0 there (Eq. 7) | n/a | holds (1.000000 at lambda = 0.01; 0.999993 at lambda = 0) |
| R1 | `scm(parallel = "multicore")` is reproducible under `set.seed()` | boot generates the indices before the workers run | n/a | holds, and is identical to serial (`r2/17_scm_parallel.R`) |

## New evidence on known issues

- **#104 (formulas matched by position) also affects `did_ec_or()` and
  `did_ec_aipw()`.** `r2/08_formula_position.R` and `r2/proposed_tests.R`:
  - `did_ec_or()` with the formula vectors reversed flips the sign on
    `SyntheticData`: 1.57, 4.41 becomes **-1.41, -4.16** (no message). In
    `make_ole()`: 1.39, 1.88 becomes -0.18, -0.53.
  - `did_ec_aipw()` reversed: 1.413, 1.894 becomes 1.397, 1.835. The change is
    small here because the DID differencing and a correct propensity model
    partly protect it (double robustness), but it is still wrong.
  - `did_ec_or()` takes the number of visits from `length(outcome_formula_ext)`
    (`R/did_ec_or.R:153`), not from `outcome_col_name`. Its outcomes come only
    from the formula left-hand sides. `outcome_col_name` sets only the row count
    and names. Five outcomes with four formulas give
    `subscript out of bounds` (from `boot.ci`, after the point estimate).
  - `did_ec_or()` with `outcome_formula_rct_ctrl` for period I only and
    `outcome_formula_rct_trt` for period II only (the only visits each is used
    for, `R/did_ec_or.R:161-170`) gives
    `invalid formula NA_character_: not a call` (`r2/20_or_partial.R`).
- **#108 (external controls with A = 1):** all four OLE methods select
  external controls by `S == 0` only. Their point estimates are identical
  with and without 10 ECs recoded to A = 1 (`r2/16_known_and_estimate.R`),
  so the OLE methods are consistent with one another (unlike ec_ipw and
  ec_aipw). `setup_analysis_OLE()` still accepts such data. The bootstrap
  strata then contain an extra (S = 0, A = 1) stratum, which changes the CIs
  but not the estimates.
- **#86 (rank-deficient fits):** the problem is not limited to bootstrap
  replicates; it reaches the reported point estimate.
  - With tiny arms (n1 = 3, n0 = 2, m = 4; `r2/02_did_edges.R` E6), the
    full-data point estimates are **-313.0** (AIPW) and **-330.8** (OR)
    against a truth of 1.5. Only "prediction from rank-deficient fit"
    warnings appear. The percentile CI lower bound equals the point estimate.
  - A covariate that is constant among the ECs only (x2 = 1 for every EC,
    `r2/09_cross_method.R` X4) gives non-estimable predictions in the main fit
    for both OR and AIPW (4 warnings each). The pivoted coefficient is treated
    as 0.
- **#103, #105, #106, #107:** nothing new. F6 has the same root cause as #106
  (`R/method_class.R:132`, `check.names`).

## Unexecuted suspicions

1. At lambda = 0 with more external controls than matching features, the
   Eq. 7 minimizer is not unique (the paper adopts the penalty for this reason,
   Section 3.2). Permutation invariance held with ECOS 0.6.1, presumably
   because the interior-point method returns a central solution. A different
   solver or CVXR version could select a different minimizer, so lambda = 0
   (the default `lambda_min`) could make `scm()` results depend on row order.
   Not run with another solver.
2. The SCM bootstrap reuses the full-data LOOCV lambda in every replicate
   (`R/scm.R:153`), so the CI ignores the variability of the lambda choice.
   The paper does not say how it bootstrapped SCM. Not quantified.
3. A naive bootstrap of matching-type estimators can be inconsistent (Abadie
   and Imbens, 2008). `r2/07_scm_boot_center.R` (B = 100, 3 datasets) found the
   share of replicates above t0 between 0.26 and 0.63, against 0.39 to 0.57 for
   DID-OR. This is not conclusive, so no finding is claimed. Earlier runs with
   B = 2 or 3 put the point estimate outside its own percentile CI, but that was
   small-B noise.
4. With F6 and #107 combined, a backticked non-syntactic covariate name that
   also exists as an object in the R session could resolve silently to that
   object. Not run.
5. `did_ec_ipw()` with complete separation in the participation model returns
   an estimate driven by very few ECs, with "glm.fit: fitted probabilities
   numerically 0 or 1" warnings (`r2/03_did_data.R` O1). The warnings are
   visible, so this is classed as acceptable. A weight-concentration
   diagnostic (effective sample size of W0) was not examined.

## What I checked and found correct

- **Formulas:** the DID-EC-IPW, AIPW and OR cores match Appendix B (normalized
  W11, W10, W0; residuals Y - mu(X, S = 0, t) for every group in AIPW; OR
  averages fitted values over the trial population). The SCM objective and
  constraints match Eq. 7, Eq. 8-9 and the Remark 4 LOOCV on ECs over T2.
- **Every property in the table marked "holds"**, over 200 random datasets for
  DID.
- **T_cross:** `T_cross = 1`, `T_cross = T2 - 1` (one OLE visit), and T2 = 2
  (one visit per period) all work for all four methods. `T_cross >= T2` is
  rejected by `setup_analysis_OLE()` with a clear message (acceptable
  rejection).
- **Arm sizes:** very unbalanced arms (n1 = 200, n0 = 3, m = 300) run. A single
  trial control works for `scm()`. Three ECs work for `scm()`.
- **Covariates:** factor and character covariates work in all three DID
  methods. A covariate constant across the whole dataset is handled without
  warnings. Large-magnitude covariates (1e4 scale with a 5e5 offset) leave the
  DID estimates unchanged.
- **Outcomes:** constant outcomes at every visit give tau = 0 with a CI of
  (0, 0). A constant outcome at one OLE visit works.
- **Bootstrap:** `bca` works for DID at B = 10, 50 and 200 (below and above
  n). `norm`, `basic` and `perc` work at B = 2. `scm()` with
  `parallel = "multicore"` is reproducible. Tibble input works.
- **ECs identical to the trial with no study effect** (n = 1000): all three DID
  estimators agree to within 0.015 (1.60 to 1.61 and 2.02 to 2.03, against a
  truth of 1.5 and 2.0 in one dataset; no Monte Carlo run, which is role 3's
  task).
- **Exact twin:** a trial control with an exact twin among the ECs gets
  weight 1 on the twin (lambda > 0).
