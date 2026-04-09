# Find synthetic control for one specific subject

Find synthetic control for one specific subject

## Usage

``` r
subject_SC(subject, X10, X00, long_term_col_name, lambda)
```

## Arguments

- subject:

  Integer index of the target subject.

- X10:

  Matrix of RCT control subjects (attributes by columns).

- X00:

  Matrix of external control subjects (attributes by columns).

- long_term_col_name:

  Character vector of long-term outcome column names.

- lambda:

  Numeric penalty parameter.
