source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
cat(R.version.string, "\n")
print(packageVersion("rdborrow"))
print(find.package("rdborrow"))
for (f in c("ec_ipw", "ec_aipw", "setup_analysis_primary", "run_analysis")) {
  cat("\n######## example:", f, "\n")
  set.seed(1)
  w(example(f, package = "rdborrow", character.only = TRUE, ask = FALSE, echo = TRUE))
}
