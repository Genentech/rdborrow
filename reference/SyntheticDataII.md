# Unbalanced synthetic example dataset for rdborrow

A companion to
[`SyntheticData`](https://genentech.github.io/rdborrow/reference/SyntheticData.md)
with unequal group sizes, for tests and examples where balanced data
would hide an error. With equal arms, for example, exchanging the
randomization probability and its complement gives the same numbers.

## Usage

``` r
data(SyntheticDataII)
```

## Format

A data frame with 380 rows and the same 12 columns as
[`SyntheticData`](https://genentech.github.io/rdborrow/reference/SyntheticData.md):
160 trial patients on treatment (`S = 1`, `A = 1`), 80 trial controls
(`S = 1`, `A = 0`), and 140 external controls (`S = 0`, `A = 0`). The
trial randomizes 2:1, so the probability of treatment is 2/3. SMA type
III (`x1 = 1`) is more common in the trial than in the external
controls. The participation model has good overlap. The outcome models
are the same as in `SyntheticData`, and `T_cross` is 2 for all rows.

## Source

Simulated with
[`simulate_trial()`](https://genentech.github.io/rdborrow/reference/simulate_trial.md).
The script is `data-raw/SyntheticDataII.R` in the package source on
GitHub.
