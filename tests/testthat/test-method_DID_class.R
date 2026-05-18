test_that("setup_method_DID returns default object", {
  obj <- suppressWarnings(setup_method_DID())
  expect_s4_class(obj, "method_DID_obj")
  expect_identical(obj@method_name, "IPW")
  expect_identical(obj@bootstrap_flag, FALSE)
  expect_identical(obj@model_form_piS, "")
  expect_identical(obj@model_form_piA, "")
})

test_that("setup_method_DID accepts valid arguments", {
  obj <- suppressWarnings(setup_method_DID(
    method_name = "AIPW",
    bootstrap_flag = TRUE,
    bootstrap_obj = setup_bootstrap(),
    model_form_piS = "S ~ x1 + x2",
    model_form_piA = "A ~ x1 + x2"
  ))
  expect_identical(obj@method_name, "AIPW")
  expect_identical(obj@model_form_piS, "S ~ x1 + x2")
  expect_identical(obj@model_form_piA, "A ~ x1 + x2")
})

test_that("setup_method_DID inherits base validation", {
  expect_warning(expect_error(setup_method_DID(method_name = 123)))
  expect_warning(expect_error(setup_method_DID(bootstrap_flag = "yes")))
  expect_warning(expect_error(setup_method_DID(bootstrap_obj = list())))
})

test_that("setup_method_DID validates DID-specific args", {
  expect_warning(expect_error(setup_method_DID(model_form_piS = 123)))
  expect_warning(expect_error(setup_method_DID(model_form_piA = NA)))
  expect_warning(expect_error(setup_method_DID(model_form_mu0_ext = 123)))
})
