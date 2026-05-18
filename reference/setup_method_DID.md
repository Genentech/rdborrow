# Construct a method_DID object

Construct a method_DID object

## Usage

``` r
setup_method_DID(
  method_name = "IPW",
  bootstrap_flag = FALSE,
  bootstrap_obj = .bootstrap_obj(),
  model_form_piS = "",
  model_form_mu0_ext = "",
  model_form_piA = "",
  model_form_mu0_rct = "",
  model_form_mu1_rct = ""
)
```

## Arguments

- method_name:

  character. Name of the method.

- bootstrap_flag:

  logical. Whether to use bootstrap for inference.

- bootstrap_obj:

  bootstrap_obj. An object of class \`bootstrap_obj\` containing
  bootstrap settings.

- model_form_piS:

  character. Model formula for the selection model (S).

- model_form_mu0_ext:

  character. Model formula for the outcome model in the external data
  (mu0_ext).

- model_form_piA:

  character. Model formula for the treatment model (A).

- model_form_mu0_rct:

  character. Model formula for the outcome model in the RCT data under
  control (mu0_rct).

- model_form_mu1_rct:

  character. Model formula for the outcome model in the RCT data under
  treatment (mu1_rct).

## Value

An object of class \`method_DID_obj\`.

## Examples

``` r
setup_method_DID(
  method_name = "IPW",
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5"
)
#> Warning: 'setup_method_DID' is being deprecated. Use did_ec_ipw() for DID with inverse probability weighting, did_ec_aipw() for DID with augmented IPW, or did_ec_or() for DID with outcome regression.
```
