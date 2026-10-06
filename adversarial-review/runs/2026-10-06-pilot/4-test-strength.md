# Test-strength audit of `ec_ipw()` and `ec_aipw()` (pilot, issue #101)

## 1. Header

| Item | Value |
|---|---|
| Role | 4, test-strength auditor |
| Commit | `6185ba943a0d3dc8357966ace0aac5d5921fb9ac` (package code identical to `main` at 6185ba9) |
| R | 4.6.1 (2026-06-24) |
| mutator | 0.2.1 (testthat 3.3.2, boot 1.3.32, covr 3.6.5) |
| Baseline | `NOT_CRAN=true devtools::test()`: 139 tests, 416 expectations passed, 0 failures, 20 known warnings (#86) |
| Scope | `R/ec_ipw.R`, `R/ec_aipw.R`, `R/ec_weights.R`, `R/method_class.R` (`.run_bootstrap()`, `.build_analysis_df()`) |
| Artifacts | `review-pilot/4-test-strength-artifacts/` (scripts, logs, mutant diffs, `mutator_main.rds`) and `review-pilot/proposed-tests/` |

All mutation work ran on copies. mutator ran on `mutator-run/pkgcopy/`, a copy of
`DESCRIPTION NAMESPACE R tests data inst man` inside the worktree. Each
hand-written mutant ran in its own throwaway copy, `mutator-run/hand-<id>/`,
deleted afterwards. The only in-place edit (H01, plus H02 cut short when I
switched to copies) was restored. At the end `git diff --quiet -- R/` succeeds
("R/ identical to HEAD"), and `git status --short` shows only the untracked
`mutator-run/` (the mutant files and the package copy, 15 MB).

### Exact mutator call

Run by `Rscript 4-test-strength-artifacts/run_mutator.R 500 main` from the worktree root:

```r
all_r <- basename(list.files("mutator-run/pkgcopy/R", pattern = "\\.R$"))
excl  <- setdiff(all_r, c("ec_ipw.R", "ec_aipw.R", "ec_weights.R", "method_class.R"))
set.seed(20261006)
mutator::mutate_package(
  pkg_dir            = "<worktree>/mutator-run/pkgcopy",
  cores              = 12,
  isFullLog          = FALSE,
  detectEqMutants    = FALSE,          # no AI equivalence classifier
  mutation_dir       = "<worktree>/mutator-run/main",
  max_mutants        = 500,
  timeout_seconds    = 300,
  max_line_deletions = 0,
  cran               = FALSE,          # NOT_CRAN=true, skip_on_cran() tests run
  fail_fast          = TRUE,
  isolate            = TRUE,
  exclude_files      = excl,
  max_show           = Inf
)                                      # strategy = "auto" -> testthat; coverage_guided = TRUE
```

`coverage_guided = TRUE` (the default) can report a mutant as SURVIVED
without running any test when covr doesn't attribute its line to a test. To
rule that out, I re-ran all 51 survivors against the **full** suite
(`devtools::test()`, `NOT_CRAN=true`, no coverage guidance) with
`par_runner.R surv 12`. All 51 still survived, so none of them is a
coverage-attribution artifact.

## 2. Mutation summary

| | Count |
|---|---|
| Mutants generated (`ec_ipw.R` 410, `ec_aipw.R` 403, `ec_weights.R` 18, `method_class.R` 85) | 916 |
| Sampled and tested (`ec_ipw` 209, `ec_aipw` 226, `ec_weights` 12, `method_class` 53) | 500 |
| Killed | 449 |
| Survived (confirmed on the full suite) | 51 |
| Hanged / timed out | 0 |
| Tool errors | 0 |
| Raw mutation score | 89.8% (95% CI 86.8 to 92.2) |
| Score excluding the 15 equivalent mutants | 449 / 485 = 92.6% |
| Runtime | baseline 48.4 s, generation 1.6 s, test execution 399.9 s; 7.5 min wall on 12 workers. Full-suite rerun of the 51 survivors: about 6 min on 12 workers |

Classification of the 51 survivors (normalized diffs: `4-test-strength-artifacts/surv_normdiff.txt`):

| Class | n | Mutants (mutator id `<file>_NNN`) | Killed by proposed test |
|---|---|---|---|
| Real gap: statistical, hidden by the balanced test data | 1 | `ec_ipw_163` (`n_ctrl <- sum(S == 1 & A != 0)`, the treated count) | P2 |
| Real gap: untested edge path | 8 | `ec_ipw_120`, `_127` (w = 0 early return deleted); `ec_ipw_208`, `_209`, `ec_aipw_111`, `_159`, `_170` (`drop = NA/NULL`: single outcome under w = 0 / AIPW); `method_class_082` (`drop = NA`: single covariate) | P10, P11, P12 |
| Real gap: API contract | 12 | `ec_ipw_029`, `ec_aipw_034`, `_036`, `_037`, `_039` (default `bootstrap_ci_type` resolution); `ec_aipw_018`, `_040`, `_042`, `_047`, `_049`, `_050` (`ec_aipw()` argument checks); `ec_aipw_052` (`method_name = NA`) | P14, P15 |
| Real gap: cosmetic | 12 | `ec_ipw_091`, `ec_aipw_098`, `_107`, `_108` (row names `tau1..`); `ec_ipw_058`, `_060`, `_061`, `ec_aipw_078`, `_079`, `_080`, `_101`, `_104` (`quiet` messages) | P13, P16 |
| Real but negligible (error-message wording) | 3 | `ec_aipw_069`, `_071`, `_074` | none proposed |
| Equivalent | 15 | `ec_ipw_155`, `ec_aipw_134` (W10 is constant and cancels in Eq 11); `ec_aipw_129`, `_131` (`w11` is dead code); `ec_ipw_233` (sign of the μ10 coefficient in the w = 0 SE; φ1 and φ0 have disjoint support, so B is block-diagonal); `ec_weights_002`, `_010`, `_016` (W00 rescaled by a constant: Hajek normalization, the scale-free Eq 11 ratio, and a sandwich that is invariant to scaling an estimating equation); `ec_ipw_010`, `_012`, `ec_aipw_014`, `method_class_021`, `_022` (prototype defaults that the constructors always override); `ec_ipw_050`, `ec_aipw_057` (`setMethod("estimate", NULL, ...)` registers the method for `ANY`, so dispatch still reaches it) | none can |
| Tool failure / timeout | 0 | | |

Every proposed test passes on the original code, except P9, which exposes a
defect (G1). Each "killed by" entry was checked by running the proposed file
on that mutant (`4-test-strength-artifacts/prop_results.txt`).

## 3. Hand-written statistical mutants

Each mutant was applied alone to a fresh copy of the package. I ran the full
suite on it (`Rscript run_tests_dir.R <copy> <out>`, which calls
`devtools::test(<copy>)` with `NOT_CRAN=true`), then deleted the copy. Full
diffs and outputs are in `4-test-strength-artifacts/hand-diffs/H*.diff` and
`H*.out`; the source of every mutation is `hand_mutants.R`. Line numbers
refer to the original files.

| ID | Mutation (file:line) | Verdict | Killed by (existing suite) |
|---|---|---|---|
| H01 | `tau <- mu0 - mu1` (ec_ipw.R:198) | killed | full_pipeline_ec_ipw (3 tests), full_pipeline_simulation_primary |
| H02 | `mu0 <- (1-w)*mu10 - w*mu00` (ec_aipw.R:234) | killed | full_pipeline_ec_aipw (3), simulation_primary |
| H03 | Horvitz-Thompson: `mu00 <- colSums(w00_ext*Y_ext)/length(w00_ext)` (ec_ipw.R:183) | killed | full_pipeline_ec_ipw (3), simulation_primary |
| H04 | `phi1 <- ... / (1 - core$pi_A) / pi_S` (ec_ipw.R:255) | **survived** | none; **real gap** (π_A = 0.5 in SyntheticData) |
| H05 | w = 0 SE: `phi0 <- ... / core$pi_A` (ec_ipw.R:228) | **survived** | none; **real gap** |
| H06 | AIPW meat: swap `pi_A` and `1 - pi_A` in phi1/phi2 (ec_aipw.R:315-317) | **survived** | none; **real gap** |
| H07 | Optimal weight: `w10 <- 1 / pi_A` (ec_ipw.R:187) | survived | equivalent (W10 cancels in Eq 11) |
| H08 | `w00 = pi_SX/(1 - pi_SX)` without `(1-pi_S)/pi_S` (ec_weights.R:19) | survived | equivalent (constant rescaling, see above) |
| H09 | `w00 = ... * pi_S/(1-pi_S)` (inverted factor) (ec_weights.R:19) | survived | equivalent (constant rescaling) |
| H10 | Optimal weight uses external `m`: `n_ctrl <- sum(S == 0)` (ec_ipw.R:188) | **survived** | none; **real gap** (n10 = m = 100) |
| H11 | Optimal weight uses trial-treated count (ec_ipw.R:188) | **survived** | none; **real gap** (n10 = n11 = 100) |
| H12 | Optimal weight uses the whole trial `n` (ec_ipw.R:188) | killed | full_pipeline_ec_ipw (2), simulation_primary |
| H13 | AIPW optimal weight uses `nrow(Yr_ext)` (ec_aipw.R:226) | **survived** | none; **real gap** |
| H14 | Drop the A34 bread block (ec_ipw.R:252) | killed | full_pipeline_ec_ipw (2), snapshot values only |
| H15 | Drop the PS score from the meat: `phi_ps <- 0 * X_model` (ec_ipw.R:258) | killed | full_pipeline_ec_ipw (2), snapshot only |
| H16 | Sign flip of A44 (ec_ipw.R:244) | killed | full_pipeline_ec_ipw (2), snapshot only |
| H17 | Zero the AIPW outcome-model bread blocks (ec_aipw.R:308) | killed | full_pipeline_ec_aipw (3), snapshot only |
| H18 | Variance denominator `n` instead of `n + m` (ec_ipw.R:272) | killed | full_pipeline_ec_ipw (2), simulation_primary |
| H19 | w = 0 SE denominator `N` instead of `n` (ec_ipw.R:231) | killed | full_pipeline_ec_ipw (1), simulation_primary |
| H34 | w = 0 meat divided by `N` instead of `n` (ec_ipw.R:229) | killed | full_pipeline_ec_ipw (1), simulation_primary |
| H20 | AIPW outcome model fit on treated patients (ec_aipw.R:207) | killed | full_pipeline_ec_aipw (4), simulation_primary |
| H21 | AIPW outcome model fit on trial controls only (ec_aipw.R:207) | killed | full_pipeline_ec_aipw (4), simulation_primary |
| H22 | Swap lower/upper for the normal bootstrap CI (method_class.R:119) | killed | method_class "all bootstrap CI types return finite bounds" |
| H23 | Basic CI mapped to the `"percent"` component (method_class.R:93) | killed | same test, but **by an incidental error**, not an assertion |
| H38 | Basic CI silently computed as a percentile CI (method_class.R:93 + 1 line) | **survived** | none; **real gap** |
| H39 | Normal bootstrap CI drops boot's bias correction (method_class.R:120) | **survived** | none; **real gap** |
| H24 | Bootstrap ignores alpha: `conf = 0.95` (method_class.R:115) | **survived** | none; **real gap** |
| H25 | EC-AIPW normal CI ignores alpha (ec_aipw.R:140) | **survived** | none; **real gap** |
| H26 | EC-IPW normal CI ignores alpha (ec_ipw.R:113) | killed | run_analysis "respects alpha parameter" |
| H27 | Bootstrap strata dropped (method_class.R:108) | killed | 7 seeded-bootstrap snapshot tests, by RNG drift only |
| H28 | Stratify by S only, not S x A (method_class.R:87) | killed | same 7 snapshot tests, by RNG drift only |
| H29 | CI for every estimate taken from `index = 1` (method_class.R:116) | killed | seeded snapshot tests (tau2 bounds) |
| H30 | AIPW: outcome-model meat scaled by `1/(1-pi_A)` but bread by `1/(1-mean(A))` (ec_aipw.R:322) | killed | full_pipeline_ec_aipw (3), snapshot only |
| H31 | AIPW treated mean uses raw Y, not the residual (ec_aipw.R:220) | killed | full_pipeline_ec_aipw (4), simulation_primary |
| H32 | Re-estimate the optimal weight in every AIPW bootstrap replicate (ec_aipw.R:353) | killed | full_pipeline_ec_aipw bootstrap snapshot |
| H35 | AIPW `pi_S <- (N - n)/N` (ec_aipw.R:191) | killed | full_pipeline_ec_aipw (3), simulation_primary |
| H36 | EC-IPW variance without cross-covariances (the paper's Eq 13 form) (ec_ipw.R:272) | killed | full_pipeline_ec_ipw (2), snapshot only |
| H33 / H37 | `ps_formula` LHS forced to `"S ~"` in ec_ipw / ec_aipw (ec_ipw.R:96, ec_aipw.R:117) | survived | none. This is the **fix** for defect G1, not an error. |

Totals: 39 hand mutants, 24 killed and 15 survived. Of the survivors, 3 are
equivalent (H07-H09), 10 are real gaps (H04, H05, H06, H10, H11, H13, H24,
H25, H38, H39), and 2 are the G1 fix (H33/H37). Of the 24 kills, 11 (H14-H17,
H27-H30, H32, H36, plus H23 by error) came only from snapshot values or
seeded bootstrap streams; see section 5.

Example output (H04, `hand-diffs/H04.out`):

```
--- R/ec_ipw.R
+++ R/ec_ipw.R (mutant)
@@ -252,7 +252,7 @@
-  phi1 <- S * A * sweep(Y, 2, core$mu1) / core$pi_A / pi_S
+  phi1 <- S * A * sweep(Y, 2, core$mu1) / (1 - core$pi_A) / pi_S
$ Rscript run_tests_dir.R <copy> H04.out
SURVIVED: tests 139, failing tests 0, expectations passed 416
```

## 4. Real test gaps, most severe first

All proposed tests are in `review-pilot/proposed-tests/test-ec_independent.R`,
with helpers in `helper-independent.R`. The helpers are written from the paper
(Def 1-2, Eq 11, Theorems 3-4), not from `R/`. Reproduce with
`Rscript 4-test-strength-artifacts/run_prop.R <id>`, where `<id>` is `orig`, a
hand id (`H04`), a combination (`H33+H37`), or `surv:<mutator id>`. That
script copies the package, applies the mutant, runs `load_all()`, and runs the
proposed file. Outputs are in `prop_results*.txt`, and failure messages for
the key cases are in `show_fail.txt`. Every proposed test passes on the
original code except P9, which fails because of a real defect.

### G1. Defect hidden by the test data: `ec_ipw()` and `ec_aipw()` fail when the trial-status column is not named `S`

- **Location:** ec_ipw.R:96, ec_aipw.R:117 (`sub("^[^~]*~", paste0(trial_status, " ~"), ...)`). `.build_analysis_df()` (method_class.R:132-134) renames the column to `S`, so the rewritten formula names a column that doesn't exist. The developer article `vignettes/articles/adding-a-method.Rmd:84` says the LHS is replaced with `S`, which the code doesn't do.
- **Why tests miss it:** every test uses `trial_status_col_name = "S"`. Hand mutants H33/H37, which hard-code `"S ~"` (the fix), survive the suite.
- **Reproducer:** `Rscript rename.R` renames `S` to `trial` and `A` to `trt` in `SyntheticData` and runs both methods with `ps_formula = "trial ~ x1 + ... + x5"`:
  ```
  Error in eval(predvars, data, env) : object 'trial' not found   (ec_ipw)
  Error in eval(predvars, data, env) : object 'trial' not found   (ec_aipw)
  ```
  The same happens in `did_ec_ipw()` (did_ec_ipw.R:85), which is out of scope; I ran it once with `rename_did.R`. The issue list has no matching issue.
- **Category / severity:** implementation bug plus documentation mismatch / wrong (hard error on valid input).
- **Proposed test (P9):** the results must equal the `S`/`A` results after renaming the columns to `trial`/`trt`. **Fails on the original** (`object 'trial' not found`). **Passes on H33+H37** (all 17 proposed tests pass).

### G2. `SyntheticData` has π_A = 0.5, so swapping π_A and 1 − π_A in the sandwich is undetectable (H04, H05, H06)

- SyntheticData has n11 = n10 = n00 = 100, so π_A = 0.5, and every π_A ↔ 1 − π_A swap in the meat gives identical numbers. On an unbalanced subset (n11 = 100, n10 = 60, n00 = 80, π_A = 0.625), the mutants give SEs that are 20-35% wrong:
  - H04 (EC-IPW): SE 0.780 vs a correct 0.575.
  - H05 (EC-IPW, w = 0): SE 0.480 vs 0.601.
  - H06 (EC-AIPW): SE 0.748 vs 0.598.
- **Proposed tests:**
  - **P1:** the w = 0 EC-IPW SE equals the closed-form Hajek variance `sqrt(var_ML(Y|A=1)/n11 + var_ML(Y|A=0)/n10)`.
  - **P3/P4:** the EC-IPW and EC-AIPW sandwich SE (w ∈ {NULL, 0, 0.3, 1}) equals an independent stacked M-estimator. It writes Ψ from Theorems 3 and 4, takes the bread as a central-difference Jacobian of the mean estimating function, uses B = crossprod(Ψ)/N, and checks that the estimating equations are solved (`max|Ψ̄| < 1e-8`); tolerance 1e-6.
  - **On the original:** P1, P3, P4 pass. The production sandwich agrees with the full M-estimator to 1e-6, which is the first independent confirmation of `.ec_ipw_se()` and `.ec_aipw_se()`.
  - **On the mutants:** P3 fails on H04, P1 on H05, P4 on H06.
  - These tests also kill H14-H18, H19, H30, H34, H35 and H36 independently of the snapshots.

### G3. Equal arm sizes hide sample-size errors in the optimal weight (H10, H11, H13, mutator `ec_ipw_163`)

- Eq 11 needs n10, the number of trial controls. Using m (external) or n11 (treated) instead gives the same answer on SyntheticData. On the unbalanced subset, H10 and H13 give borrow weight 0.0879 instead of 0.114.
- **P2:** `borrow_weight` equals Eq 11 computed from an independently fitted `glm` (`(1/n10) / (1/n10 + Σw00²/(Σw00)²)`) on the unbalanced subset, for both methods. It passes on the original and fails on H10, H11, H13 and `ec_ipw_163`.

### G4. `alpha` is never exercised for EC-AIPW normal CIs or for any bootstrap CI (H25, H24)

- The only alpha test (test-run_analysis.R:175-201) checks that the EC-IPW normal CI widens, and nothing else. All EC-AIPW and bootstrap tests run at alpha = 0.05.
  - H25 (AIPW cutoff fixed at 95%): at alpha = 0.2 the CI half-width is 1.04 instead of 0.68.
  - H24 (`conf = 0.95`): bootstrap CIs are identical at alpha = 0.05 and 0.5.
- **P5:** for both methods at alpha = 0.2, `upper - tau == qnorm(0.9) * sd` and `tau - lower == qnorm(0.9) * sd`. It fails on H25.
- **P6:** with the same seed, the bootstrap CI at alpha = 0.5 lies strictly inside the one at 0.05, for both methods. It fails on H24.

### G5. The norm, basic and bca bootstrap CIs are only checked for being finite and ordered (H38, H39)

- test-method_class.R:18-40 accepts any finite, ordered interval.
  - H38 returns a percentile interval when `"basic"` is requested; it survives.
  - H39 drops boot's bias correction from the normal interval; it survives.
  - H23 was killed only because `ci[["percent"]]` happened to be `NULL`.
- **P7:** with the same seed, `basic = 2·tau − rev(perc)` and the width of the `norm` interval is `2·z·sd_boot`. It fails on H38, H22 and H23.
- **P17:** `.run_bootstrap(type = "norm")` on a simple mean statistic equals `2·t0 − mean(t*) ± z·sd(t*)`, recomputed from `boot::boot` with the same seed and strata. It fails on H39.
- bca has no independent check yet. A reference value would need its own jackknife implementation, which I didn't write.

### G6. The documented default `bootstrap_ci_type` path is never run end to end (mutator `ec_ipw_029`, `ec_aipw_034/036/037/039`)

- Every bootstrap run in the suite passes `bootstrap_ci_type` explicitly, so the advertised default (`ec_ipw(ps, bootstrap = 500)`, as in AGENTS.md and the README) is never executed.
- `ec_ipw_029` and `ec_aipw_039` leave the type `NULL` when `bootstrap` is set, and `.run_bootstrap()` then fails in `switch()`.
- **P14:** the constructors resolve the type to `"perc"` only when `bootstrap` is set, and set `method_name` (`EC-IPW`, `EC-AIPW`). It fails on all 5 mutants and on `ec_aipw_052`. P6, P13 and P16 also run the default path and fail on these mutants.

### G7. `ec_ipw(weight = 0)` is never shown to ignore external outcomes (mutator `ec_ipw_120`, `_127`)

- Deleting the w = 0 early return (ec_ipw.R:166-172) leaves results unchanged on complete data. The PS model is then fit anyway and `0 * mu00` is added, so a missing external outcome turns the estimate into `NA`. Issue #101 lists this property explicitly.
- **P10:** setting the external `y1` and `y2` to `NA` leaves `ec_ipw(weight = 0)` unchanged. It fails on both mutants.

### G8. Single-outcome and single-covariate paths are untested for EC-AIPW and for EC-IPW at w = 0 (`ec_ipw_208/209`, `ec_aipw_111/159/170`, `method_class_082`)

- The only single-outcome test (test-run_analysis.R:160-173) uses EC-IPW with the optimal weight and checks `nrow` only. A `drop = NA` or `drop = NULL` mutation then crashes the run, for example `colMeans(Yr_trt): 'x' must be an array of at least two dimensions`.
- **P11:** a single-outcome fit reproduces row 1 of the two-outcome fit, for `ec_ipw(weight = 0)` and for `ec_aipw`.
- **P12:** `covariates_col_name = "x1"` gives the same fit as `c("x1", "x2")` when `ps_formula = "S ~ x1"`.
- Both pass on the original; each fails on its mutants.

### G9. `ec_aipw()` argument validation is untested (`ec_aipw_018/040/042/047/049/050`)

- The `"stud"` rejection test (test-method_class.R:59-63) covers `ec_ipw()` only. Removing `assert_choice()` from `ec_aipw()` or dropping `"basic"`/`"norm"` from its allowed set survives.
- **P15:** `ec_aipw()` rejects `character(0)` and `"stud"`, and accepts all four CI types. It fails on all 6 mutants.

### G10. Bootstrap stratification is not asserted (H27, H28 killed only by RNG drift)

- Dropping the strata, or stratifying by S only, changes the seeded snapshot values, but only because the random stream changes. A refactor that broke stratification while drawing random numbers the same way would pass, and a correct refactor that changes the stream fails.
- **P8:** call `.run_bootstrap()` with a statistic that returns `c(mean(y1), sum(S), sum(A))`; with S x A strata, the bootstrap SD of the two counts must be exactly 0. It fails on H27 and H28.

### G11. Cosmetic: result row names and `quiet` output (12 mutants)

- **Row names** (`ec_ipw_091`, `ec_aipw_098/107/108`): `"tau"` becomes `NA` or `NULL`, giving row names `NA1` or `1`.
- **`quiet` output** (`ec_ipw_058/060/061`, `ec_aipw_078/079/080/101/104`): the messages are deleted or emptied, or `ec_aipw` prints even when `quiet = TRUE`. The quiet test (test-run_analysis.R:146-158) covers EC-IPW without bootstrap only.
- **P13:** row names are `tau1..tauT` for the sandwich and bootstrap paths of both methods.
- **P16:** `expect_silent()` by default, and the exact progress lines with `quiet = FALSE`, for both methods with bootstrap.
- Both pass on the original and fail on all 12 mutants.

## 5. Assertions that pass by construction

1. **Snapshot-only numerics.** test-full_pipeline_ec_ipw.R:15-23, 40-48, 66-74, 95-103 and test-full_pipeline_ec_aipw.R:21-29, 51-59, 81-89, 114-122.
   - These lock every point estimate, SE and CI to 10 decimals with no independent derivation. `git log -S` traces the values to commit a9a1754 (2026-04-01, "vignette test benchmarks"), which captured the vignette output of the original implementation. They detect change, not correctness.
   - Every sandwich-variance kill in section 3 (H14-H18, H30, H35, H36) comes from these snapshots alone.
   - The tolerance (relative 1e-6) is tight, so tolerance is not the problem. The problem is the reference values.
   - Also, `tol <- 1e-6` sits outside `test_that()` at line 1 of both files, which AGENTS.md disallows.
2. **One balanced dataset.** All numerical tests in scope use `SyntheticData`, with n11 = n10 = n00 = 100, π_A = 0.5 and π_S = 2/3. This makes each test blind to π_A ↔ 1 − π_A errors and to n10 ↔ n11 ↔ m errors (G2, G3).
3. **AIPW borrow weight duplicates the IPW one.** test-full_pipeline_ec_aipw.R:21 and :122 assert `borrow_weight == 0.1475196487`, which is the EC-IPW value. Eq 11 doesn't involve the outcome model, so this assertion only repeats test-full_pipeline_ec_ipw.R:15 and can't detect anything AIPW-specific.
4. **Seeded bootstrap snapshots.** test-full_pipeline_ec_ipw.R:92-103 and test-full_pipeline_ec_aipw.R:111-122 use R = 50, a fixed seed and `"perc"` only.
   - They catch any change in RNG consumption (they killed H27-H29 and H32), but they check neither the stratification nor the CI formula. They would also fail on a correct change, for example a boot release that draws differently.
5. **Shape-only checks.**
   - test-method_class.R:18-40 checks only that the four CI types are finite and ordered (H38 and H39 survive).
   - test-run_analysis.R:1-38 checks EC-IPW and EC-AIPW dispatch by type, names and `nrow` only. Line 17 uses `expect_true(all(...))`, which AGENTS.md discourages.
   - test-run_analysis.R:160-173 checks the single outcome by `nrow` only.
   - test-analysis_primary_class.R:46-56 checks `show()` for EC-IPW only.
6. **Weak inequalities.**
   - test-run_analysis.R:175-201 checks only that the alpha = 0.01 CI is wider than the alpha = 0.10 CI, for EC-IPW normal CIs only. Any cutoff function that is monotone in alpha passes, such as `qnorm(1 - alpha)` instead of `qnorm(1 - alpha/2)`, if the snapshot tests were not also there.
   - test-run_analysis.R:146-158 (`expect_silent`) covers only `quiet = TRUE` for EC-IPW without bootstrap.

## Notes for other roles (not test gaps)

- The paper's Eq 13 and Eq 16 give the variance as Σ11 + (1−w)²Σ22 + w²Σ33, without covariance terms. The code uses the full linear combination `c' Σ c`, which includes Cov(μ̂11, μ̂00) and Cov(μ̂10, μ̂00), both nonzero through the PS block. My independent M-estimator agrees with the code. H36 (the Eq 13 form) changes the SyntheticData SEs. This is a design question for role 3: the code is the standard delta-method result, and the paper's formula omits terms.
- `w11` in `.ec_aipw_core()` (ec_aipw.R:202) is dead code.
- W10 in Eq 11 is a constant, so the optimal weight is exactly `(1/n10) / (1/n10 + Σw00²/(Σw00)²)`. The `w10` arithmetic at ec_ipw.R:187-189 and ec_aipw.R:203, 226 has no effect.
