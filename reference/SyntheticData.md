# Synthetic example dataset for rdborrow

A simulated dataset containing covariates, treatment, trial status, and
longitudinal outcomes for demonstrating external control borrowing
methods.

## Usage

``` r
data(SyntheticData)
```

## Format

A data frame with 300 rows and 12 columns: 100 trial patients on
treatment (`S = 1`, `A = 1`), 100 trial controls (`S = 1`, `A = 0`), and
100 external controls (`S = 0`, `A = 0`). The covariates mimic a spinal
muscular atrophy (SMA) study.

- x1:

  SMA type: 0 = type II, 1 = type III.

- x2:

  SMN2 copy number: 0 = 3 copies, 1 = 4 copies.

- x3:

  Scoliosis: 0 = no, 1 = yes.

- x4:

  Age at enrollment, in years.

- x5:

  Baseline outcome.

- A:

  Treatment: 1 = treated, 0 = control.

- S:

  Trial status: 1 = trial patient, 0 = external control.

- T_cross:

  Last visit before trial controls cross over to treatment: 2 for all
  rows.

- y1, y2, y3, y4:

  Outcomes at visits 1 to 4.

## Source

Simulated with
[`simulate_trial()`](https://genentech.github.io/rdborrow/reference/simulate_trial.md).
The script is `data-raw/SyntheticData.R` in the package source on
GitHub.
