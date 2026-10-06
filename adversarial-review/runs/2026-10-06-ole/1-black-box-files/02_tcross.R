# T_cross limits and outcome-vector lengths
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/bb/setup.R")
y4 <- c("y1", "y2", "y3", "y4")
mk <- list(
  ipw = function(o) did_ec_ipw("S ~ x1 + x2 + x3 + x4 + x5", bootstrap = 20),
  aipw = function(o) did_ec_aipw("S ~ x1 + x2 + x3 + x4 + x5", outcome_formula = f5(o), bootstrap = 20),
  or = function(o) did_ec_or(f5(o), f5(o), f5(o), bootstrap = 20)
)
for (tc in list(1, 2, 3, 4, 5, 0, -1, 2.5, 2L, "2", NA, c(1, 2), 1e-9 + 2)) {
  for (m in names(mk)) {
    cat("\n## T_cross =", deparse(tc), "method", m, "\n")
    set.seed(1)
    print(show(ole(mk[[m]](y4), T_cross = tc)))
  }
}

cat("\n#### one post-crossover visit: outcomes y1..y3, T_cross = 2\n")
for (m in names(mk)) {
  set.seed(1)
  print(show(ole(mk[[m]](y4[1:3]), outcomes = y4[1:3], T_cross = 2)))
}
cat("\n#### one pre-crossover visit: outcomes y2..y4, T_cross = 1\n")
for (m in names(mk)) {
  set.seed(1)
  print(show(ole(mk[[m]](y4[2:4]), outcomes = y4[2:4], T_cross = 1)))
}
cat("\n#### two outcomes, T_cross = 1\n")
for (m in names(mk)) {
  set.seed(1)
  print(show(ole(mk[[m]](c("y2", "y3")), outcomes = c("y2", "y3"), T_cross = 1)))
}
cat("\n#### one outcome\n")
for (m in names(mk)) {
  set.seed(1)
  print(show(ole(mk[[m]]("y3"), outcomes = "y3", T_cross = 1)))
}
