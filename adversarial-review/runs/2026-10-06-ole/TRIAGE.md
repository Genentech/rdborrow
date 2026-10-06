# OLE pilot triage: did_ec_ipw(), did_ec_aipw(), did_ec_or(), scm()

The four raw reports in this folder are unedited. This file merges their 46
findings into distinct items. Nothing in this run has been filed yet.

**Verified** means I reproduced the finding myself against the installed
review build (0.0.4.2, commit 6185ba9). **Testers** lists who found it
independently: 1 black-box API, 2 adversarial input and property, 3 numerical
validation, 4 test strength.

## Headline

**The DID statistics are right.** Tester 3's independent base-R versions of
DID-EC-OR, DID-EC-IPW and DID-EC-AIPW, written from Eqs 3–5 and Appendix B,
match the package:

- to 3e-13 on `SyntheticData`, at `T_cross` = 1, 2 and 3, with and without `trt_formula`
- exactly on a hand-worked case (7/6 and 7/4)
- to within 4.4e-7 across all 7,200 Monte Carlo estimates

Tester 1 independently transcribed Eqs 3–5 and also matched to every printed
digit.

The pre-registered Monte Carlo passed (400 replicates, B = 199):
- **When parallel trends hold:** all three DID estimators are unbiased, with percentile coverage 93.8–97.2%.
- **Double robustness:** DID-EC-AIPW stays unbiased when either nuisance model is wrong.
- **When parallel trends fail (designed scenario):** the bias matches the predicted 0.30 and 0.54.

Tester 2's DID properties, justified by the paper, all held to about 1e-14
over 200 random datasets.

**SCM matches the paper's Eq 7** to solver tolerance (8e-5 on a closed-form
case). Its distribution matches an independent implementation over 150
replicates. As the paper says, it is biased with only two Period I visits.

**As in the primary pilot, the defects are in inputs and robustness, not the
estimators.** The new problems specific to the OLE methods are
`T_cross` handling, the SCM solver, and SCM covariate scale.

## A. Silent wrong answers, or broken on ordinary input

| # | Finding | Testers | Verified | Category / severity |
|---|---|---|---|---|
| O1 | **#104 extends to `did_ec_aipw()` and `did_ec_or()`.** Both match formulas to visits by position. In `did_ec_or()`, reversing the formulas **flips the signs**: (1.569, 4.408) → (−1.406, −4.158). `did_ec_or()` also takes the visit order from the formulas, not `outcome_col_name`, and the formula counts are not checked | 1, 2, 3 | Yes (`did_ec_or()`) | Implementation bug / wrong. New evidence for #104 |
| O2 | **A `T_cross` that is an integer only up to floating point gives a silently different estimate.** `0.6 / 0.2` (= 2.9999999999999996) passes `checkmate::test_int()` but is never converted to an integer. `did_ec_ipw()`: tau4 3.816 → 1.507. `did_ec_aipw()`: 3.374 → 1.324. `did_ec_or()` errors. Also, the exported `estimate()` does not validate `T_cross`, so `T_cross = 0` returns placebo-phase "effects". `R/analysis_OLE_class.R:100`, `R/method_class.R:113` | 1, 2 | Yes | Implementation bug / wrong |
| O3 | **A factor treatment column with levels `c("1", "0")` passes the 0/1 check.** With `trt_formula`, `did_ec_ipw()` and `did_ec_aipw()` then model P(A = 0) as if it were P(A = 1). On `SyntheticData` the estimates shift (2.205 → 2.455 in my run). Under stratified randomization, IPW goes from 3.35 to 8.00 against a true effect of 3.15 | 2 | Yes | Implementation bug / wrong |
| O4 | **`scm()` never checks the solver status.** Inaccurate or iteration-limited solutions go into the estimate: 90 "Solution may be inaccurate" warnings with data ×10, and weights as low as −0.061 (the paper requires w ≥ 0). With data ×100, or age in days, ECOS reports "infeasible" on a problem that is always feasible, and `scm()` stops with a cryptic error. `scm()` offers no other solver. `R/scm.R:186-189`, `219-222` | 1, 2, 3 | Partly: I confirmed the scale sensitivity; the warnings and failures are from the testers' reproducers | Implementation bug / wrong |
| O5 | **`scm()` matches on raw, unstandardized covariates and outcomes, so its estimate depends on the units.** On `SyntheticData`, x4 and x5 make up 91% of the squared distance. Multiplying `x5` by 10 moves the SCM estimates from (2.142, 4.594) to (1.989, 4.165); `did_ec_or()` is unchanged at (1.569, 4.408). The paper's Eq 7 does not specify scaling | 2, 3 | Yes | Method limitation and documentation gap / misleading. Design question: standardize, or document? |

## B. Robustness and input validation

| # | Finding | Testers | Verified | Category / severity |
|---|---|---|---|---|
| O6 | **Missing values aren't rejected.** `did_ec_ipw()` and `did_ec_aipw()` return an `NA` estimate next to a finite CI: `boot.ci()` keeps only the replicates without the incomplete patient (71 of 200). `did_ec_or()` silently fits each visit on its complete cases (1.569, 4.408 → 1.714, 4.513 for one missing value). `scm()` fails with a CVXR error. This is the same gap as primary pilot B1 | 1, 2 | No | Implementation bug / misleading |
| O7 | **`scm()` input limits.** It crashes with 2 or fewer external controls (a missing `drop = FALSE`) and gives a cryptic CVXR error with factor covariates, which the DID methods accept | 1, 2, 3 | No | Implementation bug / gap |
| O8 | **Smaller validation gaps, the same kind as primary B2:** `alpha` 0 or 1 accepted (0 gives an NA bound; 1 gives an interval that excludes its estimate); empty arms and duplicated outcome names accepted; non-syntactic column names fail cryptically (the `check.names` cause behind #106); `run_analysis()` arguments not validated; tiny bootstrap counts give meaningless CIs; `bca` with B < n runs n extra fits, and an `scm()` run with B = 4 had not finished after about 23 minutes; `nlambda = 1` silently ignores `lambda_max`; `lambda_max = Inf` is accepted and then fails | 1, 2, 3 | No | Gap / polish |

## C. New evidence for known issues (add as comments)

- **#104:** O1 above.
- **#105:** `did_ec_or()` is also affected by `.` in formulas.
- **#103:** every non-NULL `trt_formula` fails when the treatment column is not named `A`.
- **#108:** all four OLE methods select external controls by S alone and ignore `A`.
- **#86:**
  - It happens in a plain `run_analysis()` on `SyntheticData`: 26 of 2,000 bootstrap replicates for `did_ec_or()`.
  - With tiny arms, rank deficiency reaches the reported point estimate itself (−313 against a true effect of 1.5).
- **#79:** the parallel modes, the default lambda grid and the `norm`/`basic` CI types now have black-box runs; parallel results equal serial ones. The SCM matching and penalty logic is protected only by a `skip_on_cran()` test.

## D. Documentation

| # | Finding | Testers | Category / severity |
|---|---|---|---|
| O9 | **The vignette's `scm()` chunk reports a "95% CI" from 3 bootstrap replicates,** and `warning = FALSE` hides the "extreme order statistics" warning | 1 | Documentation error / misleading |
| O10 | **Return value and arguments.** `?estimate` says it returns a list, but OLE methods return a data frame. Rows are named by position (`tau2` can be column `y3`). There is no SE column, although the bootstrap SD is computed. The selected lambda is never reported. `trt_formula` and the `SyntheticData` columns are not well documented. The README version is out of date | 1, 3 | Documentation error / polish |
| O11 | **Possible paper erratum:** §4.1 says π_A = 1/3, but its 2:1 design means 2/3 | 3 | Paper (not verified by me) |

## E. Tests

| # | Finding | Testers | Category / severity |
|---|---|---|---|
| O12 | **Every OLE fixture has 2 visits before crossover and 2 after, equal arm sizes, and alpha = 0.05,** so whole classes of error go unseen: using `T_cross` where `n_time − T_cross` is meant; ignoring alpha; single-visit paths; `scm()` assuming equal arm sizes (`n10 <- sum(S == 1 & A == 1)` survives). Mutation score: DID 77.0% (231 of 300), `scm.R` 73.8% (59 of 80); primary pilot was 92.6%. Of 42 hand-planted errors, the suite caught 27 and missed 13 real ones. Tester 4's 18 proposed tests catch 39 of the 42 | 4 | Gap / wrong (latent). Overlaps #102 (SyntheticDataII) |
| O13 | **Expected values pass by construction.** No DID expected value is derived independently. The SCM interval check passes for any interval containing the estimate. `.scm_lambdacv()` is checked with `expect_contains`, so any grid value passes. Lambda selection is never checked: picking the worst lambda survives. `did_ec_or()` tests pass the same formula vector to all three groups | 4 | Gap / misleading |
| O14 | **`scm()` has no shared core function.** `.scm_boot_statistic()` duplicates the estimator, against the `_core()` rule in AGENTS.md. A bootstrap mutant that builds "controls" from treated and external rows survives | 4 | Design / gap |

## F. Design questions (no action proposed yet)

- `scm()` selects lambda once and holds it fixed during the bootstrap. The same applies to the optimal weight in the primary methods.
- The default lambda grid is {0, 0.1}. At lambda = 0 the SCM solution is not unique (17 of 100 controls), so which lambda cross-validation picks can depend on the solver.
- SCM is biased with only two Period I visits, and its SD is about twice DID's. The paper says the same, and recommends DID.

## Proposed issues

| Issue | Covers | Priority |
|---|---|---|
| `T_cross` that is not an exact integer gives wrong estimates; `estimate()` doesn't validate `T_cross` | O2 | 1 |
| A factor treatment column passes the 0/1 check, and `trt_formula` models the wrong level | O3 | 1 |
| `scm()` does not check the solver status | O4 | 1 |
| `scm()` results depend on covariate units (standardize, or document) | O5 | 2 (design decision) |
| Missing values are not rejected (all six methods; merge with primary B1) | O6 | 2 |
| `scm()` fails with ≤ 2 external controls or factor covariates | O7 | 2 |
| Input validation gaps across methods (merge with primary B2) | O8 | 3 |
| Vignette and return-value docs | O9, O10 | 3 |
| Strengthen the OLE tests (visit splits, alpha, unbalanced arms, independent anchors) | O12, O13 | 2 |
| Give `scm()` a shared core function | O14 | 3 |
| Comments on #104, #105, #103, #108, #86, #79 | C | 1 |

## Pilot metrics

| Tester | Raw findings | Runtime | Tokens |
|---|---|---|---|
| 1. Black-box API | 13 | 45 min | ~249k |
| 2. Adversarial input and property | 10 | 24 min | ~255k |
| 3. Numerical validation | 8 | 30 min | ~238k |
| 4. Test strength | 15 test gaps | 29 min | ~265k |

All five findings I re-ran myself reproduced (O1, O2, O3, O5, and the O4 scale
sensitivity). O1 was found independently by three testers, and O4 by three.
