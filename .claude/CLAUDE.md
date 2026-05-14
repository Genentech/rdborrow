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

## Refactor rules
We're attemping to refactor many issues with this repositroy. In general, let's:
- make sure all examples are functional and not wrapped in dontrun{}
- make sure we have test cases for all functions
- remove @TODO blocks and other ugly code
- remove magrittr pipe and replace with base R pipe
- remove tidyverse dependencies
- replace "=" with "<-"
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

### Implementation order

1. Create all 6 method constructors (start with `ec_ipw()`)
2. Each constructor returns an S4 object with estimation logic via `estimate()` generic
3. Refactor `setup_analysis()` into a single function (merge `_primary`/`_OLE`, add `T_cross = NULL`)
4. Refactor `run_analysis()` to use S4 dispatch
5. Deprecate `setup_method_weighting`, `setup_method_DID`, `setup_method_SCM`, `setup_analysis_primary`, `setup_analysis_OLE`

### Design decisions

- **S4 classes for method objects** — keeps rigorous type definitions, consistent with existing package patterns.
- **`T_cross` goes in `setup_analysis()`** — it's a property of the study design, not the method.
- **`bootstrap_ci_type` is nullable** — defaults to `"perc"` when `bootstrap` is non-NULL, ignored otherwise.