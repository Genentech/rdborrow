# Introduction to rdborrow

## Overview

**rdborrow** implements causal inference methods for incorporating
external controls in randomized controlled trials (RCTs) with
longitudinal outcomes. The package provides tools for both analysis and
simulation, enabling researchers to evaluate different borrowing
strategies and design trials that leverage external data.

The methods are motivated by the SUNFISH trial for spinal muscular
atrophy (SMA), where external controls from the olesoxime trial augment
the randomized data to improve statistical efficiency.

## Methods

### Primary analysis (placebo-controlled phase)

These methods estimate the average treatment effect (ATE) during the
placebo-controlled phase by borrowing from external controls.

| Method | Function | Reference | Description |
|----|----|----|----|
| EC-IPW | [`ec_ipw()`](https://genentech.github.io/rdborrow/reference/ec_ipw.md) | Zhou et al. (2024b) | Inverse probability weighting with external control borrowing |
| EC-AIPW | [`ec_aipw()`](https://genentech.github.io/rdborrow/reference/ec_aipw.md) | Zhou et al. (2024b) | Augmented IPW (doubly robust) |

Both methods support:

- **No borrowing** (`weight = 0`): uses only RCT data
- **Optimal weight** (`weight = NULL`): data-adaptive weight minimizing
  variance
- **Fixed weight** (`weight = 0.3`): user-specified borrowing amount
- **Sandwich variance** or **bootstrap inference**

See
[`vignette("primary_analysis_workflow")`](https://genentech.github.io/rdborrow/articles/primary_analysis_workflow.md)
for usage.

### OLE phase analysis (open-label extension)

After the placebo-controlled phase, control subjects cross over to
treatment. These methods estimate the long-term treatment effect using
external controls who remain untreated.

| Method | Function | Reference | Description |
|----|----|----|----|
| DID-EC-IPW | [`did_ec_ipw()`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md) | Zhou et al. (2024a) | Difference-in-differences with IPW |
| DID-EC-AIPW | [`did_ec_aipw()`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md) | Zhou et al. (2024a) | DID with augmented IPW |
| DID-EC-OR | [`did_ec_or()`](https://genentech.github.io/rdborrow/reference/did_ec_or.md) | Zhou et al. (2024a) | DID with outcome regression |
| SCM | [`scm()`](https://genentech.github.io/rdborrow/reference/scm.md) | Zhou et al. (2024a) | Synthetic control method |

All OLE methods use bootstrap for inference.

See
[`vignette("OLE_analysis_workflow")`](https://genentech.github.io/rdborrow/articles/OLE_analysis_workflow.md)
for usage.

### Simulation

The simulation module evaluates estimator performance via Monte Carlo:

- [`simulate_trial()`](https://genentech.github.io/rdborrow/reference/simulate_trial.md)
  generates synthetic trial + external control data
- [`setup_simulation_primary()`](https://genentech.github.io/rdborrow/reference/setup_simulation_primary.md)
  /
  [`setup_simulation_OLE()`](https://genentech.github.io/rdborrow/reference/setup_simulation_OLE.md)
  configure simulations
- [`run_simulation()`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
  runs Monte Carlo experiments and reports bias, variance, MSE,
  coverage, power

See
[`vignette("primary_simulation_workflow")`](https://genentech.github.io/rdborrow/articles/primary_simulation_workflow.md)
and
[`vignette("OLE_simulation_workflow")`](https://genentech.github.io/rdborrow/articles/OLE_simulation_workflow.md)
for usage.

## Getting help

The help pages for
[`run_analysis()`](https://genentech.github.io/rdborrow/reference/run_analysis.md)
and
[`run_simulation()`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
list all available methods and link to their documentation:

``` r

?run_analysis
?run_simulation
```

## Quick start

``` r

# create an EC-IPW method with optimal borrowing weight
method <- ec_ipw(ps_formula = "S ~ x1 + x2 + x3 + x4 + x5")

# set up the analysis
analysis <- setup_analysis_primary(
  data = SyntheticData,
  trial_status_col_name = "S",
  treatment_col_name = "A",
  outcome_col_name = c("y1", "y2"),
  covariates_col_name = c("x1", "x2", "x3", "x4", "x5"),
  method_weighting_obj = method
)

# run
results <- run_analysis(analysis)
results
```

    ## $results
    ##      point_estimates standard_deviation lower_CI_normal upper_CI_normal
    ## tau1      -0.1971969          0.5134018       -1.203446        0.809052
    ## tau2       0.4697209          0.5410007       -0.590621        1.530063
    ## 
    ## $borrow_weight
    ## [1] 0.1475196

## References

- Zhou X, Zhu J, Drake C, Pang H (2024). “Causal estimators for
  incorporating external controls in randomized trials with longitudinal
  outcomes.” *Journal of the Royal Statistical Society Series A:
  Statistics in Society*. doi:
  [10.1093/jrsssa/qnae075](https://doi.org/10.1093/jrsssa/qnae075).
- Zhou X, Pang H, Drake C, Burger HU, Zhu J (2024). “Estimating
  treatment effect in randomized trial after control to treatment
  crossover using external controls.” *Journal of Biopharmaceutical
  Statistics*. doi:
  [10.1080/10543406.2024.2444222](https://doi.org/10.1080/10543406.2024.2444222).
- Shi L, Pang H, Chen C, Zhu J (2025). “rdborrow: an R package for
  causal inference incorporating external controls in randomized
  controlled trials with longitudinal outcomes.” *Journal of
  Biopharmaceutical Statistics*, 35(6), 1043-1066. doi:
  [10.1080/10543406.2025.2489283](https://doi.org/10.1080/10543406.2025.2489283).
