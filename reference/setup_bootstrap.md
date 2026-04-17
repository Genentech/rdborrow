# Construct a bootstrap object

Construct a bootstrap object

## Usage

``` r
setup_bootstrap(replicates = 500, bootstrap_CI_type = "bca")
```

## Arguments

- replicates:

  Number of bootstrap replicates.

- bootstrap_CI_type:

  Type of bootstrap CI. One of `"bca"`, `"norm"`, `"basic"`, `"stud"`,
  or `"perc"`.

## Value

A bootstrap object.

## Examples

``` r
bootstrap_obj <- setup_bootstrap(
  replicates = 2e3,
  bootstrap_CI_type = "perc"
)
```
