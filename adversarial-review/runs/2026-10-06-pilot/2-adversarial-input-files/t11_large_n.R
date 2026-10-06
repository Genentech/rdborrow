source("/tmp/claude-1000/-home-matts-Documents-rdborrow/403de6d7-6cc1-4a41-9c33-1c39c7fb55db/scratchpad/review-pilot/r2/h.R")
args <- commandArgs(TRUE)
m_ext <- as.integer(args[1])
which_m <- args[2]
set.seed(2026)
trial <- SyntheticData[SyntheticData$S == 1, ]
ext <- SyntheticData[SyntheticData$S == 0, ]
ext_big <- ext[sample(nrow(ext), m_ext, replace = TRUE), ]
ext_big$x5 <- ext_big$x5 + rnorm(m_ext, 0, 1)
ext_big$y1 <- ext_big$y1 + rnorm(m_ext, 0, 1)
ext_big$y2 <- ext_big$y2 + rnorm(m_ext, 0, 1)
d <- rbind(trial, ext_big)
m <- if (which_m == "ipw") ec_ipw(ps5) else ec_aipw(ps5, of5)
gc(reset = TRUE)
tm <- system.time(r <- ra(m, d))
mem <- gc()
cat(sprintf("N = %d (m = %d), %s: elapsed %.1f s, max R heap used %.0f MB\n",
  nrow(d), m_ext, which_m, tm[["elapsed"]], sum(mem[, ncol(mem)])))
show_res(r)
