hm <- list(
  H01 = list(
    desc = "flip sign of treatment effect (tau = mu0 - mu1) in EC-IPW",
    file = "R/ec_ipw.R",
    old = "  tau <- mu1 - mu0\n",
    new = "  tau <- mu0 - mu1\n"
  ),
  H02 = list(
    desc = "flip sign of external-control term in the synthesized control mean (EC-AIPW)",
    file = "R/ec_aipw.R",
    old = "  mu0 <- (1 - borrow_weight) * mu10 + borrow_weight * mu00\n",
    new = "  mu0 <- (1 - borrow_weight) * mu10 - borrow_weight * mu00\n"
  ),
  H03 = list(
    desc = "drop normalization of the weighted external mean (Horvitz-Thompson / m instead of Hajek / sum(w))",
    file = "R/ec_ipw.R",
    old = "  mu00 <- colSums(w00_ext * Y_ext) / sum(w00_ext)\n",
    new = "  mu00 <- colSums(w00_ext * Y_ext) / length(w00_ext)\n"
  ),
  H04 = list(
    desc = "use 1 - pi_A instead of pi_A for the treated arm in the EC-IPW sandwich meat (w > 0)",
    file = "R/ec_ipw.R",
    old = "  phi1 <- S * A * sweep(Y, 2, core$mu1) / core$pi_A / pi_S\n",
    new = "  phi1 <- S * A * sweep(Y, 2, core$mu1) / (1 - core$pi_A) / pi_S\n"
  ),
  H05 = list(
    desc = "use pi_A instead of 1 - pi_A for the control arm in the EC-IPW w = 0 sandwich",
    file = "R/ec_ipw.R",
    old = "    phi0 <- (1 - A_rct) * sweep(Y_rct, 2, core$mu10) / (1 - core$pi_A)\n",
    new = "    phi0 <- (1 - A_rct) * sweep(Y_rct, 2, core$mu10) / core$pi_A\n"
  ),
  H06 = list(
    desc = "swap pi_A and 1 - pi_A in both EC-AIPW meat terms phi1 and phi2",
    file = "R/ec_aipw.R",
    old = "  phi1 <- S * A * sweep(core$Yr, 2, core$mu1) / core$pi_A / core$pi_S\n  phi2 <- S * (1 - A) * sweep(core$Yr, 2, core$mu10) /\n    (1 - core$pi_A) / core$pi_S\n",
    new = "  phi1 <- S * A * sweep(core$Yr, 2, core$mu1) / (1 - core$pi_A) / core$pi_S\n  phi2 <- S * (1 - A) * sweep(core$Yr, 2, core$mu10) /\n    core$pi_A / core$pi_S\n"
  ),
  H07 = list(
    desc = "use 1 - pi_A instead of pi_A in the trial-control weight W10 used by the optimal weight (EC-IPW)",
    file = "R/ec_ipw.R",
    old = "    w10 <- 1 / (1 - pi_A)\n",
    new = "    w10 <- 1 / pi_A\n"
  ),
  H08 = list(
    desc = "W00 = p/(1-p) without the (1 - pi_S)/pi_S factor",
    file = "R/ec_weights.R",
    old = "    w00 = (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S)\n",
    new = "    w00 = (pi_SX / (1 - pi_SX))\n"
  ),
  H09 = list(
    desc = "W00 with the pi_S factor inverted: pi_S/(1 - pi_S)",
    file = "R/ec_weights.R",
    old = "    w00 = (pi_SX / (1 - pi_SX)) * ((1 - pi_S) / pi_S)\n",
    new = "    w00 = (pi_SX / (1 - pi_SX)) * (pi_S / (1 - pi_S))\n"
  ),
  H10 = list(
    desc = "optimal weight uses the external sample size m in place of the trial-control count (EC-IPW)",
    file = "R/ec_ipw.R",
    old = "    n_ctrl <- sum(S == 1 & A == 0)\n",
    new = "    n_ctrl <- sum(S == 0)\n"
  ),
  H11 = list(
    desc = "optimal weight uses the trial-treated count in place of the trial-control count (EC-IPW)",
    file = "R/ec_ipw.R",
    old = "    n_ctrl <- sum(S == 1 & A == 0)\n",
    new = "    n_ctrl <- sum(S == 1 & A == 1)\n"
  ),
  H12 = list(
    desc = "optimal weight uses the whole trial size n in place of the trial-control count (EC-IPW)",
    file = "R/ec_ipw.R",
    old = "    n_ctrl <- sum(S == 1 & A == 0)\n",
    new = "    n_ctrl <- sum(S == 1)\n"
  ),
  H13 = list(
    desc = "optimal weight uses the external count for the trial-control term (EC-AIPW)",
    file = "R/ec_aipw.R",
    old = "    num <- sum(rep(w10^2, nrow(Yr_ctrl))) / sum(rep(w10, nrow(Yr_ctrl)))^2\n",
    new = "    num <- sum(rep(w10^2, nrow(Yr_ext))) / sum(rep(w10, nrow(Yr_ext)))^2\n"
  ),
  H14 = list(
    desc = "drop the A34 block (PS-estimation correction) from the EC-IPW bread",
    file = "R/ec_ipw.R",
    old = "  A_mat[(2 * n_time + 1):(3 * n_time), (3 * n_time + 1):block_dim] <- A34\n",
    new = "\n"
  ),
  H15 = list(
    desc = "drop the propensity-score score block from the EC-IPW meat",
    file = "R/ec_ipw.R",
    old = "  phi_ps <- (S - core$pi_SX) * X_model\n",
    new = "  phi_ps <- 0 * X_model\n"
  ),
  H16 = list(
    desc = "flip the sign of A44 (Hessian of the PS log-likelihood) in the EC-IPW bread",
    file = "R/ec_ipw.R",
    old = "  A44 <- t(X_model) %*% diag(-core$pi_SX * (1 - core$pi_SX)) %*% X_model / N\n",
    new = "  A44 <- t(X_model) %*% diag(core$pi_SX * (1 - core$pi_SX)) %*% X_model / N\n"
  ),
  H17 = list(
    desc = "drop the outcome-model blocks from the EC-AIPW bread (treat mu(X) as known)",
    file = "R/ec_aipw.R",
    old = "  A_right <- rbind(\n    Phi1_gamma, Phi2_gamma, Phi3_gamma,\n",
    new = "  A_right <- rbind(\n    0 * Phi1_gamma, 0 * Phi2_gamma, 0 * Phi3_gamma,\n"
  ),
  H18 = list(
    desc = "variance denominator n (trial size) instead of n + m in the EC-IPW sandwich",
    file = "R/ec_ipw.R",
    old = "  sd_tau <- sqrt(diag(coef_mat %*% sigma %*% t(coef_mat) / N))\n",
    new = "  sd_tau <- sqrt(diag(coef_mat %*% sigma %*% t(coef_mat) / n))\n"
  ),
  H19 = list(
    desc = "variance denominator n + m instead of n in the EC-IPW w = 0 sandwich",
    file = "R/ec_ipw.R",
    old = "    sd_tau <- sqrt(diag(coef_mat %*% B %*% t(coef_mat) / n))\n",
    new = "    sd_tau <- sqrt(diag(coef_mat %*% B %*% t(coef_mat) / N))\n"
  ),
  H20 = list(
    desc = "fit the EC-AIPW outcome model on treated patients",
    file = "R/ec_aipw.R",
    old = "    lm(as.formula(f), data = df[A == 0, , drop = FALSE])\n  })\n  Y0 <-",
    new = "    lm(as.formula(f), data = df[A == 1, , drop = FALSE])\n  })\n  Y0 <-"
  ),
  H21 = list(
    desc = "fit the EC-AIPW outcome model on trial controls only",
    file = "R/ec_aipw.R",
    old = "    lm(as.formula(f), data = df[A == 0, , drop = FALSE])\n  })\n  Y0 <-",
    new = "    lm(as.formula(f), data = df[A == 0 & S == 1, , drop = FALSE])\n  })\n  Y0 <-"
  ),
  H22 = list(
    desc = "swap lower and upper bound for the normal bootstrap CI only",
    file = "R/method_class.R",
    old = "    bounds <- if (ci_type_long == \"normal\") 2:3 else 4:5\n",
    new = "    bounds <- if (ci_type_long == \"normal\") 3:2 else 4:5\n"
  ),
  H23 = list(
    desc = "basic bootstrap CI silently computed as a percentile CI",
    file = "R/method_class.R",
    old = "    basic = \"basic\"\n",
    new = "    basic = \"percent\"\n"
  ),
  H24 = list(
    desc = "ignore alpha in bootstrap CIs (always 95%)",
    file = "R/method_class.R",
    old = "      conf = 1 - alpha,\n",
    new = "      conf = 0.95,\n"
  ),
  H25 = list(
    desc = "ignore alpha in EC-AIPW normal CIs (always 95%)",
    file = "R/ec_aipw.R",
    old = "  cutoff <- qnorm(1 - alpha / 2)\n",
    new = "  cutoff <- qnorm(1 - 0.05 / 2)\n"
  ),
  H26 = list(
    desc = "ignore alpha in EC-IPW normal CIs (always 95%)",
    file = "R/ec_ipw.R",
    old = "  cutoff <- qnorm(1 - alpha / 2)\n",
    new = "  cutoff <- qnorm(1 - 0.05 / 2)\n"
  ),
  H27 = list(
    desc = "ignore the bootstrap strata",
    file = "R/method_class.R",
    old = "    strata = group_id,\n",
    new = "\n"
  ),
  H28 = list(
    desc = "stratify the bootstrap by trial status only, not S x A",
    file = "R/method_class.R",
    old = "  group_id <- as.integer(interaction(df$S, df$A, drop = TRUE))\n",
    new = "  group_id <- as.integer(factor(df$S))\n"
  ),
  H29 = list(
    desc = "bootstrap CI for every estimate taken from index 1 (tau1)",
    file = "R/method_class.R",
    old = "      type = bootstrap_ci_type, index = i\n",
    new = "      type = bootstrap_ci_type, index = 1\n"
  ),
  H30 = list(
    desc = "EC-AIPW: scale the outcome-model meat by 1/(1 - pi_A) but leave the bread at 1/(1 - mean(A))",
    file = "R/ec_aipw.R",
    old = "    ((1 - A) / (1 - mean(A))) * (core$Yr[, t] * Y0_model_mats[[t]])\n",
    new = "    ((1 - A) / (1 - core$pi_A)) * (core$Yr[, t] * Y0_model_mats[[t]])\n"
  ),
  H31 = list(
    desc = "EC-AIPW: treated mean uses raw Y instead of the residual Y - mu(X)",
    file = "R/ec_aipw.R",
    old = "  mu1 <- colMeans(Yr_trt)\n",
    new = "  mu1 <- colMeans(Y[S == 1 & A == 1, , drop = FALSE])\n"
  ),
  H32 = list(
    desc = "re-estimate the optimal weight inside every EC-AIPW bootstrap replicate",
    file = "R/ec_aipw.R",
    old = "  core <- .ec_aipw_core(d, outcomes, ps_formula, outcome_formula, borrow_wt)\n",
    new = "  core <- .ec_aipw_core(d, outcomes, ps_formula, outcome_formula, NULL)\n"
  ),
  H33 = list(
    desc = "ps_formula LHS hard-coded to S (what the developer article says the code does)",
    file = "R/ec_ipw.R",
    old = "  ps_formula <- sub(\"^[^~]*~\", paste0(trial_status, \" ~\"), method@ps_formula)\n",
    new = "  ps_formula <- sub(\"^[^~]*~\", \"S ~\", method@ps_formula)\n"
  ),
  H37 = list(
    desc = "ps_formula LHS hard-coded to S in EC-AIPW (companion to H33)",
    file = "R/ec_aipw.R",
    old = "  ps_formula <- sub(\"^[^~]*~\", paste0(trial_status, \" ~\"), method@ps_formula)\n",
    new = "  ps_formula <- sub(\"^[^~]*~\", \"S ~\", method@ps_formula)\n"
  ),
  H38 = list(
    desc = "basic bootstrap CI silently computed as a percentile CI (no error)",
    file = "R/method_class.R",
    old = "    basic = \"basic\"\n  )\n",
    new = "    basic = \"percent\"\n  )\n  if (bootstrap_ci_type == \"basic\") bootstrap_ci_type <- \"perc\"\n"
  ),
  H39 = list(
    desc = "normal bootstrap CI ignores the bootstrap bias correction (centred on tau-hat)",
    file = "R/method_class.R",
    old = "    ci[[ci_type_long]][bounds]\n",
    new = "    if (ci_type_long == \"normal\") {\n      z <- qnorm(1 - alpha / 2) * sd(boot_out$t[, i])\n      return(boot_out$t0[i] + c(-z, z))\n    }\n    ci[[ci_type_long]][bounds]\n"
  ),
  H34 = list(
    desc = "EC-IPW w = 0 sandwich divides the meat by N instead of n",
    file = "R/ec_ipw.R",
    old = "    B <- crossprod(cbind(phi1, phi0)) / n\n",
    new = "    B <- crossprod(cbind(phi1, phi0)) / N\n"
  ),
  H35 = list(
    desc = "EC-AIPW sandwich uses pi_S = n/N computed on the external count (m/N)",
    file = "R/ec_aipw.R",
    old = "  pi_S <- n / N\n",
    new = "  pi_S <- (N - n) / N\n"
  ),
  H36 = list(
    desc = "EC-IPW variance drops the cross-covariance terms (paper Eq 13 form)",
    file = "R/ec_ipw.R",
    old = "  sd_tau <- sqrt(diag(coef_mat %*% sigma %*% t(coef_mat) / N))\n",
    new = "  sd_tau <- sqrt(vapply(seq_len(n_time), \\(t) {\n    sum(coef_mat[t, ]^2 * diag(sigma))\n  }, numeric(1)) / N)\n"
  )
)
