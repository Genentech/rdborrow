# method class

method class

## Slots

- `model_form_mu0_ext`:

  Formula string for external control outcome model.

- `model_form_mu0_rct`:

  Formula string for RCT control outcome model.

- `model_form_mu1_rct`:

  Formula string for RCT treatment outcome model.

- `model_form_piS`:

  Formula string for trial participation model.

- `bootstrap_flag`:

  Logical indicating whether bootstrap inference is used.

- `model_form_piA`:

  Formula string for treatment assignment model.

- `bootstrap_obj`:

  A bootstrap_obj with bootstrap settings.

## Examples

``` r
if (FALSE) { # \dontrun{
method_DID_obj <- setup_method_DID(
  method_name = "IPW",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5"
)
} # }
```
