source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/bb/hdr.R")
d <- SyntheticData
pr <- function(m, ...) {
  rr <- w(run_analysis(mk(m, ...)))
  if (!is.null(rr)) {
    print(rr$results)
    cat("borrow_weight:", rr$borrow_weight, "\n")
  }
  invisible(rr)
}
dA <- d; names(dA)[names(dA) == "A"] <- "arm"
cat("## reference: treatment 'arm', outcome y1\n")
pr(ec_ipw(F5), data = dA, A = "arm", outcomes = "y1")
cat("## outcome column named 'A' (copy of y1), treatment 'arm'\n")
do <- dA; do$A <- do$y1
pr(ec_ipw(F5), data = do, A = "arm", outcomes = "A")
pr(ec_aipw(F5, "A ~ x1 + x2 + x3 + x4 + x5"), data = do, A = "arm", outcomes = "A")
cat("## binary 0/1 outcome named 'A', treatment 'arm'\n")
db <- dA; db$A <- as.numeric(db$y1 > 0); db$ybin <- db$A
pr(ec_ipw(F5), data = db, A = "arm", outcomes = "ybin")
pr(ec_ipw(F5), data = db, A = "arm", outcomes = "A")
