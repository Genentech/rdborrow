# method class

method class

## Slots

- `method_name`:

  character.

- `bootstrap_flag`:

  Logical indicating whether bootstrap inference is used.

- `bootstrap_obj`:

  A bootstrap_obj with bootstrap settings.

## Examples

``` r
if (FALSE) { # \dontrun{
method_weighting_obj <- setup_method_weighting(
  method_name = "AIPW",
  optimal_weight_flag = TRUE,
  wt = 0,
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_mu0_ext = c(
    "y1 ~ x1 + x2 + x3 + x4 + x5",
    "y2 ~ x1 + x2 + x3 + x4 + x5"
  )
)
} # }
```
