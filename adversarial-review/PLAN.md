# Adversarial review plan

Plan for rdborrow issue #101: an AI-assisted adversarial review of the package
against its methods papers. The approach, roles, rules of evidence, finding
format, and acceptance criteria are in the issue; this file covers what we
need and the order we do it in.

## 1. Papers

### Required

| # | Paper | Functions it motivates | Sections and equations the code cites | Status |
|---|---|---|---|---|
| 1 | Zhou X, Zhu J, Drake C, Pang H. Causal estimators for incorporating external controls in randomized trials with longitudinal outcomes. *JRSS-A.* 2025;188(3):791–818. [doi:10.1093/jrsssa/qnae075](https://doi.org/10.1093/jrsssa/qnae075). **Plus its supplementary material.** | **Exported:** `ec_ipw()`, `ec_aipw()`, `setup_analysis_primary()`, `setup_simulation_primary()`<br>**Internal:** `.ec_ipw_core()`, `.ec_ipw_se()`, `.ec_aipw_core()`, `.ec_aipw_se()`, `.ec_weights()` (shared with the DID weighting methods) | §2.3 Assumptions 1–5; §3.1 Theorems 1–2 (Eqs 2–5); Definitions 1–2 (Eqs 6–7); §3.3 optimal weight (Eq 11); §3.4 Theorem 3 (Eqs 12–13, EC-IPW sandwich) and Theorem 4 (Eqs 15–16, EC-AIPW sandwich); §5 simulations; supplement Figure 1 | In hand: `~/Downloads/rdborrow-papers/zhou_2025_jrssa_ec-ipw-aipw.pdf` and `..._supplement.pdf` |
| 2 | Zhou X, Pang H, Drake C, Burger HU, Zhu J. Estimating treatment effect in randomized trial after control to treatment crossover using external controls. *J Biopharm Stat.* 2024;34(6):893–921. [doi:10.1080/10543406.2024.2330209](https://doi.org/10.1080/10543406.2024.2330209). PMID 38557220. **Plus any supplementary material.** | **Exported:** `did_ec_ipw()`, `did_ec_aipw()`, `did_ec_or()`, `scm()`, `setup_analysis_OLE()`, `setup_simulation_OLE()`<br>**Internal:** `.did_ec_ipw_core()`, `.did_ec_aipw_core()`, `.did_ec_or_core()`, `.scm_subject_sc()`, `.scm_lambdacv()`, and their `_boot_statistic()` functions | Eq 3 (DID-EC-OR), Eq 4 (DID-EC-IPW), Eq 5 (DID-EC-AIPW), each with Appendix B for the sample estimator; Eqs 7–9 (SCM optimization and effect estimate); Figure 2 (conditional parallel trends); Appendix A, Remark 6; Appendices A–E are in the PDF | In hand: `~/Downloads/rdborrow-papers/zhou_2024_jbs_did-scm.pdf` |
| 3 | Shi L, Pang H, Chen C, Zhu J. rdborrow: an R package for causal inference incorporating external controls in randomized controlled trials with longitudinal outcomes. *J Biopharm Stat.* 2025;35(6):1043–1066. [doi:10.1080/10543406.2025.2489283](https://doi.org/10.1080/10543406.2025.2489283). PMID 40296214. | **The package design and simulation module:** `run_analysis()`, `run_simulation()`, `simulate_trial()`, `simulate_X_copula()`, `simulate_X_dct_mvnorm()`, `simulate_X_mixture()`, `simulate_trt_assign()`, `simulate_trial_status()`, `simulate_outcome_from_model()`, and the report metrics (bias, variance, MSE, coverage, type I error, power)<br>**Also:** the original implementation choices behind every estimator, which the 0.0.4 rewrite replaced | Not cited by section in the code; the reviewer maps it | **Needed** |

### Background (optional; check that papers 1–2 cite them before relying on them)

| Reference | Why it's relevant | Functions |
|---|---|---|
| Li F, Morgan KL, Zaslavsky AM. Balancing covariates via propensity score weighting. *JASA.* 2018;113(521):390–400. | Paper 1 says W00 is a special case of these balancing weights | `.ec_weights()` |
| Tsiatis AA. *Semiparametric Theory and Missing Data.* Springer; 2006. | Source paper 1 cites for the AIPW and estimating-equation (sandwich) theory | `.ec_ipw_se()`, `.ec_aipw_se()` |
| Abadie A, Diamond A, Hainmueller J. Synthetic control methods for comparative case studies. *JASA.* 2010;105(490):493–505. | The original synthetic control method | `scm()` |
| Abadie A, L'Hour J. A penalized synthetic control estimator for disaggregated data. *JASA.* 2021;116(536):1817–1834. | `.scm_subject_sc()`'s penalty, λ·Σⱼ wⱼ‖xᵢ − xⱼ‖², has the form of this estimator | `.scm_subject_sc()`, `.scm_lambdacv()` |
| Davison AC, Hinkley DV. *Bootstrap Methods and Their Application.* Cambridge University Press; 1997. | The theory behind `boot::boot.ci()`'s `perc`, `bca`, `norm`, and `basic` intervals | `.run_bootstrap()` and every `bootstrap_ci_type` |

### Functions no paper specifies

The reviewer judges these against the docs and the papers' intent: `.build_analysis_df()`, the `estimate()` dispatch, argument validation in every constructor, and the deprecated `setup_method_*()` stubs.

## Coverage

| Reviewed | Function | Reference |
|---|---|---|
| [x] | `ec_ipw()` | Zhou et al. 2025, *JRSS-A* 188(3):791–818 (Def 1, Eq 6; Eq 11; Thm 3) |
| [x] | `ec_aipw()` | Zhou et al. 2025 (Def 2, Eq 7; Thm 4) |
| [x] | `setup_analysis_primary()` | Zhou et al. 2025 §2 |
| [x] | `did_ec_or()` | Zhou et al. 2024, *J Biopharm Stat* 34(6):893–921 (Eq 3, App B) |
| [x] | `did_ec_ipw()` | Zhou et al. 2024 (Eq 4, App B) |
| [x] | `did_ec_aipw()` | Zhou et al. 2024 (Eq 5, App B) |
| [x] | `scm()` | Zhou et al. 2024 (Eqs 7–9) |
| [x] | `setup_analysis_OLE()` | Zhou et al. 2024 §2 |
| [x] | `run_analysis()`, `estimate()` | None (package design) |
| [ ] | `setup_simulation_primary()` | Zhou et al. 2025 §5 and supplement; Morris et al. 2019 |
| [ ] | `setup_simulation_OLE()` | Zhou et al. 2024 §4; Morris et al. 2019 |
| [ ] | `run_simulation()` | Morris et al. 2019 (partly checked: #90, #93) |
| [ ] | `simulate_trial()` | Zhou et al. 2025 §5; Zhou et al. 2024 §4 |
| [ ] | `simulate_trial_status()` | Zhou et al. 2025 supplement Table 1; Zhou et al. 2024 §4 |
| [ ] | `simulate_trt_assign()` | Zhou et al. 2025 Assumption 3 |
| [ ] | `simulate_outcome_from_model()` | Zhou et al. 2025 §5; Zhou et al. 2024 §4 |
| [ ] | `simulate_X_copula()` | Yan 2007, *J Stat Softw* 21(4) |
| [ ] | `simulate_X_dct_mvnorm()` | None (standard construction) |
| [ ] | `simulate_X_mixture()` | None (standard construction) |
| [ ] | `SyntheticData` | `data-raw/SyntheticData.R` (see #102) |

Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate statistical methods. *Stat Med.* 2019;38(11):2074–2102. doi:10.1002/sim.8086.

The deprecated stubs (`setup_method_weighting()`, `setup_method_DID()`, `setup_method_SCM()`, `setup_bootstrap()`) only warn and error, so they need no review.

## 2. Phases

| Phase | What happens | Inputs | Who |
|---|---|---|---|
| 0. Setup | Put the papers in one folder. Record the commit, R and package versions, seeds, and baseline `devtools::test()` and `devtools::check()` results. Install and smoke-test the tools (`mutator` or `muttest`, `quickcheck`, `autotest`). | Papers 1–3 | Matt (papers); Claude (the rest) |
| 1. Pilot: primary analysis | Four testers in parallel, each in its own worktree at the recorded commit: black-box API, adversarial input and property, numerical validation, test strength. Scope: `ec_ipw()`, `ec_aipw()`, `.ec_weights()`, the optimal weight, and the sandwich variance. | Paper 1 and supplement; paper 3 for intent | Four agents |
| 2. Triage | Read each tester's raw report, confirm the reproducers, and file one issue per confirmed finding. | Phase 1 reports | Matt, with Claude |
| 3. Repair | One PR per issue, each with a test that fails before the fix and passes after. No relaxed tolerances or weakened assertions. | Phase 2 issues | Claude, reviewed by Matt |
| 4. Evaluate the pilot | Score the pilot against seeded defects and unmodified controls, and against a single general-purpose reviewer with the same budget. Report confirmed defects, unsupported findings, review time, runtime, and cost. | Phases 1–3 | Claude, reviewed by Matt |
| 5. Expand | Repeat phases 1–3 for the OLE methods (paper 2), then the simulation module (paper 3). | Papers 2–3 | Four agents per module |

We decide whether to run phase 5 after phase 4, based on whether the pilot's findings were worth the review time.

## 3. Dispatch details

- **Papers folder:** `~/Downloads/rdborrow-papers/`, named `lastname_year_journal_method.pdf`.
- **Worktrees:** one per tester, created from the recorded commit and deleted after its report is saved.
- **Reports:** each tester's raw report is copied unedited into `adversarial-review/runs/<date>-<phase>/<role>.md` on this branch, so independent findings stay distinguishable from repeated ones.
- **Budget per tester:** to decide before dispatch (time and tokens).

## 4. Decisions needed before phase 1

- [ ] Papers 2 and 3 downloaded into `~/Downloads/rdborrow-papers/`.
- [ ] Mutation tool: `mutator` (parallel runs, bounded samples) or `muttest`.
- [ ] Budget per tester.
- [ ] Whether to include seeded defects in the pilot itself, or only in phase 4.
