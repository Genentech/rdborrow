test_that("setup_method_SCM returns valid object", {
  obj <- setup_method_SCM(lambda.min = 0, lambda.max = 1e-3)
  expect_s4_class(obj, "method_SCM_obj")
  expect_identical(obj@method_name, "SCM")
  expect_identical(obj@lambda.min, 0)
  expect_identical(obj@lambda.max, 1e-3)
  expect_identical(obj@nlambda, 10)
  expect_identical(obj@parallel, "no")
  expect_identical(obj@ncpus, 1)
})

test_that("setup_method_SCM accepts valid arguments", {
  obj <- setup_method_SCM(
    lambda.min = 0,
    lambda.max = 1,
    nlambda = 20,
    parallel = "multicore",
    ncpus = 4
  )
  expect_identical(obj@nlambda, 20)
  expect_identical(obj@parallel, "multicore")
  expect_identical(obj@ncpus, 4)
})

test_that("setup_method_SCM inherits base validation", {
  expect_error(setup_method_SCM(lambda.min = 0, lambda.max = 1, method_name = 123))
  expect_error(setup_method_SCM(lambda.min = 0, lambda.max = 1, bootstrap_flag = "yes"))
  expect_error(setup_method_SCM(lambda.min = 0, lambda.max = 1, bootstrap_obj = list()))
})

test_that("setup_method_SCM validates SCM-specific args", {
  expect_error(setup_method_SCM(lambda.min = 1, lambda.max = 0))
  expect_error(setup_method_SCM(lambda.min = 0, lambda.max = 1, nlambda = 0))
  expect_error(setup_method_SCM(lambda.min = 0, lambda.max = 1, parallel = "unknown"))
  expect_error(setup_method_SCM(lambda.min = 0, lambda.max = 1, ncpus = 0))
})
