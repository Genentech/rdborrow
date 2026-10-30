## Submission

This is a bug-fix release, 0.0.5.1, soon after 0.0.5.0 (published
2026-10-08). Sorry for the quick resubmission.

`scm()`, one of the six estimators, needs the ECOSolveR package, which was
listed only in Suggests. A default `install.packages("rdborrow")` does not
install it, so `scm()` failed for users with a default install. CRAN checks
install suggested packages, so they did not show the problem. We found it by
installing rdborrow from CRAN in a clean container. This release moves
ECOSolveR to Imports. There are no other changes.

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
