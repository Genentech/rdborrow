## R package development

### Key commands

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

# To check the package with R CMD check
Rscript -e "devtools::check()"

# To format code
Rscript -e "styler::style_pkg()"

# To check spelling
Rscript -e "spelling::spell_check_package()"

# To lint the package
Rscript -e "lintr::lint_package()"
```

### Coding

* Always run `Rscript -e "styler::style_pkg()"` after generating code
* Use the base pipe operator (`|>`) not the magrittr pipe (`%>%`)
* Don't use `_$x` or `_$[["x"]]` since this package must work on R 4.1.
* Use `\() ...` for single-line anonymous functions. For all other cases, use `function() {...}`

### Testing

- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
- All new code should have an accompanying test.
- If there are existing tests, place new tests next to similar existing tests.
- Strive to keep your tests minimal with few comments.
- Never put code in a `test-{name}.R` file outside of a `test_that()` block. Instead, use `tests/testthat/helper.R` or `tests/testthat/helper-{name}.R`.
- Avoid `expect_true()` and `expect_false()` in favour of a specific expectation which will give a better failure message. A few expectations in newer releases that you might not know about are `expect_all_true()`, `expect_all_equal()`, and `expect_r6_class()`.
- Use `expect_error()` for errors and `expect_warning()` for warnings.
- Avoid the `.package` argument to `local_mocked_bindings()`; this modifies the namespace of another package which is not good practice. Instead create a mockable version of the function in the current package. See `?local_mocked_bindings` for more details.

### Documentation

- Every user-facing function should be exported and have roxygen2 documentation.
- Wrap roxygen comments at 80 characters.
- Internal functions should not have roxygen documentation.
- Whenever you add a new (non-internal) documentation topic, also add the topic to `_pkgdown.yml`.
- Always re-document the package after changing a roxygen2 comment.
- Use `pkgdown::check_pkgdown()` to check that all topics are included in the reference index.

### `NEWS.md`

- Every user-facing change should be given a bullet in `NEWS.md`. Do not add bullets for small documentation changes or internal refactorings.
- Each bullet should briefly describe the change to the end user and mention the related issue in parentheses.
- A bullet can consist of multiple sentences but should not contain any new lines (i.e. DO NOT line wrap).
- If the change is related to a function, put the name of the function early in the bullet.
- Order bullets alphabetically by function name. Put all bullets that don't mention function names at the beginning.

### GitHub

- If you use `gh` to retrieve information about an issue, always use `--comments` to read all the comments.

### Writing

- Use sentence case for headings.
- Use US English.

### Proofreading

If the user asks you to proofread a file, act as an expert proofreader and editor with a deep understanding of clear, engaging, and well-structured writing.

Work paragraph by paragraph, always starting by making a TODO list that includes individual items for each top-level heading.

Fix spelling, grammar, and other minor problems without asking the user. Label any unclear, confusing, or ambiguous sentences with a FIXME comment.

Only report what you have changed.

## Programming rules for LLMs
1. mostly lower-case comments
2. no in-line comments
3. don't number comments
4. comments are followed by '----', such as "# dependencies----". nothing that takes a full line.
5. no unnecessary code changes beyond what is already done
6. unless I ask, don't print too much code at once 
7. don't do unnecessary print statements within the code.
8. don't add unnecessary try/catch statements or make unnecessary validation checks. i'm working by myself, no need for these things -- I want to see the errors!
9. NO EMOJIS
10. in R code, 2 spaces per tab and base R pipe

## Refactor rules

### Per-function checklist

When refactoring any estimator or internal function, apply all of these:

1. Make runnable examples (no `\dontrun{}`)
2. Remove commented-out code
3. Remove TODOs
4. Add type checks (checkmate)
5. Factor out tidyverse (`filter` → `df[cond, ]`, `mutate` → direct assignment)
6. `<-` for assignment (not `=`)
7. Drop debug prints (`cat`, `print`, commented `# print(...)`)
8. Consistent variable naming without periods (e.g. `pi_S` not `pi.S`)
9. Drop backtick column access (`temp$\`piA\`` → `temp$piA`)

### General rules

- make sure we have test cases for all functions
- remove magrittr pipe and replace with base R pipe
- make sure every function is documented
- add validation to function inputs

## Before committing

Run this one-liner to validate the package before committing:

```
Rscript -e "devtools::document()" && Rscript -e "styler::style_pkg()" && Rscript -e "spelling::spell_check_package()" && Rscript -e "lintr::lint_package()" && Rscript -e "devtools::check(vignettes = FALSE)"
```

## Changing the API

### Goals

1. **Better method constructors** — replace `setup_method_weighting(method_name="IPW", ...)` with `ec_ipw()`, etc. Each constructor carries its own estimation logic.
2. **Polymorphic dispatch** — `run_analysis()` calls a generic on the method object instead of an if/else tree. Adding a new method = writing one constructor.
3. **Merge bootstrap** — bootstrap is an inference option on the method, not a separate code path.
4. **(Future) Model formula interface** — `outcome ~ treatment | covariates` instead of column name args.

### Current workflow (to deprecate)

```r
method <- setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = FALSE,
  wt = 0,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
)

analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

res <- run_analysis(analysis)
```

### Desired workflow

```r
method <- ec_ipw(
  ps_formula = "S ~ x1 + x2 + x3 + x4 + x5",
  weight = NULL,          # NULL = optimal, 0 = no borrowing, 0.3 = fixed
  bootstrap = 500,        # NULL = sandwich SE only
  bootstrap_ci_type = NULL  # NULL defaults to "perc" when bootstrap is set
)

analysis <- setup_analysis(
  data = SyntheticData,
  outcomes = c("y1", "y2"),
  treatment = "A",
  trial_status = "S",
  covariates = c("x1", "x2", "x3", "x4", "x5"),
  method = method
)

res <- run_analysis(analysis)
```

### Method constructors

| Constructor | Replaces | Phase |
|---|---|---|
| `ec_ipw()` | `setup_method_weighting(method_name="IPW", ...)` | Primary |
| `ec_aipw()` | `setup_method_weighting(method_name="AIPW", ...)` | Primary |
| `did_ec_ipw()` | `setup_method_DID(method_name="IPW", ...)` | OLE |
| `did_ec_aipw()` | `setup_method_DID(method_name="AIPW", ...)` | OLE |
| `did_ec_or()` | `setup_method_DID(method_name="OR", ...)` | OLE |
| `scm()` | `setup_method_SCM(...)` | OLE |

Each constructor returns an S4 method object. The S4 class defines a generic `estimate()` that `run_analysis()` dispatches on — no if/else.

### How dispatch works

```r
# S4 generic
setGeneric("estimate", function(method, data, ...) standardGeneric("estimate"))

# Each method class implements estimate()
setMethod("estimate", "ec_ipw_method", function(method, data, ...) {
  # IPW estimation logic lives here
})

# run_analysis() becomes:
run_analysis <- function(analysis_obj) {
  estimate(analysis_obj@method, data = analysis_obj@data, ...)
}
```

### Interim dispatch (during migration)

While new method constructors coexist with the old if/else tree in `run_analysis()`, each new class gets an `else if` block at the end of `run_analysis()` that calls `estimate()`:

```r
# In run_analysis.R, BEFORE the final } else { stop(...) }:
} else if (is(method, "ec_ipw_method")) {
  res <- estimate(method,
    data = data,
    outcomes = outcome_col_name,
    treatment = treatment_col_name,
    trial_status = trial_status_col_name,
    covariates = covariates_col_name,
    alpha = alpha,
    quiet = quiet
  )
}
```

This pattern is repeated for each new method class as it's created. The old if/else branches for the legacy classes remain untouched. Once all 6 methods are migrated, the entire if/else tree is replaced with a single `estimate()` call.

New method objects inherit from `method_primary_obj` or `method_OLE_obj`, so they pass the existing `checkmate::assert_class(method, "method_primary_obj")` validation in `setup_analysis_primary()`.

### Implementation order

1. Create full-pipeline regression tests for all 6 methods (old API, locked numerical values) ✓
2. Create all 6 method constructors (start with `ec_ipw()`)
3. Each constructor returns an S4 object with estimation logic via `estimate()` generic
4. For each new method, add an `else if (is(method, "xxx_method"))` to `run_analysis()`
5. Add new-API tests to each pipeline test file (same expected values)
6. Once all 6 are done: refactor `setup_analysis()` into a single function (merge `_primary`/`_OLE`, add `T_cross = NULL`)
7. Once all 6 are done: replace the entire if/else in `run_analysis()` with one `estimate()` call
8. Deprecate `setup_method_weighting`, `setup_method_DID`, `setup_method_SCM`, `setup_analysis_primary`, `setup_analysis_OLE`

### Design decisions

- **S4 classes for method objects** — keeps rigorous type definitions, consistent with existing package patterns.
- **`T_cross` goes in `setup_analysis()`** — it's a property of the study design, not the method.
- **`bootstrap_ci_type` is nullable** — defaults to `"perc"` when `bootstrap` is non-NULL, ignored otherwise.

### Full-pipeline regression tests

Before refactoring any estimator, we lock in its numerical outputs on `SyntheticData` so any code change that alters results is caught. Tests use the old API (setup_method → setup_analysis → run_analysis) with exact values at `tolerance = 1e-6`. As new API constructors are added, we add parallel assertions against the same expected values.

Rename existing `test-vignette_results_*` files and split by method:

| Test file | Method | Covers |
|---|---|---|
| `test-full_pipeline_ec_ipw.R` | EC-IPW | weight=0, optimal, fixed (0.3), bootstrap point estimates |
| `test-full_pipeline_ec_aipw.R` | EC-AIPW | weight=0, optimal, fixed (0.3), bootstrap point estimates |
| `test-full_pipeline_did_ec_ipw.R` | DID-EC-IPW | bootstrap CIs, point estimates |
| `test-full_pipeline_did_ec_aipw.R` | DID-EC-AIPW | bootstrap CIs, point estimates |
| `test-full_pipeline_did_ec_or.R` | DID-EC-OR | bootstrap CIs, point estimates |
| `test-full_pipeline_scm.R` | SCM | bootstrap CIs, point estimates |

Each test file asserts:
- Point estimates (exact values)
- Standard errors / standard deviations (exact values)
- CI bounds for non-bootstrap (exact values)
- Bootstrap point estimates match non-bootstrap
- Borrow weight (where applicable)

Simulation tests (`test-vignette_results_*_simulation.R`) stay separate — they test Monte Carlo properties, not individual estimator outputs.