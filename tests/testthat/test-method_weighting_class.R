test_that("setup_method_weighting returns default object", {
  obj <- setup_method_weighting()
  expect_s4_class(obj, "method_weighting_obj")
  expect_identical(obj@method_name, "IPW")
  expect_identical(obj@optimal_weight_flag, FALSE)
  expect_identical(obj@wt, 0)
  expect_identical(obj@bootstrap_flag, FALSE)
})

test_that("setup_method_weighting accepts valid arguments", {
  obj <- setup_method_weighting(
    method_name = "AIPW",
    optimal_weight_flag = TRUE,
    wt = 0.5,
    bootstrap_flag = TRUE,
    bootstrap_obj = setup_bootstrap(),
    model_form_piS = "S ~ x1 + x2"
  )
  expect_identical(obj@method_name, "AIPW")
  expect_identical(obj@optimal_weight_flag, TRUE)
  expect_identical(obj@wt, 0.5)
  expect_identical(obj@model_form_piS, "S ~ x1 + x2")
})

test_that("setup_method_weighting inherits base validation", {
  expect_error(setup_method_weighting(method_name = 123))
  expect_error(setup_method_weighting(bootstrap_flag = "yes"))
  expect_error(setup_method_weighting(bootstrap_obj = list()))
})

test_that("setup_method_weighting validates weighting-specific args", {
  expect_error(setup_method_weighting(optimal_weight_flag = "yes"))
  expect_error(setup_method_weighting(wt = "heavy"))
  expect_error(setup_method_weighting(model_form_piS = 123))
})
