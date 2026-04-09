# Construct a method object

Construct a method object

## Usage

``` r
setup_method(
  method_name = "",
  bootstrap_flag = FALSE,
  bootstrap_obj = .bootstrap_obj()
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

## Value

An object of class \`method_obj\`.
