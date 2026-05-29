# Package index

## Borrowing methods

Choose an estimator for external control borrowing

- [`ec_ipw()`](https://genentech.github.io/rdborrow/reference/ec_ipw.md)
  : EC-IPW method constructor
- [`ec_aipw()`](https://genentech.github.io/rdborrow/reference/ec_aipw.md)
  : EC-AIPW method
- [`did_ec_ipw()`](https://genentech.github.io/rdborrow/reference/did_ec_ipw.md)
  : DID-EC-IPW method
- [`did_ec_aipw()`](https://genentech.github.io/rdborrow/reference/did_ec_aipw.md)
  : DID-EC-AIPW method
- [`did_ec_or()`](https://genentech.github.io/rdborrow/reference/did_ec_or.md)
  : DID-EC-OR method constructor
- [`scm()`](https://genentech.github.io/rdborrow/reference/scm.md) : SCM
  method constructor

## Analysis

Set up and run a single analysis

- [`setup_analysis_primary()`](https://genentech.github.io/rdborrow/reference/setup_analysis_primary.md)
  : Set up a primary analysis with external control borrowing
- [`setup_analysis_OLE()`](https://genentech.github.io/rdborrow/reference/setup_analysis_OLE.md)
  : Set up an open-label extension (OLE) analysis
- [`run_analysis()`](https://genentech.github.io/rdborrow/reference/run_analysis.md)
  : Run an analysis with external control borrowing

## Simulation

Evaluate operating characteristics via Monte Carlo

- [`setup_simulation_primary()`](https://genentech.github.io/rdborrow/reference/setup_simulation_primary.md)
  : Construct a simulation object for primary analysis
- [`setup_simulation_OLE()`](https://genentech.github.io/rdborrow/reference/setup_simulation_OLE.md)
  : Construct a simulation object for OLE analysis
- [`run_simulation()`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
  : Evaluate operating characteristics via Monte Carlo simulation

## Data generation

Simulate trial and external control data

- [`simulate_trial()`](https://genentech.github.io/rdborrow/reference/simulate_trial.md)
  : Simulate trials
- [`simulate_X_copula()`](https://genentech.github.io/rdborrow/reference/simulate_X_copula.md)
  : Simulate covariates using a copula
- [`simulate_X_dct_mvnorm()`](https://genentech.github.io/rdborrow/reference/simulate_X_dct_mvnorm.md)
  : Simulate covariates by discretizing a multivariate normal
- [`simulate_X_mixture()`](https://genentech.github.io/rdborrow/reference/simulate_X_mixture.md)
  : Simulate covariates from a Gaussian mixture model
- [`simulate_trt_assign()`](https://genentech.github.io/rdborrow/reference/simulate_trt_assign.md)
  : Simulate treatment assignment
- [`simulate_trial_status()`](https://genentech.github.io/rdborrow/reference/simulate_trial_status.md)
  : Simulate trial participation status
- [`simulate_outcome_from_model()`](https://genentech.github.io/rdborrow/reference/simulate_outcome_from_model.md)
  : Simulate outcomes from additive linear models

## Data

- [`SyntheticData`](https://genentech.github.io/rdborrow/reference/SyntheticData.md)
  : Synthetic example dataset for rdborrow

## Deprecated

- [`setup_method_weighting()`](https://genentech.github.io/rdborrow/reference/setup_method_weighting.md)
  : Setup method weighting (Deprecated)
- [`setup_method_DID()`](https://genentech.github.io/rdborrow/reference/setup_method_DID.md)
  : Setup method DID (Deprecated)
- [`setup_method_SCM()`](https://genentech.github.io/rdborrow/reference/setup_method_SCM.md)
  : Setup method SCM (Deprecated)
