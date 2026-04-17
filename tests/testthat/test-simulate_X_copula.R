test_that("simulate_X_copula returns data.frame with correct dimensions", {
  result <- simulate_X_copula(
    n = 100, p = 2, cp = cop_2d,
    margins = c("norm", "norm"),
    paramMargins = params_std_2d
  )
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 100)
  expect_equal(ncol(result), 2)
  expect_named(result, c("x1", "x2"))
})

test_that("simulate_X_copula column names scale with p", {
  cop <- copula::normalCopula(param = c(0.5, 0.3, 0.4), dim = 3, dispstr = "un")
  params <- list(list(mean = 0, sd = 1), list(mean = 0, sd = 1), list(mean = 0, sd = 1))
  result <- simulate_X_copula(
    n = 50, p = 3, cp = cop,
    margins = c("norm", "norm", "norm"),
    paramMargins = params
  )
  expect_named(result, c("x1", "x2", "x3"))
})

test_that("simulate_X_copula is reproducible", {
  set.seed(42)
  r1 <- simulate_X_copula(
    n = 100, p = 2, cp = cop_2d,
    margins = c("norm", "norm"),
    paramMargins = params_std_2d
  )
  set.seed(42)
  r2 <- simulate_X_copula(
    n = 100, p = 2, cp = cop_2d,
    margins = c("norm", "norm"),
    paramMargins = params_std_2d
  )
  expect_equal(r1, r2)
})

test_that("simulate_X_copula respects marginal mean and sd", {
  set.seed(123)
  result <- simulate_X_copula(
    n = 10000, p = 2, cp = cop_2d,
    margins = c("norm", "norm"),
    paramMargins = list(list(mean = 5, sd = 2), list(mean = -3, sd = 1))
  )
  expect_equal(mean(result$x1), 5, tolerance = 0.1)
  expect_equal(mean(result$x2), -3, tolerance = 0.1)
  expect_equal(sd(result$x1), 2, tolerance = 0.1)
  expect_equal(sd(result$x2), 1, tolerance = 0.1)
})

test_that("simulate_X_copula respects copula correlation structure", {
  set.seed(123)
  result <- simulate_X_copula(
    n = 10000, p = 2, cp = copula::normalCopula(param = 0.8, dim = 2),
    margins = c("norm", "norm"),
    paramMargins = params_std_2d
  )
  expect_equal(cor(result$x1, result$x2), 0.8, tolerance = 0.05)
})

test_that("simulate_X_copula handles mixed marginals", {
  set.seed(123)
  result <- simulate_X_copula(
    n = 1000, p = 2, cp = cop_2d,
    margins = c("norm", "binom"),
    paramMargins = list(list(mean = 0, sd = 1), list(size = 1, prob = 0.4))
  )
  expect_s3_class(result, "data.frame")
  expect_all_true(result$x2 %in% c(0, 1))
  expect_equal(mean(result$x2), 0.4, tolerance = 0.1)
})

test_that("simulate_X_copula validates n", {
  expect_error(simulate_X_copula(n = 0, p = 2, cp = cop_2d, margins = c("norm", "norm"), paramMargins = params_std_2d))
  expect_error(simulate_X_copula(n = -1, p = 2, cp = cop_2d, margins = c("norm", "norm"), paramMargins = params_std_2d))
  expect_error(simulate_X_copula(n = 1.5, p = 2, cp = cop_2d, margins = c("norm", "norm"), paramMargins = params_std_2d))
  expect_error(simulate_X_copula(n = "100", p = 2, cp = cop_2d, margins = c("norm", "norm"), paramMargins = params_std_2d))
})

test_that("simulate_X_copula validates p", {
  expect_error(simulate_X_copula(n = 100, p = 0, cp = cop_2d, margins = c("norm", "norm"), paramMargins = params_std_2d))
  expect_error(simulate_X_copula(n = 100, p = "2", cp = cop_2d, margins = c("norm", "norm"), paramMargins = params_std_2d))
})

test_that("simulate_X_copula validates p matches copula dimension", {
  expect_error(
    simulate_X_copula(
      n = 100, p = 3, cp = cop_2d,
      margins = c("norm", "norm", "norm"),
      paramMargins = list(list(mean = 0, sd = 1), list(mean = 0, sd = 1), list(mean = 0, sd = 1))
    )
  )
})

test_that("simulate_X_copula validates cp is a copula", {
  expect_error(simulate_X_copula(n = 100, p = 2, cp = list(), margins = c("norm", "norm"), paramMargins = params_std_2d))
})

test_that("simulate_X_copula validates margins length", {
  expect_error(simulate_X_copula(n = 100, p = 2, cp = cop_2d, margins = "norm", paramMargins = params_std_2d))
})

test_that("simulate_X_copula validates paramMargins length", {
  expect_error(simulate_X_copula(n = 100, p = 2, cp = cop_2d, margins = c("norm", "norm"), paramMargins = list(list(mean = 0, sd = 1))))
})
