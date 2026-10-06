suppressMessages(pkgload::load_all("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/4-test-strength-artifacts/handpkg", quiet = TRUE))
d <- SyntheticData
names(d)[names(d) == "S"] <- "trial"
names(d)[names(d) == "A"] <- "arm"
for (meth in list(
  did_ec_ipw("trial ~ x1 + x2", trt_formula = "arm ~ x1", bootstrap = 20),
  did_ec_aipw("trial ~ x1 + x2", trt_formula = "arm ~ x1",
    outcome_formula = paste0("y", 1:4, " ~ x1"), bootstrap = 20)
)) {
  a <- setup_analysis_OLE(d, "trial", "arm", paste0("y", 1:4), c("x1", "x2"),
    method_OLE_obj = meth, T_cross = 2)
  r <- try(suppressWarnings(run_analysis(a)))
  print(r)
}
