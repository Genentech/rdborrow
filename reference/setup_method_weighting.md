# Setup method weighting (Deprecated)

\`r lifecycle::badge("deprecated")\`

This function has been removed. Use \[ec_ipw()\] for inverse probability
weighting or \[ec_aipw()\] for augmented inverse probability weighting.

## Usage

``` r
setup_method_weighting(...)
```

## Arguments

- ...:

  Ignored.

## Value

This function is defunct and always signals an error; it does not return
a value.

## Examples

``` r
try(setup_method_weighting())
#> Warning: 'setup_method_weighting' has been removed. Use ec_ipw() or ec_aipw() instead.
#> Error : setup_method_weighting() is no longer functional. Use ec_ipw() or ec_aipw().
```
