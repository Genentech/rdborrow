## Submission

This is a feature and bug-fix release, 0.0.5.0. An adversarial review of the
package against its methods papers found no errors in the estimators, but
found gaps in input validation that could give incorrect results without a
message. This release:

* rejects invalid inputs with clear errors (missing values, empty groups,
  external controls coded as treated, factor treatment columns, formulas
  that use variables other than the covariates, and `alpha` of 0 or 1);
* fixes the sandwich variance for collinear covariates and for
  data-dependent outcome-model bases, and makes its memory use linear in the
  sample size;
* adds `SyntheticDataII`, an unbalanced example dataset, and tests against
  independent calculations;
* corrects the citations and expands the documentation.

Some changes are breaking: outcome formulas must name an outcome on the
left-hand side, and formulas may use only the covariates. They are listed
under "Breaking changes" in NEWS.md.

## Test environments

* local: Pop!_OS 24.04 (Ubuntu 24.04), R 4.6.1, with
  `NOT_CRAN = "false"` and the PDF manual
* GitHub Actions: Ubuntu (R-release, R-devel), macOS (R-release),
  Windows (R-release)

## R CMD check results

0 errors | 0 warnings | 0 notes

The "checking CRAN incoming feasibility" NOTE seen on submission flags
words in DESCRIPTION (AIPW, IPW, RCTs, Zhou, et, al) that are domain
acronyms, an author surname, and standard citation abbreviations, not
typos.

## Downstream dependencies

There are currently no downstream dependencies for this package.
