# Package index

## Package Overview

- [`rdborrow-package`](https://genentech.github.io/rdborrow/reference/aaa-rdborrow-package.md)
  [`rdborrow`](https://genentech.github.io/rdborrow/reference/aaa-rdborrow-package.md)
  : The rdborrow package

## Analysis

Set up and run analyses

- [`setup_analysis_primary()`](https://genentech.github.io/rdborrow/reference/setup_analysis_primary.md)
  : Set up a primary analysis with external control borrowing
- [`setup_analysis_OLE()`](https://genentech.github.io/rdborrow/reference/setup_analysis_OLE.md)
  : Set up an open-label extension (OLE) analysis
- [`run_analysis()`](https://genentech.github.io/rdborrow/reference/run_analysis.md)
  : Run an analysis with external control borrowing

## Simulation

Set up and run simulations

- [`setup_simulation_primary()`](https://genentech.github.io/rdborrow/reference/setup_simulation_primary.md)
  : Construct a simulation object for primary analysis
- [`setup_simulation_OLE()`](https://genentech.github.io/rdborrow/reference/setup_simulation_OLE.md)
  : Construct a simulation object for OLE analysis
- [`run_simulation()`](https://genentech.github.io/rdborrow/reference/run_simulation.md)
  : Evaluate operating characteristics via Monte Carlo simulation
- [`setup_simulation_report()`](https://genentech.github.io/rdborrow/reference/setup_simulation_report.md)
  : setup_simulation_report

## Estimators

Method constructors for estimation

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
- [`estimate()`](https://genentech.github.io/rdborrow/reference/estimate.md)
  : Run estimation for a method object

## Method Configuration (legacy)

Configure estimation methods (deprecated)

- [`setup_method_weighting()`](https://genentech.github.io/rdborrow/reference/setup_method_weighting.md)
  : Construct a method_weighting object
- [`setup_method_DID()`](https://genentech.github.io/rdborrow/reference/setup_method_DID.md)
  : Construct a method_DID object
- [`setup_method_SCM()`](https://genentech.github.io/rdborrow/reference/setup_method_SCM.md)
  : Construct a method_SCM object
- [`setup_bootstrap()`](https://genentech.github.io/rdborrow/reference/setup_bootstrap.md)
  : Construct a bootstrap object

## Data Generation

Simulate trial data

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

## Classes

S4 class documentation

- [`analysis_obj-class`](https://genentech.github.io/rdborrow/reference/analysis_obj-class.md)
  [`.analysis_obj`](https://genentech.github.io/rdborrow/reference/analysis_obj-class.md)
  : Analysis class
- [`analysis_primary_obj-class`](https://genentech.github.io/rdborrow/reference/analysis_primary_obj-class.md)
  [`.analysis_primary_obj`](https://genentech.github.io/rdborrow/reference/analysis_primary_obj-class.md)
  : Analysis primary class
- [`analysis_OLE_obj-class`](https://genentech.github.io/rdborrow/reference/analysis_OLE_obj-class.md)
  [`.analysis_OLE_obj`](https://genentech.github.io/rdborrow/reference/analysis_OLE_obj-class.md)
  : Analysis OLE class
- [`bootstrap_obj-class`](https://genentech.github.io/rdborrow/reference/bootstrap_obj-class.md)
  [`.bootstrap_obj`](https://genentech.github.io/rdborrow/reference/bootstrap_obj-class.md)
  : Bootstrap class
- [`method_obj-class`](https://genentech.github.io/rdborrow/reference/method_obj-class.md)
  [`.method_obj`](https://genentech.github.io/rdborrow/reference/method_obj-class.md)
  : Method classes
- [`method_weighting_obj-class`](https://genentech.github.io/rdborrow/reference/method_weighting_obj-class.md)
  [`.method_weighting_obj`](https://genentech.github.io/rdborrow/reference/method_weighting_obj-class.md)
  : Method weighting class
- [`method_DID_obj-class`](https://genentech.github.io/rdborrow/reference/method_DID_obj-class.md)
  [`.method_DID_obj`](https://genentech.github.io/rdborrow/reference/method_DID_obj-class.md)
  : Method DID class
- [`method_SCM_obj-class`](https://genentech.github.io/rdborrow/reference/method_SCM_obj-class.md)
  [`.method_SCM_obj`](https://genentech.github.io/rdborrow/reference/method_SCM_obj-class.md)
  : Method SCM class
- [`simulation_obj-class`](https://genentech.github.io/rdborrow/reference/simulation_obj-class.md)
  [`.simulation_obj`](https://genentech.github.io/rdborrow/reference/simulation_obj-class.md)
  : Simulation class
- [`simulation_primary_obj-class`](https://genentech.github.io/rdborrow/reference/simulation_primary_obj-class.md)
  [`.simulation_primary_obj`](https://genentech.github.io/rdborrow/reference/simulation_primary_obj-class.md)
  : Simulation for primary analysis
- [`simulation_OLE_obj-class`](https://genentech.github.io/rdborrow/reference/simulation_OLE_obj-class.md)
  [`.simulation_OLE_obj`](https://genentech.github.io/rdborrow/reference/simulation_OLE_obj-class.md)
  : Simulation for OLE study
- [`simulation_report_obj-class`](https://genentech.github.io/rdborrow/reference/simulation_report_obj-class.md)
  [`.simulation_report_obj`](https://genentech.github.io/rdborrow/reference/simulation_report_obj-class.md)
  : Simulation class

## Data

Example datasets

- [`SyntheticData`](https://genentech.github.io/rdborrow/reference/SyntheticData.md)
  : Synthetic example dataset for rdborrow
