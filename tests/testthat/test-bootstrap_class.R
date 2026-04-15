test_that("setup_bootstrap returns default object", {
  obj <- setup_bootstrap()
  expect_s4_class(obj, "bootstrap_obj")
  expect_identical(obj@replicates, 500)
  expect_identical(obj@bootstrap_CI_type, "bca")
})

test_that("setup_bootstrap accepts valid arguments", {
  obj <- setup_bootstrap(replicates = 2000, bootstrap_CI_type = "perc")
  expect_identical(obj@replicates, 2000)
  expect_identical(obj@bootstrap_CI_type, "perc")
})

test_that("setup_bootstrap validates replicates", {
  expect_error(setup_bootstrap(replicates = -1))
  expect_error(setup_bootstrap(replicates = 0))
  expect_error(setup_bootstrap(replicates = 1.5))
  expect_error(setup_bootstrap(replicates = "abc"))
  expect_error(setup_bootstrap(replicates = NA))
  expect_error(setup_bootstrap(replicates = c(1, 2)))
})

test_that("setup_bootstrap validates bootstrap_CI_type", {
  expect_error(setup_bootstrap(bootstrap_CI_type = "xyz"))
  expect_error(setup_bootstrap(bootstrap_CI_type = 123))
  expect_error(setup_bootstrap(bootstrap_CI_type = NA))
})

test_that("setup_bootstrap accepts all valid CI types", {
  for (ci in c("bca", "norm", "basic", "stud", "perc")) {
    obj <- setup_bootstrap(bootstrap_CI_type = ci)
    expect_identical(obj@bootstrap_CI_type, ci)
  }
})

test_that("show method prints without error", {
  obj <- setup_bootstrap()
  expect_output(show(obj), "bootstrap_obj")
  expect_output(show(obj), "Replicates: 500")
  expect_output(show(obj), "Bias-corrected")
})
