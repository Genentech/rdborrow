# Construct a method_weighting object

Construct a method_weighting object

## Usage

``` r
setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = FALSE,
  wt = 0,
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

- optimal_weight_flag:

  logical. Whether to use optimal weighting.

- wt:

  numeric. The value of wt for the weighting scheme.

- bootstrap_flag:

  logical. Whether to use bootstrap for inference.

- bootstrap_obj:

  bootstrap_obj. An object of class \`bootstrap_obj\` containing
  bootstrap settings.

- model_form_piS:

  character. The model formula for the selection model (S).

- model_form_mu0_ext:

  character. The model formula for the outcome model in the external
  data (mu0_ext).

- model_form_piA:

  character. The model formula for the treatment model (A).

- model_form_mu0_rct:

  character. The model formula for the outcome model in the RCT data
  under control (mu0_rct).

- model_form_mu1_rct:

  character. The model formula for the outcome model in the RCT data
  under treatment (mu1_rct).

## Value

An object of class \`method_weighting_obj\`.
