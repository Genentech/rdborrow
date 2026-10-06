source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
for (topic in c("did_ec_ipw", "did_ec_aipw", "did_ec_or", "scm", "setup_analysis_OLE", "run_analysis")) {
  cat("\n===== example(", topic, ")\n")
  show(example(topic, package = "rdborrow", character.only = TRUE, echo = TRUE, run.dontrun = FALSE))
}
