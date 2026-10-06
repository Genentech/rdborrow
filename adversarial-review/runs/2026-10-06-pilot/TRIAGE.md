# Pilot triage: ec_ipw() and ec_aipw()

The four raw reports in this folder are unedited. This file merges their 42
findings into 15 distinct items for the maintainer to triage. Nothing has been
filed yet.

**Verified** means I reproduced the finding myself against the installed
review build (0.0.4.2), separately from the tester's own reproducer.
**Testers** lists who found it independently. Testers 1–4 are the black-box
API tester, the adversarial-input and property tester, the numerical-validation
tester, and the test-strength auditor.

## Headline

**The statistics are right.** Tester 3's independent base-R implementation
matches the package:

- point estimates, W00 and the Eq 11 weight to 1e-14
- sandwich SEs to 1e-10
- the bootstrap to 1e-10

Its pre-registered Monte Carlo passed every criterion: coverage 0.942–0.959
and SE/SD 0.98–1.03 at N = 1200. Tester 2's 17 properties held except the
three tied to the bugs below.

**The defects are in how inputs reach the statistics:** formula handling,
column names, and validation. Four of them silently return wrong numbers.

## A. Silent wrong answers, or broken on ordinary input

| # | Finding | Testers | Verified | Category / severity |
|---|---|---|---|---|
| A1 | **`ec_aipw()` matches `outcome_formula` to outcomes by position**, while each formula's left-hand side decides what is fitted. Reordering the formulas changes τ from (−0.546, 0.540) to (−0.127, 0.121) with no message. The sandwich SE is wrong too. `R/ec_aipw.R:206-212` | 1, 2, 3 | Yes | Implementation bug / wrong |
| A2 | **A trial-status column not named `S` always errors** ("object 'in_trial' not found"). The formula's left-hand side is rewritten to the user's column name *after* `.build_analysis_df()` has renamed that column to `S`. If a same-named object exists in the user's session, it is silently used instead. Every test, vignette and example uses `S`, so nothing caught it. `R/ec_ipw.R:96`, `R/ec_aipw.R:117`; probably also `R/did_ec_ipw.R:85` and `R/did_ec_aipw.R:99` (not yet verified) | 1, 2, 3, 4 | Yes | Implementation bug / wrong |
| A3 | **Model formulas aren't restricted to the declared covariates.** Three symptoms with one root cause: (a) `ps_formula = "S ~ ."` puts the outcomes and `A` into the participation model (τ −0.197 → 0.036); (b) a covariate or outcome named `A` or `S` collides with the internal columns, and is renamed `A.1`/`S.1` while the formula silently uses the treatment or trial indicator (τ −0.002 → 0.92 for an outcome named `A`); (c) a formula variable that isn't in the data silently resolves to a same-named object in the user's session (an added `z` moved τ from −0.197 to −0.199). `R/method_class.R:129-136` and the formula evaluation in each method | 1, 2 | Yes, all three | Implementation bug / wrong |
| A4 | **External patients coded `A = 1` are accepted.** EC-IPW counts them as controls; EC-AIPW leaves them out of its outcome model. The two methods are inconsistent, and if those patients really were treated, the estimate is biased (τ −1.16 → −3.22 at w = 1 in tester 2's data). Nothing checks that external patients are untreated | 1, 2 | Partly: relabeling alone leaves EC-IPW unchanged, which confirms it ignores `A` for external patients | Implementation bug / misleading |

## B. Robustness and input validation (loud failures or missing checks)

| # | Finding | Testers | Verified | Category / severity |
|---|---|---|---|---|
| B1 | **Missing values aren't rejected.** EC-IPW returns `NA`, which spreads to other outcomes' SEs. With bootstrap, an `NA` estimate comes back next to a finite CI. Other paths fail cryptically | 1, 2 | No (tester reproducers) | Implementation bug / misleading |
| B2 | **Smaller validation gaps:** empty arms return `NaN`; `alpha` accepts 0 and 1; `bootstrap_ci_type` is silently ignored without `bootstrap`; factor or character S/A columns pass validation then fail cryptically; several invalid inputs fail late with low-level errors | 1, 2 | No | Gap / polish |
| B3 | **Sandwich variance robustness.** (a) Both sandwiches build N×N matrices with `diag()`, so memory grows as 8N² bytes (670 MB at N = 8,200; 2.1 GB at N = 16,000). (b) Collinear or aliased covariates give a valid estimate, then a cryptic LAPACK error, even when that block has zero weight. (c) EC-AIPW's sandwich fails once a covariate reaches about 1e6 in magnitude. (d) EC-AIPW's sandwich refits the outcome model on all rows, so data-dependent bases (`ns()`, `bs()`) differ from the point estimate's (0.07% SE difference) | 2, 3 | No | Implementation bug / gap |
| B4 | **New evidence for #86.** EC-AIPW's bootstrap has the same non-estimable-prediction problem as the DID methods: 52 of 400 replicates were affected, matching the expected 13.4%, and their mean differed from the clean replicates by about 0.7. EC-IPW is unaffected | 2 | No | Add to #86 |

## C. Documentation

| # | Finding | Testers | Verified | Category / severity |
|---|---|---|---|---|
| C1 | **The paper's printed variance formulas (Eqs 13 and 16) omit cross-covariance terms; the code correctly includes them** (delta method on the full Σ). The code comments cite Eqs 13 and 16 as if the code followed them. The printed formula overstates the SE by up to 19% (coverage 0.982 vs 0.950 for the code). **Nobody should "fix" the code to match the paper.** Probably an erratum worth raising with the authors | 3 | Yes: Eq 13 on p. 801 prints Σ₁₁ + (1−w)²Σ₂₂ + w²Σ₃₃, with no cross terms | Documentation error (and a probable paper erratum) / misleading |
| C2 | **`weight = NULL` is described as "data-adaptive" and "minimizing variance".** Eq 11 is an outcome-free approximation that assumes no bias. Shifting external outcomes by +50 leaves it at 0.1475 while τ moves to −7.6. The code matches the paper; the wording oversells it | 1, 3 | Consistent with my #92 analysis | Documentation error / misleading |
| C3 | **Small doc inconsistencies:** the paper is cited as 2024, though it was published in 2025; code comments call it "2024a" and the vignette "2024b"; `ec_aipw.Rd` gives the wrong default for `bootstrap_ci_type`; `run_analysis.Rd` says "standard errors" for the `standard_deviation` column and doesn't explain the `tau1..T` row names; the `setup_analysis_primary()` example prints nothing; vignette bootstrap chunks have no seed; the README version is out of date; progress output uses `cat()` | 1, 3 | Citation year: yes | Documentation error / polish |

## D. Tests

| # | Finding | Testers | Verified | Category / severity |
|---|---|---|---|---|
| D1 | **The balanced test data hides real errors.** `SyntheticData` has π_A = 0.5 and equal arm sizes, so swapping π_A and 1 − π_A in the sandwich, or using the wrong arm size in the optimal weight, gives identical numbers. On an unbalanced subset, the same mutants give SEs 20–35% off and a weight of 0.088 instead of 0.114 | 4 | No | Gap / wrong (latent) |
| D2 | **Regression values pass by construction.** All EC regression numbers are snapshots from the original implementation (2026-04-01, commit a9a1754), never derived independently, and all use the one balanced dataset (`test-full_pipeline_ec_ipw.R:15-103`, `test-full_pipeline_ec_aipw.R:21-122`). Proposed fix: lock SEs against an independent sandwich, which testers 3 and 4 both wrote and which matches the package to 1e-6 | 3, 4 | No | Gap / misleading |
| D3 | **Specific untested paths:** `alpha` for EC-AIPW normal CIs and all bootstrap CIs; the norm, basic and bca CIs beyond "finite and ordered"; the default `bootstrap_ci_type` end to end; `ec_ipw(weight = 0)` ignoring external outcomes; bootstrap stratification; single-outcome and single-covariate runs; `ec_aipw()` argument checks; row names and `quiet` output. Mutation score excluding equivalent mutants: 92.6% (449 of 500 sampled killed; 36 real gaps). Tester 4 wrote 17 tests (P1–P17), each shown to kill its target mutants | 4 | No | Gap |

## E. Design questions (no action proposed)

- **E1.** The sandwich and the bootstrap both hold the estimated optimal weight fixed. The effect was negligible here (bootstrap SD 0.5204 fixed vs 0.5211 re-estimated). Testers: 3.
- **Checked and not a defect:** tester 1 suspected EC-AIPW's outcome-model estimating equation is scaled by 1/(1 − mean(A)) instead of 1/(1 − π_A). A constant row scale cancels in A⁻¹BA⁻ᵀ, so the variance is unaffected. Theorem 4 also confirms the outcome model is fit on all untreated patients in R ∪ E, which settles #92.

## Proposed issues

| Issue | Covers | Priority |
|---|---|---|
| Trial-status column must be named `S` (also check the DID methods) | A2 | 1 |
| `ec_aipw()` matches `outcome_formula` by position | A1 | 1 |
| Restrict model formulas to declared covariates; protect internal column names; evaluate formulas only in the data | A3 | 1 |
| Validate that external patients are untreated, and make EC-IPW and EC-AIPW consistent | A4 | 2 |
| Reject missing values and other invalid inputs early | B1, B2 | 2 |
| Sandwich variance robustness: memory, collinearity, scale, data-dependent bases | B3 | 2 |
| Comment on #86 with the EC-AIPW evidence | B4 | 2 |
| Code comments vs the paper's Eqs 13 and 16; consider raising the erratum with the authors | C1 | 2 |
| Doc fixes: the `weight = NULL` wording and the small inconsistencies | C2, C3 | 3 |
| Strengthen the EC tests: an unbalanced fixture, an independent sandwich anchor, and P1–P17 | D1–D3 | 2 |

## Pilot metrics (for phase 4)

| Tester | Raw findings | Runtime | Tokens |
|---|---|---|---|
| 1. Black-box API | 11 | 13 min | ~210k |
| 2. Adversarial input and property | 12 | 17 min | ~196k |
| 3. Numerical validation | 8 | 16.5 min | ~198k |
| 4. Test strength | 11 gaps | 33 min | ~264k |

The 42 raw findings merge into 15 items. Of the 7 findings I re-ran myself
(A1, A2, A3a–c, A4, C1), all reproduced; none was unsupported. A2 was found
independently by all four testers, and A1 by three.
