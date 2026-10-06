# OLE methods: test-strength audit (tester 4)

## 1. Header

- **Role:** test-strength auditor for the open-label extension (OLE) methods
  `did_ec_ipw()`, `did_ec_aipw()`, `did_ec_or()` and `scm()`.
- **Commit:** 6185ba9 (worktree `agent-a81ea1649fef0ead6`). `git diff --quiet -- R/`
  succeeds at the end, so the `R/` files are original. The only untracked
  paths are mutator's `mutation_dir` folders, `.mutants-did/` and
  `.mutants-scm/`. Delete them before using this worktree for anything else.
- **R:** 4.6.1 (2026-06-24). **mutator:** 0.2.1. testthat edition 3.
- **Spec:** Zhou et al. 2024, Eq. 3 to 5 and Appendix B (DID-EC-OR, IPW and
  AIPW sample estimators), and Section 3.2, Eq. 7 to 9 (penalized SCM and
  leave-one-out cross-validation (LOOCV) for lambda).
- **Baseline:** the full suite passes under `NOT_CRAN=true` in 42 s
  (`artifacts/baseline_timing.log`). `test-full_pipeline_scm.R` takes 22.8 s
  and `test-run_analysis.R` takes 10.8 s.

Exact mutator calls. Each script set `targets` and then
`others <- setdiff(basename(list.files("R", "[.]R$")), targets)`.

```r
# R/did_ec_ipw.R, R/did_ec_aipw.R, R/did_ec_or.R  (artifacts/mutator_did.R)
set.seed(20261006)
mutator::mutate_package(
  pkg_dir = pkg, cores = 8, detectEqMutants = FALSE,
  mutation_dir = file.path(pkg, ".mutants-did"),
  max_mutants = 300, timeout_seconds = 300,
  cran = FALSE, isolate = TRUE,
  exclude_files = others,  # every R/ file except the three targets
  max_show = Inf
)
# R/scm.R  (artifacts/mutator_scm.R)
set.seed(20261007)
mutator::mutate_package(
  pkg_dir = pkg, cores = 8, detectEqMutants = FALSE,
  mutation_dir = file.path(pkg, ".mutants-scm"),
  max_mutants = 80, timeout_seconds = 600,
  cran = FALSE, isolate = TRUE,
  exclude_files = others,  # every R/ file except scm.R
  max_show = Inf
)
```

All defaults were kept: coverage-guided testing (`record_tests` backend),
`fail_fast = TRUE`, and the testthat strategy.

Artifacts are in `4-test-strength-artifacts/` (called "artifacts" below):

- `mutator_*.log`, `mutator_*.rds` and `mutator_*_mutants.csv` hold the
  status of every tested mutant.
- `mutator_*_survivors.diff` holds a compact deparsed diff of every survivor.
- `hand_mutants.R` defines the hand mutants and `drive_hand.R` runs them.
  Their diffs are in `hand_diffs/`, logs in `hand_logs/`, and the summary in
  `hand_results.csv`.
- `run_tests_in.R` runs the existing OLE-relevant tests against a package
  copy.
- `run_proposed.R` and `drive_proposed.R` run the proposed tests. The logs
  are in `proposed_logs/`, the results in `proposed_vs_mutants_final.csv`
  and `proposed_vs_mutants_scm_ci_choice.csv`, and the run against the
  original code in `proposed_on_original.log`.

The proposed tests are in `proposed-tests/`: `helper-ole.R` and test files
for ipw, aipw, or, scm and method_class.

**Hand mutants ran in a copy.** Hand mutants were applied to a copy of the
package (`artifacts/handpkg/`, copied from the worktree), never to the
worktree itself. Mutator was reading the worktree concurrently, and editing
it in place would have contaminated mutator's results. Each mutant got a
fresh copy, which was deleted afterwards.

## 2. Mutation summary

| File | Generated | Tested (sampled) | Killed | Survived | Hang/timeout | Score | Test-exec time |
|---|---|---|---|---|---|---|---|
| did_ec_ipw.R | 199 | 99 | 72 | 27 | 0 | 72.7% | 333.6 s for the three DID files together (6.4 min wall, baseline 49.7 s) |
| did_ec_aipw.R | 218 | 124 | 99 | 25 | 0 | 79.8% | (shared) |
| did_ec_or.R | 139 | 77 | 60 | 17 | 0 | 77.9% | (shared) |
| scm.R | 294 | 80 | 59 | 21 | 0 | 73.8% | 533.4 s (10.5 min wall, baseline 97.9 s) |

The DID run scored 77.0% overall (95% CI 71.9 to 81.4%, 300 of 556 mutants
sampled). The scm run scored 73.75% (95% CI 63.2 to 82.1%, 80 of 294
sampled). No tool failures occurred: 0 hangs and 0 timeouts.

Classification of the 90 survivors (diffs in `mutator_*_survivors.diff`):

| Class | ipw | aipw | or | scm | Notes |
|---|---|---|---|---|---|
| **Equivalent**: prototype default changed (`ps_formula = ""`, `method_name`, `ncpus`), which the constructor always overrides | 2 | 5 | 4 | 3 | |
| **Equivalent**: `setMethod("estimate", NULL, ...)` registers the method on ANY; dispatch for the real class is unchanged | 1 | 1 | 1 | 0 | |
| **Equivalent**: marginal `pi_AX` changed (`/n` to `*n`, ipw_085) | 1 | 0 | 0 | 0 | Hajek normalization cancels any constant treatment weight (gap 13) |
| **Equivalent**: `drop = FALSE` changed to NA/NULL on a row subset or on `Y <- df[, outcomes]` | 6 | 5 | 0 | 0 | Behavior changes only when a group has one patient, or with a single outcome, which setup forbids |
| **Equivalent**: `colnames(X) <- NULL` deleted; solver `"ECOS"` changed to `NULL` (CVXR's default solver agrees within 1e-6) | 0 | 0 | 0 | 3 | |
| **Real gap**: `drop = FALSE` changed on a **column** subset (`1:T_cross`, `(T_cross+1):n_time`) | 4 | 4 | 0 | 0 | Gap 3 |
| **Real gap**: allowed `bootstrap_ci_type` values or `assert_choice` deleted | 3 | 4 | 3 | 3 | Gap 9 |
| **Real gap**: input validation deleted or weakened (`assert_string(trt_formula)`, `assert_character(min.len)`, `assert_count(ncpus)`, `"multicore"` choice) | 1 | 1 | 3 | 2 | Gap 12 (low) |
| **Real gap**: `quiet = FALSE` messages mutated or deleted | 6 | 3 | 5 | 7 | Low severity: no OLE test uses `quiet = FALSE` |
| **Real gap**: constructor `method_name` set to NA | 1 | 1 | 1 | 0 | Low: never asserted |
| **Real gap**: row names `paste0("tau", ...)` changed to `paste0(NULL, ...)` | 1 | 0 | 0 | 0 | Gap 3 (the DID tests never check row names) |
| **Real gap, blocked by #103**: LHS rewrite of `trt_formula` deleted | 1 | 1 | 0 | 0 | No green test is possible until #103 is fixed |
| **Real gap**: `n10 <- sum(S == 1 & A != 0)` (scm_116) | | | | 1 | Gap 4 (balanced data) |
| **Real gap**: bootstrap `X10 <- d[S == 1 \| A == 0, ]` (scm_254) | | | | 1 | Gap 5 |
| **Real gap**: missing-ECOSolveR error branch (`call. = NA`) | | | | 1 | Low: the branch needs a mockable seam |
| **Total survivors** | 27 | 25 | 17 | 21 | |

## 3. Hand-written statistical mutants

There are 42 mutants (H01 to H42), each applied alone to a fresh copy:

```
Rscript artifacts/drive_hand.R '<id-regex>'
  -> for each mutant: Rscript artifacts/run_tests_in.R <copy> '<filter>'
```

The DID filter is
`did_ec|run_analysis|analysis_OLE|simulation_OLE|run_simulation|method_class`.
The scm filter is `scm|run_analysis|method_class`. Both run with
`NOT_CRAN=true`. The diffs are in `hand_diffs/<id>.diff` and the output in
`hand_logs/<id>.log`.

The last column records whether the proposed tests (section 4) kill the
mutant. Each proposed test was rerun against every mutant with
`artifacts/drive_proposed.R`.

| ID | Mutation (one line; full diff in `hand_diffs/`) | Existing suite | Killed by | Proposed tests |
|---|---|---|---|---|
| H01 | IPW: Period I gap uses only visit 1 (`rowMeans(Y_ctrl[,1:T_cross])` changed to `Y_ctrl[,1]`) | KILLED | full_pipeline_did_ec_ipw (locked values) | KILLED (3 tests) |
| H02 | IPW: Period I gap over visits `1:(T_cross+1)`, which includes the first OLE visit | KILLED | full_pipeline_did_ec_ipw | KILLED |
| H03 | IPW: `tau <- mu_trt - mu_ext + bias` (sign of the DID correction) | KILLED | full_pipeline_did_ec_ipw | KILLED |
| H04 | IPW: EC OLE term divided by `length(w00)` instead of `sum(w00)` (Hajek normalization dropped) | KILLED | full_pipeline_did_ec_ipw | KILLED |
| H05 | IPW: treatment model fitted on trial and EC rows | KILLED | full_pipeline_did_ec_ipw, simulation_OLE | KILLED |
| H06 | IPW: controls weighted by `w11` instead of `w10` | KILLED | full_pipeline_did_ec_ipw (covariate `trt_formula` test only) | KILLED |
| H07 | IPW: marginal `P(A=1)` divided by N instead of n | SURVIVED | | SURVIVED: equivalent (constant weight cancels) |
| H08 | IPW: `n_ole <- T_cross` | **SURVIVED** | | KILLED |
| H09 | IPW: `drop = FALSE` removed from the Period I subset | **SURVIVED** | | KILLED |
| H10 | IPW: lower and upper CI swapped | KILLED | full_pipeline_did_ec_ipw | KILLED |
| H11 | IPW: `alpha` ignored (always 0.05) | **SURVIVED** | | KILLED |
| H12 | IPW: bootstrap statistic ignores `indices` | KILLED (error) | full_pipeline_did_ec_ipw | KILLED |
| H13 | IPW: `bias <- bias_ext - bias_ctrl` | KILLED | full_pipeline_did_ec_ipw | KILLED |
| H14 | AIPW: outcome model fitted on all subjects | KILLED | full_pipeline_did_ec_aipw | KILLED |
| H15 | AIPW: treated arm uses raw Y, not residuals | KILLED | full_pipeline_did_ec_aipw | KILLED |
| H16 | AIPW: outcome model fitted on RCT controls | KILLED | full_pipeline_did_ec_aipw | KILLED |
| H17 | AIPW: EC Period I residual uses only visit `T_cross` | KILLED | full_pipeline_did_ec_aipw | KILLED (Appendix B test only) |
| H18 | AIPW: `n_ole <- T_cross` | **SURVIVED** | | KILLED |
| H19 | AIPW: `alpha` ignored | **SURVIVED** | | KILLED |
| H20 | OR: Period I trial model fitted on treated and control | KILLED | full_pipeline_did_ec_or, simulation_OLE | KILLED |
| H21 | OR: OLE trial model fitted on crossed-over controls | KILLED | full_pipeline_did_ec_or | KILLED |
| H22 | OR: standardized to the pooled trial and EC population | KILLED | full_pipeline_did_ec_or | KILLED |
| H23 | OR: EC Period I mean uses only visit `T_cross` | KILLED | full_pipeline_did_ec_or | KILLED |
| H24 | OR: number of Period I models taken as `n_time - T_cross` | **SURVIVED** | | KILLED |
| H25 | OR: `alpha` ignored | **SURVIVED** | | KILLED |
| H26 | OR: OLE trial models use `outcome_formula_ext` instead of `outcome_formula_rct_trt` | **SURVIVED** | | KILLED |
| H27 | SCM: sum-to-one constraint dropped | KILLED | full_pipeline_scm, test-scm unit | KILLED |
| H28 | SCM: nonnegativity dropped | KILLED (error) | full_pipeline_scm, run_analysis, test-scm | KILLED |
| H29 | SCM: penalty dropped (`0 * ...`) | KILLED | **only** full_pipeline_scm (`skip_on_cran`) | KILLED |
| H30 | SCM: match on covariates only | KILLED | **only** full_pipeline_scm | KILLED |
| H31 | SCM: match on Period I outcomes only | KILLED | **only** full_pipeline_scm | KILLED |
| H32 | SCM: LOOCV picks `which.max` (the worst lambda) | **SURVIVED** | | KILLED |
| H33 | SCM: LOOCV leaves the held-out EC in the donor pool (leakage) | **SURVIVED** | | KILLED |
| H34 | SCM: LOOCV prediction uses donors `-1` instead of `-loocv` | **SURVIVED** | | SURVIVED (selected lambda unchanged on test data; see gap 6) |
| H35 | SCM: `n10 <- sum(S == 1 & A == 1)` | **SURVIVED** | | KILLED |
| H36 | SCM: bootstrap statistic ignores `indices` | KILLED (error) | full_pipeline_scm, run_analysis, test-scm (boot.ci errors on constant t) | KILLED |
| H37 | SCM: `alpha` ignored | **SURVIVED** | | KILLED |
| H38 | SCM: CI widened with `pmin`/`pmax` to always contain tau | SURVIVED | | SURVIVED: behaviorally equivalent when the percentile CI already contains tau (true on all test data) |
| H39 | SCM: synthetic control is the unweighted EC mean | KILLED | full_pipeline_scm, test-scm | KILLED |
| H40 | `.run_bootstrap`: no strata (shared helper) | KILLED | all three DID full pipelines (locked CIs) | KILLED |
| H41 | `.run_bootstrap`: `conf = 1 - alpha/2` | KILLED | all three DID full pipelines | KILLED |
| H42 | SCM: matching also uses the OLE (post-crossover) outcomes | KILLED | **only** full_pipeline_scm | KILLED |

The existing suite kills 27 of the 42 mutants. Of the 15 survivors, 2 are
equivalent (H07 and H38) and 13 are real gaps: H08, H09, H11, H18, H19,
H24, H25, H26, H32, H33, H34, H35 and H37. The proposed tests kill 39
of 42; the 3 left are H07, H38 and H34. Four SCM kills (H29, H30, H31 and
H42) depend entirely on a `skip_on_cran()` test, so in CRAN mode
(`cran = TRUE`, as R CMD check runs on CRAN) they would survive. This
strengthens #79's point; it is not a new issue.

The proposed tests all pass on the original code
(`artifacts/proposed_on_original.log`: 18 tests, all PASS).

## 4. Real test gaps, most severe first

Each entry gives the reproducer, the proposed test, and its result on the
mutant and the original. Command for the proposed tests:

```
Rscript artifacts/run_proposed.R <pkg copy> '<file filter>'
```

The results are in `proposed_logs/<id>.log` (mutant) and
`proposed_on_original.log` (original).

### Gap 1. Every DID test has `T_cross == n_time - T_cross == 2`, so confusing Period I length with OLE length is invisible

SyntheticData has 4 visits and `T_cross = 2`. The OLE simulation fixtures
and `make_OLE_sim_data()` use the same split. Any code that uses `T_cross`
where `n_time - T_cross` is meant gives the same result.

```diff
# H08 (H18 is the same in did_ec_aipw.R)
-  n_ole <- ncol(Y) - T_cross
+  n_ole <- T_cross
# H24 (did_ec_or.R)
-  model_list_rct_pc <- lapply(seq_len(T_cross), \(t) {
+  model_list_rct_pc <- lapply(seq_len(n_time - T_cross), \(t) {
```

Existing suite: `SURVIVED` (`hand_logs/H08...log`: PASSED_EXPECTATIONS 65,
FAILED_TESTS 0; the same for H18 and H24).

**Proposed:** `test-did_ec_{ipw,aipw,or}.R`, "... with intercept-only
models is the unadjusted DID". It uses `make_ole_data()` (60/30/45 patients,
5 visits) and loops `T_cross` over 1 to 4. With `S ~ 1`, `NULL` treatment
model, and `y ~ 1` outcome models, all three estimators reduce exactly to
the plain difference of group means, which `unadjusted_did()` computes with
no package code. The tests also check the row names.

- On the mutant: `FAIL` (H08, H18, H24; `proposed_logs/H08*`, `H18*`,
  `H24*`).
- On the original: `PASS`.

### Gap 2. `alpha` never differs from 0.05 in any OLE test, so ignoring it is invisible

```diff
# H11, H19, H25, H37: one per estimate() method
-    bootstrap_ci_type = method@bootstrap_ci_type, alpha = alpha,
+    bootstrap_ci_type = method@bootstrap_ci_type, alpha = 0.05,
```

Existing suite: `SURVIVED` for all four. The `run_analysis()` alpha test
(test-run_analysis.R:175-200) covers only `ec_ipw()`.

**Proposed:** "... confidence intervals honour alpha" in each of the four
proposed files. Using the same seed, the 50% CI must lie strictly inside
the 95% CI. The `scm` version carries `skip_on_cran()` and takes about 20 s.

- On the mutant: `FAIL` (H11, H19, H25, H37).
- On the original: `PASS`.

### Gap 3. Single-visit shapes (`T_cross = 1` or one OLE visit) are never exercised, so `drop = FALSE` is unprotected

```diff
# H09 (and mutator ipw_163/164/185/186, aipw_190/191/197/198)
-  bias_ctrl <- sum(w10_ctrl * rowMeans(Y_ctrl[, 1:T_cross, drop = FALSE])) /
+  bias_ctrl <- sum(w10_ctrl * rowMeans(Y_ctrl[, 1:T_cross])) /
```

With `T_cross = 1`, `rowMeans()` errors on a vector. With one OLE visit,
`colSums()` errors. Existing suite: `SURVIVED`. The mutator row-name
survivor ipw_075 (`paste0(NULL, ...)`) also survives, because the DID tests
never check row names.

**Proposed:** the same loop as gap 1 (`T_cross` in 1:4, so n_ole is 4 to 1)
together with `expect_identical(rownames(res), paste0("tau", ...))`.

- On the mutant: `FAIL` for H09, MUT_did_ec_ipw.R_164,
  MUT_did_ec_aipw.R_198 and MUT_did_ec_ipw.R_075.
- On the original: `PASS`.

### Gap 4. Every scm test has equal arm sizes (100/100 or 10/10), so using the wrong arm's count is invisible

```diff
# H35; mutator scm_116 is the same as A != 0
-  n10 <- sum(S == 1 & A == 0)
+  n10 <- sum(S == 1 & A == 1)
```

With 2:1 randomization this errors with subscript out of bounds. With
fewer treated than controls it silently drops controls. Existing suite:
`SURVIVED` (H35 and mutator scm_116). Issue #102 (an unbalanced
SyntheticDataII) is the matching fixture request.

**Proposed:** `test-scm.R`, "scm() with a dominant penalty uses
nearest-neighbour synthetic controls" (5 treated, 8 controls, 25 EC, about
7 s, not skipped on CRAN). With `lambda = 1e4`, the penalized objective in
Eq. 7 puts all weight on the nearest external control in (x, Y_I), so each
control's synthetic OLE outcome is that neighbor's outcome. The test
computes this independently with `which.min(colSums(...))` and checks it
to within 1e-5. I verified that every weight is exactly 1 at `lambda = 1e4`.
At `lambda = 100`, one subject split its weight 0.54/0.46, and at 1e6 ECOS
returned a weight of 1.02, so 1e4 is the safe range.

- On the mutant: `FAIL` (H35, MUT_scm.R_116).
- On the original: `PASS`.

This test also kills H27, H28, H29, H30, H31, H39 and H42 without relying
on `skip_on_cran`.

### Gap 5. The scm bootstrap CI is never checked against anything; it only has to contain the point estimate

`test-full_pipeline_scm.R:30-31` checks only
`lower <= point_estimate <= upper`. The scm bootstrap statistic
re-implements the estimator: there is no `.scm_core()`, unlike the rule in
AGENTS.md. So a bug confined to `.scm_boot_statistic()` cannot be seen.

```diff
# mutator scm_254 (R/scm.R:250)
-  X10 <- t(as.matrix(d[S == 1 & A == 0, c(covariates, outcomes), drop = FALSE]))
+  X10 <- t(as.matrix(d[S == 1 | A == 0, c(covariates, outcomes), drop = FALSE]))
```

Mutator status: `SURVIVED`. The bootstrap then builds "controls" from
treated and external rows.

**Proposed:** in the nearest-neighbour test, `.scm_boot_statistic()` at
the identity resample `seq_len(nrow(d))` must reproduce the same
independently derived estimates. This is the standard bootstrap invariant
`t(identity) == t0`.

- On the mutant: `FAIL` (`proposed_logs/MUT_scm.R_254.log`).
- On the original: `PASS`.

Longer term, an `.scm_core()` shared by `estimate()` and the bootstrap, as
the other three methods have, would remove this class of bug.

### Gap 6. Lambda selection is never checked; any grid value passes

`test-scm.R:37-38` checks only `expect_contains(c(0, 0.1, 0.2), lambda)`.
`test-full_pipeline_scm.R` uses `nlambda = 1`, and the `run_analysis()`
scm test (default `nlambda = 2`) checks only the output shape.

```diff
# H32
-  lambda_vals[which.min(mse_vals)]
+  lambda_vals[which.max(mse_vals)]
# H33: LOOCV leakage; the held-out EC stays in the donor pool
-      X0 <- ec[-which(row.names(ec) %in% long_term_col_name), -loocv]
+      X0 <- ec[-which(row.names(ec) %in% long_term_col_name), ]
       (and the matching Variable(dim) and y_est edits)
```

Existing suite: `SURVIVED` (H32, H33, H34).

**Proposed:** `test-scm.R`, ".scm_lambdacv picks the lambda with the
smallest held-out error". It recomputes the Eq. 9 LOOCV error for the grid
`seq(0, 0.1, length.out = 5)` through `.scm_subject_sc()`, a separate code
path. On these data the MSE path is 20.11, 18.62, 22.28, 23.43, 24.15, so
the argmin, 0.025, is interior. The test asserts that `.scm_lambdacv()`
returns that argmin.

- On the mutant: `FAIL` (H32, H33).
- On the original: `PASS`.

H34 still survives because the corrupted errors happen to share the
argmin. `.scm_lambdacv()` does not return its error path, so no black-box
test can pin it down. The remedy is the same as gap 5: have
`.scm_lambdacv()` call `.scm_subject_sc()`, or return `mse_vals`.

### Gap 7. DID-EC-OR tests always pass the same formula vector for all three groups

All OR tests (test-full_pipeline_did_ec_or.R:3-14, run_analysis,
simulation_OLE) pass identical `outcome_formula_ext`, `_rct_ctrl` and
`_rct_trt`. Any mix-up between the three slots is therefore invisible.

```diff
# H26 (did_ec_or.R)
-    lm(as.formula(outcome_formula_rct_trt[t]),
+    lm(as.formula(outcome_formula_ext[t]),
```

Existing suite: `SURVIVED`.

**Proposed:** `test-did_ec_or.R`, "did_ec_or() standardizes each group's
model to the trial covariates". It uses three different formulas
(`~ x1 + x2`, `~ x1`, `~ x2`) and an independent Eq. 3 computation: fit each
`lm` and average its predictions over the trial rows.

- On the mutant: `FAIL` (H26).
- On the original: `PASS`.

It also kills H20, H21, H22, H23 and H24 with exact derivation instead of
locked values.

### Gap 8. No DID assertion is derived independently of the code

All DID point estimates and CIs are golden values captured from the code:

- test-full_pipeline_did_ec_ipw.R:24-29 and 50-53
- test-full_pipeline_did_ec_aipw.R:30-35 and 62-65
- test-full_pipeline_did_ec_or.R:31-36
- test-full_pipeline_simulation_OLE.R:136-149

The tolerance (1e-6, or 1e-4 in the simulation test) is tight, so these do
kill most wrong-number mutants (H01 to H06, H13 to H17, H20 to H23). But
they only prove that nothing changed, not that the numbers are right, and
updating them after a refactor would silently re-baseline any error.

**Proposed** (each derived from Zhou 2024 Appendix B without package code):

- "did_ec_ipw() matches the Appendix B weighted-mean formula" uses
  `glm()` and `weighted.mean()`.
- "did_ec_aipw() matches the Appendix B weighted-residual formula" uses a
  covariate PS and a covariate treatment model.
- The OR test from gap 7.
- "... responds to outcome shifts as the DID algebra implies", for all
  three estimators. Adding 7 to every EC outcome leaves tau unchanged: this
  is the parallel-trends invariance, and it kills H04's lost
  normalization. Adding 4 to `y1` of RCT controls lowers tau by
  4/`T_cross`. Adding 4 to `y1` of EC raises it by 4/`T_cross`. Adding 4 to
  treated `y3` raises tau3 only.

These kill H01 to H06, H13 to H17 and H20 to H24 on unbalanced data and
pass on the original. H17 is notable: with a constant propensity, the EC
residuals have mean zero at every visit, so only the covariate-PS
Appendix B test catches it.

### Gap 9. The OLE constructors' `bootstrap_ci_type` choice set is untested

There are 13 mutator survivors: ipw_025/030/031, aipw_032/036/039/040,
or_040/042/043 and scm_052/055/060. Example:

```diff
-  checkmate::assert_choice(bootstrap_ci_type, c("perc", "bca", "norm", "basic"))
+  checkmate::assert_choice(bootstrap_ci_type, c("perc", NULL, "norm", "basic"))
```

Only `ec_ipw()` iterates the four types (test-method_class.R:22).

**Proposed:** `test-method_class.R`, "OLE constructors accept every
supported CI type and reject others".

- On the mutant: `FAIL` for all 6 sampled survivors I reran (ipw_031,
  aipw_032, or_040, scm_052, scm_055, scm_060).
- On the original: `PASS`.

### Gap 10. The SCM matching and penalty logic is protected only by a `skip_on_cran()` test

H29 (no penalty), H30 (covariates only), H31 (outcomes only) and H42
(matching on post-crossover outcomes) are killed only by
`test-full_pipeline_scm.R`, which skips on CRAN. The CRAN-safe tests in
`test-scm.R` (#79) let all four through. The proposed nearest-neighbour and
LOOCV tests (gaps 4 and 6) have no skip and run in about 7 s and 2 to 6 s.
They kill all four (`proposed_vs_mutants_final.csv`).

### Gap 11. The bootstrap strata and CI level are tested only through locked values

H40 (no strata) and H41 (`1 - alpha/2`) are killed today only because the
DID CI golden values shift. Stratification is a design property, and
nothing asserts it directly.

**Proposed:** `test-method_class.R`.

- ".run_bootstrap resamples within (S, A) strata": a statistic that
  returns group counts must have a bootstrap SD of 0 on 20/7/13 data.
- ".run_bootstrap returns boot.ci intervals at level 1 - alpha": the result
  must match `boot::boot.ci(conf = 0.8)` at the same seed.

On the mutant: `FAIL` (H40, H41). On the original: `PASS`.

### Gap 12. Lower-severity gaps (no proposed test written; listed for completeness)

- **`quiet = FALSE`:** 21 mutator survivors. No OLE test exercises it.
  Proposal: one `expect_output(run_analysis(a, quiet = FALSE), "Running")`
  for each method.
- **`method_name`:** 3 survivors. `show()` prints it, but
  test-analysis_OLE_class.R:98-99 checks only the class name and `T_cross`.
- **Input validation:** 7 survivors: `assert_string(trt_formula)`,
  `assert_character(min.len)` for the OR formulas, `assert_count(ncpus)`,
  and the `parallel` choice.
- **Missing-ECOSolveR branch** (scm_079): needs a mockable
  `requireNamespace` seam, per AGENTS.md.
- **LHS rewrite of `trt_formula`** (ipw_053, aipw_062): the rewrite is
  itself the defect in #103. A test with non-`S`/`A` column names cannot
  pass until #103 is fixed.
  `artifacts/check_colnames.R` reproduces the error
  `object 'trial' not found`.

## 5. Assertions that pass by construction

| Location | Assertion | What it hides |
|---|---|---|
| test-full_pipeline_did_ec_ipw.R:24-29, 50-53; test-full_pipeline_did_ec_aipw.R:30-35, 62-65; test-full_pipeline_did_ec_or.R:31-36 | Golden values from the code itself, at tolerance 1e-6 | No independent derivation. Sensitive, but an error baked in before the snapshot (or re-baselined later) passes. Only `T_cross = 2` with 4 visits and balanced 100/100/100 data, so gaps 1 to 4 and 7 cannot show. |
| test-full_pipeline_scm.R:28-29 | Golden point estimates, `nlambda = 1`, `lambda_min == lambda_max` | LOOCV selection is never run in the regression test (gap 6). |
| test-full_pipeline_scm.R:30-31 | `lower <= pe`, `upper >= pe` | Passes for any interval that contains the point estimate. A bootstrap computed on wrong rows (scm_254) and an artificially widened interval (H38) both pass (gap 5). |
| test-scm.R:37-38 | `expect_contains(c(0, 0.1, 0.2), lambda)` | Any grid value passes, including the worst lambda (H32) and LOOCV leakage (H33). |
| test-scm.R:61-62 | Row names and `is.finite()` only, on 10/10/15 data | Shape-only. Equal arm sizes hide H35/scm_116, and the CIs are unchecked. |
| test-run_analysis.R:57-59, 85-86, 122-123, 142-143 | `expect_s3_class`, `expect_true("point_estimates" %in% names(res))`, `nrow == 2` | Shape-only (and `expect_true` is against AGENTS.md). `nrow == 2` holds whether `n_ole` or `T_cross` is used, because both are 2. |
| test-full_pipeline_did_ec_ipw.R:55-67, test-full_pipeline_did_ec_aipw.R:68-80 | Marginal treatment model equals `"A ~ 1"` to 1e-12 | Holds for **any** constant `pi_A`, because the Hajek-normalized `w11` and `w10` cancel. A wrong marginal probability (H07, mutator ipw_085 `/n` to `*n`) passes. It is a valid regression test for the NA bug (#71), but it does not check `pi_A`. In this estimator `pi_A` is irrelevant whenever it is constant, so this is an equivalence, not a defect. |
| test-full_pipeline_simulation_OLE.R:136-153 | Golden bias, variance and MSE (1e-4); `coverage == c(1,1,1)`, `type_I_error == 0` over 3 replicates | `run_simulation()` keeps only the **last** OLE row (R/run_simulation.R:92-94), so errors that affect earlier OLE visits are invisible. With 3 replicates, coverage and type I error are 0/1-coarse. |
| test-run_simulation.R:155-181 | `expect_length(report@bias, 1)` and similar | Shape-only. Its `make_OLE_sim_data()` is the only unbalanced OLE fixture (40/10/30), and nothing numeric is asserted on it. |
| test-analysis_OLE_class.R:16-18, 98-99 | `T_cross`, `alpha` and `show()` output | Checks only what the setup stores. `method_name` is never checked. |

What `SyntheticData` hides:

- **Group sizes are 100/100/100:**
  - Treated and control counts are interchangeable (H35, scm_116).
  - The marginal `pi_A` is 0.5, which is moot anyway because of the
    normalization.
  - Control and EC counts are equal, so code that sizes one group by the
    other would also pass.
- **`T_cross = 2` of 4 visits:**
  - `n_ole == T_cross` (H08, H18, H24).
  - `T_cross` is never 1 and `n_ole` is never 1, so `drop = FALSE` is
    unprotected (gap 3).
  - The `T_cross` column in SyntheticData is constant 2 and unused, which
    is consistent with the scalar `T_cross` design.
- **Identical formula vectors** in every OR test (H26).
- **`alpha = 0.05` everywhere** (H11, H19, H25, H37).
- **Columns named `S`/`A`** hide the formula LHS rewrite (#103, known).

Where the proposed tests should go: in this package, tests for
`R/{name}.R` belong in `tests/testthat/test-{name}.R`.

- `test-did_ec_ipw.R`, `test-did_ec_aipw.R` and `test-did_ec_or.R` are
  new files.
- `test-scm.R` and `test-method_class.R` are additions to the existing
  files.
- `helper-ole.R` is a new helper.

The proposed DID tests run in under 10 s in total. The scm tests run in
about 15 s, plus about 20 s for the alpha test, which carries
`skip_on_cran()`.
