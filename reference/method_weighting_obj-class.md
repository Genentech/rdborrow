# method weighting class

method weighting class

## Slots

- `optimal_weight_flag`:

  logical.

- `wt`:

  numeric.

- `model_form_mu0_ext`:

  Formula string for external control outcome model.

- `model_form_mu0_rct`:

  Formula string for RCT control outcome model.

- `model_form_mu1_rct`:

  Formula string for RCT treatment outcome model.

- `model_form_piS`:

  Formula string for trial participation model.

- `model_form_piA`:

  Formula string for treatment assignment model.

## Examples

``` r
if (FALSE) { # \dontrun{
method_IPW_optimal_weight <- setup_method_weighting(
  method_name = "IPW",
  optimal_weight_flag = TRUE,
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5"
)
} # }
```
