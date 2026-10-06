# where does scm() fail when all covariates and outcomes are multiplied by 100?
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
cols <- c(paste0("x", 1:5), paste0("y", 1:4))
d <- SyntheticData
d[cols] <- d[cols] * 100
set.seed(7)
withCallingHandlers(
  ole(scm(lambda_min = 0, lambda_max = 0, nlambda = 1, bootstrap = 2), data = d),
  error = function(e) {
    cat("ERROR:", conditionMessage(e), "\ncall stack:\n")
    calls <- vapply(sys.calls(), \(x) paste(deparse(x)[1], collapse = ""), "")
    cat(paste0("  ", substr(calls, 1, 110)), sep = "\n")
  },
  warning = function(w) invokeRestart("muffleWarning")
) |> try(silent = TRUE) |> invisible()
