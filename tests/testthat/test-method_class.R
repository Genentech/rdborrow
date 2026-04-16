test_that("setup_method returns default object", {
  obj <- setup_method()
  expect_s4_class(obj, "method_obj")
  expect_identical(obj@method_name, "")
  expect_identical(obj@bootstrap_flag, FALSE)
  expect_s4_class(obj@bootstrap_obj, "bootstrap_obj")
})

test_that("setup_method accepts valid arguments", {
  obj <- setup_method(
    method_name = "AIPW",
    bootstrap_flag = TRUE,
    bootstrap_obj = setup_bootstrap()
  )
  expect_identical(obj@method_name, "AIPW")
  expect_identical(obj@bootstrap_flag, TRUE)
})

test_that("setup_method validates method_name", {
  expect_error(setup_method(method_name = 123))
  expect_error(setup_method(method_name = NA))
  expect_error(setup_method(method_name = c("a", "b")))
})

test_that("setup_method validates bootstrap_flag", {
  expect_error(setup_method(bootstrap_flag = "true"))
  expect_error(setup_method(bootstrap_flag = NA))
  expect_error(setup_method(bootstrap_flag = 1))
})

test_that("setup_method validates bootstrap_obj", {
  expect_error(setup_method(bootstrap_obj = list()))
  expect_error(setup_method(bootstrap_obj = "not_an_obj"))
})
