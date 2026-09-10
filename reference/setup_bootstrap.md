# Setup bootstrap (Deprecated)

\`r lifecycle::badge("deprecated")\`

Bootstrap settings are now specified directly in each method constructor
(e.g., \[ec_ipw()\], \[did_ec_ipw()\]). The separate bootstrap object is
no longer needed.

## Usage

``` r
setup_bootstrap(...)
```

## Arguments

- ...:

  Ignored.

## Value

This function is defunct and always signals an error; it does not return
a value.

## Examples

``` r
try(setup_bootstrap())
#> Warning: 'setup_bootstrap' has been removed. Bootstrap settings are now passed directly to method constructors (e.g., ec_ipw(bootstrap = 500, bootstrap_ci_type = 'perc')).
#> Error : setup_bootstrap() is no longer functional. Pass bootstrap settings directly to method constructors.
```
