# non-syntactic column names, tibble input, outcome names in the result
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)

cat("=== N1 outcome names with a space ('week 26' ...) through did_ec_ipw and scm\n")
dn <- d
names(dn)[names(dn) %in% ycols()] <- c("week 26", "week 52", "week 78", "week 104")
out <- c("week 26", "week 52", "week 78", "week 104")
show_try(fit(dn, m_ipw(20), outcomes = out))
show_try(fit(dn, m_scm(2), outcomes = out))

cat("\n=== N2 covariate name with a hyphen ('smn2-copies') through did_ec_ipw and scm\n")
dn <- d
names(dn)[names(dn) == "x3"] <- "smn2-copies"
covs <- c("x1", "x2", "smn2-copies")
show_try(fit(dn, did_ec_ipw("S ~ x1 + x2 + `smn2-copies`", bootstrap = 20), covs = covs))
show_try(fit(dn, m_scm(2), covs = covs))

cat("\n=== N3 outcome names starting with a digit ('1y' ...) through did_ec_or\n")
dn <- d
names(dn)[names(dn) %in% ycols()] <- paste0(1:4, "y")
ff <- paste0("`", 1:4, "y` ~ x1 + x2 + x3")
show_try(fit(dn, did_ec_or(ff, ff, ff, bootstrap = 20), outcomes = paste0(1:4, "y")))

if (requireNamespace("tibble", quietly = TRUE)) {
  cat("\n=== N4 tibble input\n")
  show_try(fit(tibble::as_tibble(d), m_ipw(20)))
  show_try(fit(tibble::as_tibble(d), m_scm(2)))
}
