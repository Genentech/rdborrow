# Run simulation from a simualtion_obj

Run simulation from a simualtion_obj

## Usage

``` r
run_simulation(simulation_obj, quiet = TRUE)
```

## Arguments

- simulation_obj:

  A simulation object created by `setup_simulation_primary` or
  `setup_simulation_OLE`.

- quiet:

  Logical. If `TRUE`, suppress iteration output.

## Value

a simulation_report object

## Examples

``` r
if (FALSE) { # \dontrun{
simulation_report <- run_simulation(simulation_OLE_obj, quiet = FALSE)
} # }
```
