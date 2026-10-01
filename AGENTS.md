# rdborrow

rdborrow estimates treatment effects in randomized trials that borrow external
controls, for longitudinal outcomes in rare diseases. It supports single
analyses (`run_analysis()`) and Monte Carlo studies of operating
characteristics (`run_simulation()`).

Developer guides (pkgdown articles, not shipped to CRAN):

- `vignettes/articles/adding-a-method.Rmd`: how an estimator plugs in, with a
  runnable toy method and a checklist. Follow it when adding a method.
- `vignettes/articles/ai-coding-agents.Rmd`: how to work on this package
  with an AI coding agent.

## Architecture

### User-facing API

These are the only functions users should need. Everything else is internal.

- **Method constructors**: `ec_ipw()`, `ec_aipw()`, `did_ec_ipw()`, `did_ec_aipw()`, `did_ec_or()`, `scm()`
- **Analysis**: `setup_analysis_primary()`, `setup_analysis_OLE()`, `run_analysis()`
- **Simulation**: `setup_simulation_primary()`, `setup_simulation_OLE()`, `run_simulation()`
- **Data generation**: `simulate_trial()` and related `simulate_*()` helpers

```r
method <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  weight = NULL,
  bootstrap = 500,
  bootstrap_ci_type = NULL
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

run_analysis(analysis)
```

`weight = NULL` is the data-adaptive optimal weight, `0` is no borrowing, and
a value in (0, 1] is a fixed weight. `bootstrap = NULL` gives sandwich
standard errors only.

### Method classes and dispatch

Each constructor returns an S4 object. `run_analysis()` is a single
`do.call(estimate, args)`; each method class implements its own `estimate()`
method. A new estimator adds a class, a constructor and an `estimate()`
method, and never changes the logic of `run_analysis()`, `run_simulation()`
or another method. Registering it edits only documentation: the method
lists, `_pkgdown.yml`, `NEWS.md`, and the files `devtools::document()`
regenerates.

```
method_obj
├── method_primary_obj  -> setup_analysis_primary()
│   └── method_weighting_obj    ec_ipw(), ec_aipw()
└── method_OLE_obj      -> setup_analysis_OLE()
    ├── method_DID_obj          did_ec_ipw(), did_ec_aipw(), did_ec_or()
    └── method_SCM_obj          scm()
```

Internals for method `{name}`, in `R/{name}.R`:

- `.{name}_core()`: the single source of truth for the point estimate, shared
  by `estimate()` and the bootstrap statistic. No duplication.
- `.{name}_se()`: sandwich variance. Only `ec_ipw()` and `ec_aipw()` have
  one; the DID methods and `scm()` support bootstrap inference only.
- `.{name}_boot_statistic(data, indices, ...)`: resamples rows and calls
  `.{name}_core()`. Pass it to the shared `.run_bootstrap()`; never write a
  new bootstrap loop.

`run_simulation()` depends on the result column names (`point_estimates`,
`*_CI_normal` or `*_CI_boot`). See the `estimate()` contract in
`adding-a-method.Rmd` before changing a return value.

`DESCRIPTION` has a `Collate` field, so every new `R/` file that defines a
subclass needs `#' @include method_class.R`.

Full-pipeline regression tests (`tests/testthat/test-full_pipeline_*.R`) lock
the numerical output of all six methods on `SyntheticData`. If one of them
changes, explain why in the PR.

### Design decisions

- **S4 classes for method objects**: rigorous type definitions, consistent
  with existing package patterns.
- **`T_cross` goes in `setup_analysis_OLE()`**: it is a property of the study
  design, not the method.
- **`bootstrap_ci_type` is nullable**: it defaults to `"perc"` when
  `bootstrap` is set.
- **Keep `setup_analysis_primary()` and `setup_analysis_OLE()` separate**:
  collapsing them is easy later, splitting them apart is not.

### Legacy API

`setup_method_weighting()`, `setup_method_DID()`, `setup_method_SCM()` and
`setup_bootstrap()` are deprecated stubs that warn and then error, pointing
users to the new constructors. The dplyr/tidyr code they used is gone; do not
reintroduce a tidyverse dependency.

Remaining cleanup, in order:

1. Remove the deprecated stubs after users have had time to migrate.
2. Rename the S4 classes for consistency (`method_*_obj` naming).
3. Maybe merge `setup_analysis_primary()` and `setup_analysis_OLE()` into
   `setup_analysis()` with `T_cross = NULL`.

## Key commands

```
# To run code
Rscript -e "devtools::load_all(); code"

# To run all tests
Rscript -e "devtools::test()"

# To run all tests for files starting with {name}
Rscript -e "devtools::test(filter = '^{name}')"

# To run all tests for R/{name}.R
Rscript -e "devtools::test_active_file('R/{name}.R')"

# To run a single test "blah" for R/{name}.R
Rscript -e "devtools::test_active_file('R/{name}.R', desc = 'blah')"

# To redocument the package
Rscript -e "devtools::document()"

# To check pkgdown documentation
Rscript -e "pkgdown::check_pkgdown()"

# To build the pkgdown site locally
Rscript -e "pkgdown::clean_site(force = TRUE); pkgdown::build_site(override = list(template = list(favicon = list())))"

# To check the package with R CMD check
Rscript -e "devtools::check()"

# To format code
Rscript -e "styler::style_pkg()"

# To check spelling
Rscript -e "spelling::spell_check_package()"

# To lint the package
Rscript -e "lintr::lint_package()"
```

## Coding

- Always run `Rscript -e "styler::style_pkg()"` after generating code.
- Use the base pipe operator (`|>`), not the magrittr pipe (`%>%`).
- Don't use `_$x` or `_$[["x"]]`, since this package must work on R 4.1.
- Use `\() ...` for single-line anonymous functions. For all other cases, use
  `function() {...}`.
- Use 2 spaces per indent level.
- Use `<-` for assignment, not `=`.
- Use snake_case names without periods (`pi_S`, not `pi.S`).
- Validate the arguments of exported functions with checkmate. Don't add
  other defensive checks or `tryCatch()` wrappers; let errors surface.
- No debug output (`cat()`, `print()`) in package code.
- No commented-out code and no TODOs.
- Make no changes beyond what the task needs.
- No emojis, in code or anywhere else.

### Comments

- Mostly lower-case.
- No inline comments; a comment takes its own line.
- Don't number comments.
- Section comments end with `----`, for example `# dependencies----`.

### Refactoring checklist

When refactoring any estimator or internal function, apply all of these:

1. Make runnable examples (no `\dontrun{}`).
2. Remove commented-out code.
3. Remove TODOs.
4. Add type checks (checkmate).
5. Factor out tidyverse (`filter` -> `df[cond, ]`, `mutate` -> direct
   assignment).
6. Use `<-` for assignment.
7. Drop debug prints (`cat`, `print`, commented `# print(...)`).
8. Use consistent variable names without periods.
9. Drop backtick column access (`` temp$`piA` `` -> `temp$piA`).

## Testing

- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
- All new code should have an accompanying test.
- If there are existing tests, place new tests next to similar existing tests.
- Strive to keep your tests minimal with few comments.
- Never put code in a `test-{name}.R` file outside of a `test_that()` block.
  Instead, use `tests/testthat/helper.R` or `tests/testthat/helper-{name}.R`.
- Avoid `expect_true()` and `expect_false()` in favour of a specific
  expectation, which gives a better failure message. A few expectations in
  newer releases that you might not know about are `expect_all_true()`,
  `expect_all_equal()`, and `expect_r6_class()`.
- Use `expect_error()` for errors and `expect_warning()` for warnings.
- Avoid the `.package` argument to `local_mocked_bindings()`; it modifies the
  namespace of another package. Instead create a mockable version of the
  function in this package. See `?local_mocked_bindings`.
- Don't back a bug fix with reasoning alone. Write a test that fails before
  the fix, for example by mocking a seam.
- `devtools::test()` uses `load_all()`, which can hide problems that only
  appear in the installed package. Run `devtools::check()` before calling a
  fix done.

## Documentation

- Every user-facing function should be exported and have roxygen2
  documentation.
- Wrap roxygen comments at 80 characters.
- Internal functions get no help page: describe them with `#'` comments that
  end in `@noRd`, as `R/ec_ipw.R` does.
- Whenever you add a new (non-internal) documentation topic, also add the
  topic to `_pkgdown.yml`.
- Always re-document the package after changing a roxygen2 comment.
- Use `pkgdown::check_pkgdown()` to check that all topics are included in the
  reference index.

## `NEWS.md`

- Every user-facing change should be given a bullet in `NEWS.md`. Do not add
  bullets for small documentation changes or internal refactorings.
- Each bullet should briefly describe the change to the end user and mention
  the related issue in parentheses.
- A bullet can consist of multiple sentences but should not contain any new
  lines (i.e. DO NOT line wrap).
- If the change is related to a function, put the name of the function early
  in the bullet.
- Order bullets alphabetically by function name. Put all bullets that don't
  mention function names at the beginning.

## Specialized tasks

For adding input validation or deprecating a function or argument, follow the
tidyverse team's instructions:

- Claude Code: use the `tidy-argument-checking` and `tidy-deprecate-function`
  skills in `.claude/skills/`.
- Other agents: run `Rscript -e 'usethis::learn_tidy_skill("arg-checking")'`
  or `Rscript -e 'usethis::learn_tidy_skill("deprecate")'` (usethis >= 3.2.2)
  and follow the output. If `learn_tidy_skill()` doesn't exist, the installed
  usethis is too old; run `Rscript -e 'install.packages("usethis")'` first.

## GitHub

- If you use `gh` to retrieve information about an issue, always use
  `--comments` to read all the comments.

## Writing

- Use sentence case for headings.
- Use US English.

## Proofreading

If asked to proofread a file, act as an expert proofreader and editor with a
deep understanding of clear, engaging, and well-structured writing.

Work paragraph by paragraph, always starting by making a TODO list that
includes individual items for each top-level heading.

Fix spelling, grammar, and other minor problems without asking. Label any
unclear, confusing, or ambiguous sentences with a FIXME comment.

Only report what you have changed.

## Before committing

Run this one-liner to validate the package before committing:

```
Rscript -e "devtools::document()" && Rscript -e "styler::style_pkg()" && Rscript -e "spelling::spell_check_package()" && Rscript -e "lintr::lint_package()" && Rscript -e "devtools::check(vignettes = FALSE)"
```
