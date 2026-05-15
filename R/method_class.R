#' method class
#'
#' @slot method_name character.
#' @slot bootstrap_flag Logical indicating whether bootstrap inference is used.
#' @slot bootstrap_obj A bootstrap_obj with bootstrap settings.
#'
#' @include bootstrap_class.R
.method_obj <- setClass(
  "method_obj",
  slots = c(
    method_name = "character",
    bootstrap_flag = "logical",
    bootstrap_obj = "bootstrap_obj"
  )
)

.method_primary_obj <- setClass(
  "method_primary_obj",
  contains = "method_obj"
)

.method_OLE_obj <- setClass(
  "method_OLE_obj",
  contains = "method_obj"
)

# estimate() generic----

#' Run estimation for a method object
#'
#' S4 generic that dispatches to the appropriate estimation logic
#' based on the method class.
#'
#' @param method An S4 method object (e.g., from \code{\link{ec_ipw}}).
#' @param ... Method-specific arguments (data, outcomes, etc.).
#'
#' @return A list with estimation results.
#' @export
setGeneric("estimate", function(method, ...) standardGeneric("estimate"))

# bootstrap helpers----

#' @noRd
.boot_ci_type_long <- function(short) {
  switch(short,
    norm = "normal", bca = "bca", stud = "student",
    perc = "percent", basic = "basic"
  )
}

#' @noRd
.run_bootstrap <- function(df, statistic, n_estimates, bootstrap,
                           bootstrap_ci_type, alpha, ...) {
  group_id <- as.integer(interaction(df$S, df$A, drop = TRUE))
  ci_type_long <- .boot_ci_type_long(bootstrap_ci_type)

  boot_out <- boot::boot(
    data = df,
    statistic = statistic,
    R = bootstrap,
    strata = group_id,
    ...
  )

  lower_ci <- vapply(seq_len(n_estimates), \(i) {
    ci <- boot::boot.ci(boot_out, conf = 1 - alpha,
                        type = bootstrap_ci_type, index = i)
    ci[[ci_type_long]][4]
  }, numeric(1))

  upper_ci <- vapply(seq_len(n_estimates), \(i) {
    ci <- boot::boot.ci(boot_out, conf = 1 - alpha,
                        type = bootstrap_ci_type, index = i)
    ci[[ci_type_long]][5]
  }, numeric(1))

  sd_boot <- sqrt(diag(var(boot_out$t)))

  list(lower_ci = lower_ci, upper_ci = upper_ci, sd_boot = sd_boot)
}

# validation----

.validate_method_base <- function(method_name, bootstrap_flag, bootstrap_obj) {
  checkmate::assert_string(method_name)
  checkmate::assert_flag(bootstrap_flag)
  checkmate::assert_class(bootstrap_obj, "bootstrap_obj")
}

setup_method <- function(method_name = "",
                         bootstrap_flag = FALSE,
                         bootstrap_obj = .bootstrap_obj()) {
  .validate_method_base(method_name, bootstrap_flag, bootstrap_obj)

  method_obj <- .method_obj(
    method_name = method_name,
    bootstrap_flag = bootstrap_flag,
    bootstrap_obj = bootstrap_obj
  )
}
