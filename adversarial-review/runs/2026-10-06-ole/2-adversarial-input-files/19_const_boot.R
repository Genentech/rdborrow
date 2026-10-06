# every bootstrap replicate equal to a non-zero constant: boot.ci() returns NULL
# example: an OLE visit at which every treated patient is at the scale ceiling
# and every untreated patient is at the floor. seed 2024
source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-ole/r2/helper.R")
d <- make_ole(seed = 1)
d$y4 <- ifelse(d$A == 1, 32, 0)
d$y1 <- 0
d$y2 <- 0
show_try(fit(d, m_ipw(20)))
show_try(fit(d, m_or(20)))
