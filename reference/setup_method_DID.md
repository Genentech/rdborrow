# Setup method DID (Deprecated)

\`r lifecycle::badge("deprecated")\`

This function has been removed. Use \[did_ec_ipw()\] for inverse
probability weighting, \[did_ec_aipw()\] for augmented inverse
probability weighting, or \[did_ec_or()\] for outcome regression.

## Usage

``` r
setup_method_DID(...)
```

## Arguments

- ...:

  Ignored.

## Value

This function is defunct and always signals an error; it does not return
a value.

## Examples

``` r
try(setup_method_DID())
#> Warning: 'setup_method_DID' has been removed. Use did_ec_ipw(), did_ec_aipw(), or did_ec_or() instead.
#> Error : setup_method_DID() is no longer functional. Use did_ec_ipw(), did_ec_aipw(), or did_ec_or().
```
