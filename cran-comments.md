## Submission

This release addresses the check failure reported on 2026-09-28 under
"Additional issues" for the BLIS BLAS flavor.

Two tests compared a marginal treatment model against an equivalent
intercept-only model with an exact floating-point equality assertion. The
two are mathematically identical but computed by different routes, so under
BLIS they differ in the last bit. Both assertions now use a tolerance. No
estimator behavior changed.

## Test environments

* local: Ubuntu 24.04, R 4.6.1 (OpenBLAS)
* GitHub Actions: Ubuntu (R-release, R-devel), macOS, Windows

## R CMD check results

0 errors | 0 warnings | 0 notes

The "checking CRAN incoming feasibility" NOTE seen on submission flags
words in DESCRIPTION (AIPW, IPW, RCTs, Zhou, et, al) that are domain
acronyms, an author surname, and standard citation abbreviations, not
typos.

## Downstream dependencies

There are currently no downstream dependencies for this package.
