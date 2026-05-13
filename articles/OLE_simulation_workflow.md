# Simulation Workflow for OLE Phase

## OLE study

This vignette demonstrates Monte Carlo simulation for evaluating the
difference-in-differences (DID) estimators proposed in [Zhou et
al. (2024)](https://doi.org/10.1080/10543406.2024.2444222) for the
open-label extension (OLE) phase.

### 1. Simulate a dataset for OLE study

``` r

# Initialize an empty data list
set.seed(2023)

data_matrix_list <- list()
ntrial <- 500

# Specify the significance level alpha
alpha <- 0.05

# Specify the true effect size at the end of the OLE study
true_effect_long <- 0

# Specify column names
covariates_col_name <- c("x1", "x2", "x3", "x4", "x5")
outcome_col_name <- c("y1", "y2", "y3", "y4")
treatment_col_name <- "A"
trial_status_col_name <- "S"
```

``` r

# Sequentially adding in datasets
for (trial_iter in 1:ntrial) {
  # simulate 300 sample
  normal <- copula::normalCopula(param = c(0.8), dim = 4, dispstr = "ar1")

  # ========== generate internal covariates =============
  X_int <- simulate_X_copula(
    n = 200,
    p = 4,
    cp = normal, # copula
    margins = c("binom", "binom", "binom", "exp"), # specify marginal distributions
    paramMargins = list(
      list(size = 1, prob = 0.7), # specify parameters for marginals
      list(size = 1, prob = 0.9),
      list(size = 1, prob = 0.3),
      list(rate = 1 / 10)
    )
  )

  X_int$x4 <- round(X_int$x4) + 1
  X_int$x5 <- 30 + 10 * X_int$x1 + (7) * X_int$x2 + (-6) * X_int$x3 + (-0.5) * X_int$x4 + rnorm(200, mean = 0, sd = 10)

  varnames <- c("1", paste0("x", 1:5))

  # ============ generate external covariates ==============
  X_ext <- simulate_X_copula(
    n = 100,
    p = 4,
    cp = normal, # copula
    margins = c("binom", "binom", "binom", "exp"), # specify marginal distributions
    paramMargins = list(
      list(size = 1, prob = 0.7), # specify parameters for marginals
      list(size = 1, prob = 0.9),
      list(size = 1, prob = 0.3),
      list(rate = 1 / 10)
    )
  )

  X_ext$x4 <- round(X_ext$x4) + 1
  X_ext$x5 <- 50 + 10 * X_ext$x1 + (2) * X_ext$x2 + (-1) * X_ext$x3 + (-0.3) * X_ext$x4 + rnorm(100, mean = 0, sd = 10)

  varnames <- c("1", paste0("x", 1:5))

  # ============ Specify outcome models ==============
  model_form_x_t1 <- setNames(c(10.0, 0.05, -1.5, -1.0, -0.2, -0.1), varnames) # 1.5*A, sigma = 4.0
  model_form_x_t2 <- setNames(c(6.0, 0.5, -0.5, -1.0, -0.3, -0.06), varnames) # 1.8*A, sigma = 4.0
  model_form_x_t3 <- setNames(c(5.0, 1.9, 1.4, -1.3, -0.4, -0.15), varnames) # 1.6*A, sigma = 4.0
  model_form_x_t4 <- setNames(c(1.2, 1.0, 2.0, -0.5, -0.4, -0.10), varnames) # 2.5*A, sigma = 5.0

  outcome_model_specs <- list(
    list(
      effect = 0, model_form_x = model_form_x_t1, # from data: true_effect = 1.5
      noise_mean = 0, noise_sd = 4
    ), # model form for the first time point, given by model_form_x_t1
    list(
      effect = 0, model_form_x = model_form_x_t2, # from data: true_effect = 1.8
      noise_mean = 0, noise_sd = 4
    ), # model form for the second time point, given by model_form_x_t2
    list(
      effect = 0, model_form_x = model_form_x_t3, # from data: true_effect = 1.6
      noise_mean = 0, noise_sd = 4
    ), # model form for the third time point, given by model_form_x_t3
    list(
      effect = true_effect_long, model_form_x = model_form_x_t4, # from data: true_effect = 2.5
      noise_mean = 0, noise_sd = 4
    ) # model form for the fourth time point, given by model_form_x_t4
  )

  # =========== generate trial data ============
  Data <- simulate_trial(X_int,
    X_ext,
    num_treated = 150,
    OLE_flag = TRUE,
    T_cross = 2,
    outcome_model_specs
  )


  data_matrix_list[[trial_iter]] <- Data
}
```

### 2 Bootstrap inference

``` r

# Specify a list of methods to be tested
bootstrap_obj <- setup_bootstrap(
  replicates = 50,
  bootstrap_CI_type = "perc"
)

model_form_mu <- c(
  "y1 ~ x1 + x2 + x3 + x4 + x5",
  "y2 ~ x1 + x2 + x3 + x4 + x5",
  "y3 ~ x1 + x2 + x3 + x4 + x5",
  "y4 ~ x1 + x2 + x3 + x4 + x5"
)

## IPW - optimal weight
method_IPW_DID <- setup_method_DID(
  method_name = "IPW",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5"
)

## AIPW - optimal weight
method_AIPW_DID <- setup_method_DID(
  method_name = "AIPW",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_piS = "S ~ x1 + x2 + x3 + x4 + x5",
  model_form_piA = "A ~ x1 + x2 + x3 + x4 + x5",
  model_form_mu0_ext = model_form_mu
)

## OR - optimal weight

method_OR_DID <- setup_method_DID(
  method_name = "OR",
  bootstrap_flag = TRUE,
  bootstrap_obj = bootstrap_obj,
  model_form_mu0_ext = model_form_mu,
  model_form_mu0_rct = model_form_mu,
  model_form_mu1_rct = model_form_mu
)

## method list
method_obj_list <- list(
  method_IPW_DID,
  method_AIPW_DID,
  method_OR_DID
)
```

``` r

# create a simulation object for primary analysis
simulation_OLE_obj <- setup_simulation_OLE(
  data_matrix_list = data_matrix_list, # two scenarios
  trial_status_col_name = trial_status_col_name,
  treatment_col_name = treatment_col_name,
  outcome_col_name = outcome_col_name,
  covariates_col_name = covariates_col_name,
  method_obj_list = method_obj_list,
  true_effect = true_effect_long,
  T_cross = 2,
  alpha = alpha,
  method_description = c(
    "IPW, DID",
    "AIPW, DID",
    "OR, DID"
  )
)
```

``` r

simulation_report <- run_simulation(simulation_OLE_obj, quiet = FALSE)
#> Null:  | method setting:  1 | data setting:  1 
#> Null:  | method setting:  1 | data setting:  2 
#> Null:  | method setting:  1 | data setting:  3 
#> Null:  | method setting:  1 | data setting:  4 
#> Null:  | method setting:  1 | data setting:  5 
#> Null:  | method setting:  1 | data setting:  6 
#> Null:  | method setting:  1 | data setting:  7 
#> Null:  | method setting:  1 | data setting:  8 
#> Null:  | method setting:  1 | data setting:  9 
#> Null:  | method setting:  1 | data setting:  10 
#> Null:  | method setting:  1 | data setting:  11 
#> Null:  | method setting:  1 | data setting:  12 
#> Null:  | method setting:  1 | data setting:  13 
#> Null:  | method setting:  1 | data setting:  14 
#> Null:  | method setting:  1 | data setting:  15 
#> Null:  | method setting:  1 | data setting:  16 
#> Null:  | method setting:  1 | data setting:  17 
#> Null:  | method setting:  1 | data setting:  18 
#> Null:  | method setting:  1 | data setting:  19 
#> Null:  | method setting:  1 | data setting:  20 
#> Null:  | method setting:  1 | data setting:  21 
#> Null:  | method setting:  1 | data setting:  22 
#> Null:  | method setting:  1 | data setting:  23 
#> Null:  | method setting:  1 | data setting:  24 
#> Null:  | method setting:  1 | data setting:  25 
#> Null:  | method setting:  1 | data setting:  26 
#> Null:  | method setting:  1 | data setting:  27 
#> Null:  | method setting:  1 | data setting:  28 
#> Null:  | method setting:  1 | data setting:  29 
#> Null:  | method setting:  1 | data setting:  30 
#> Null:  | method setting:  1 | data setting:  31 
#> Null:  | method setting:  1 | data setting:  32 
#> Null:  | method setting:  1 | data setting:  33 
#> Null:  | method setting:  1 | data setting:  34 
#> Null:  | method setting:  1 | data setting:  35 
#> Null:  | method setting:  1 | data setting:  36 
#> Null:  | method setting:  1 | data setting:  37 
#> Null:  | method setting:  1 | data setting:  38 
#> Null:  | method setting:  1 | data setting:  39 
#> Null:  | method setting:  1 | data setting:  40 
#> Null:  | method setting:  1 | data setting:  41 
#> Null:  | method setting:  1 | data setting:  42 
#> Null:  | method setting:  1 | data setting:  43 
#> Null:  | method setting:  1 | data setting:  44 
#> Null:  | method setting:  1 | data setting:  45 
#> Null:  | method setting:  1 | data setting:  46 
#> Null:  | method setting:  1 | data setting:  47 
#> Null:  | method setting:  1 | data setting:  48 
#> Null:  | method setting:  1 | data setting:  49 
#> Null:  | method setting:  1 | data setting:  50 
#> Null:  | method setting:  1 | data setting:  51 
#> Null:  | method setting:  1 | data setting:  52 
#> Null:  | method setting:  1 | data setting:  53 
#> Null:  | method setting:  1 | data setting:  54 
#> Null:  | method setting:  1 | data setting:  55 
#> Null:  | method setting:  1 | data setting:  56 
#> Null:  | method setting:  1 | data setting:  57 
#> Null:  | method setting:  1 | data setting:  58 
#> Null:  | method setting:  1 | data setting:  59 
#> Null:  | method setting:  1 | data setting:  60 
#> Null:  | method setting:  1 | data setting:  61 
#> Null:  | method setting:  1 | data setting:  62 
#> Null:  | method setting:  1 | data setting:  63 
#> Null:  | method setting:  1 | data setting:  64 
#> Null:  | method setting:  1 | data setting:  65 
#> Null:  | method setting:  1 | data setting:  66 
#> Null:  | method setting:  1 | data setting:  67 
#> Null:  | method setting:  1 | data setting:  68 
#> Null:  | method setting:  1 | data setting:  69 
#> Null:  | method setting:  1 | data setting:  70 
#> Null:  | method setting:  1 | data setting:  71 
#> Null:  | method setting:  1 | data setting:  72 
#> Null:  | method setting:  1 | data setting:  73 
#> Null:  | method setting:  1 | data setting:  74 
#> Null:  | method setting:  1 | data setting:  75 
#> Null:  | method setting:  1 | data setting:  76 
#> Null:  | method setting:  1 | data setting:  77 
#> Null:  | method setting:  1 | data setting:  78 
#> Null:  | method setting:  1 | data setting:  79 
#> Null:  | method setting:  1 | data setting:  80 
#> Null:  | method setting:  1 | data setting:  81 
#> Null:  | method setting:  1 | data setting:  82 
#> Null:  | method setting:  1 | data setting:  83 
#> Null:  | method setting:  1 | data setting:  84 
#> Null:  | method setting:  1 | data setting:  85 
#> Null:  | method setting:  1 | data setting:  86 
#> Null:  | method setting:  1 | data setting:  87 
#> Null:  | method setting:  1 | data setting:  88 
#> Null:  | method setting:  1 | data setting:  89 
#> Null:  | method setting:  1 | data setting:  90 
#> Null:  | method setting:  1 | data setting:  91 
#> Null:  | method setting:  1 | data setting:  92 
#> Null:  | method setting:  1 | data setting:  93 
#> Null:  | method setting:  1 | data setting:  94 
#> Null:  | method setting:  1 | data setting:  95 
#> Null:  | method setting:  1 | data setting:  96 
#> Null:  | method setting:  1 | data setting:  97 
#> Null:  | method setting:  1 | data setting:  98 
#> Null:  | method setting:  1 | data setting:  99 
#> Null:  | method setting:  1 | data setting:  100 
#> Null:  | method setting:  1 | data setting:  101 
#> Null:  | method setting:  1 | data setting:  102 
#> Null:  | method setting:  1 | data setting:  103 
#> Null:  | method setting:  1 | data setting:  104 
#> Null:  | method setting:  1 | data setting:  105 
#> Null:  | method setting:  1 | data setting:  106 
#> Null:  | method setting:  1 | data setting:  107 
#> Null:  | method setting:  1 | data setting:  108 
#> Null:  | method setting:  1 | data setting:  109 
#> Null:  | method setting:  1 | data setting:  110 
#> Null:  | method setting:  1 | data setting:  111 
#> Null:  | method setting:  1 | data setting:  112 
#> Null:  | method setting:  1 | data setting:  113 
#> Null:  | method setting:  1 | data setting:  114 
#> Null:  | method setting:  1 | data setting:  115 
#> Null:  | method setting:  1 | data setting:  116 
#> Null:  | method setting:  1 | data setting:  117 
#> Null:  | method setting:  1 | data setting:  118 
#> Null:  | method setting:  1 | data setting:  119 
#> Null:  | method setting:  1 | data setting:  120 
#> Null:  | method setting:  1 | data setting:  121 
#> Null:  | method setting:  1 | data setting:  122 
#> Null:  | method setting:  1 | data setting:  123 
#> Null:  | method setting:  1 | data setting:  124 
#> Null:  | method setting:  1 | data setting:  125 
#> Null:  | method setting:  1 | data setting:  126 
#> Null:  | method setting:  1 | data setting:  127 
#> Null:  | method setting:  1 | data setting:  128 
#> Null:  | method setting:  1 | data setting:  129 
#> Null:  | method setting:  1 | data setting:  130 
#> Null:  | method setting:  1 | data setting:  131 
#> Null:  | method setting:  1 | data setting:  132 
#> Null:  | method setting:  1 | data setting:  133 
#> Null:  | method setting:  1 | data setting:  134 
#> Null:  | method setting:  1 | data setting:  135 
#> Null:  | method setting:  1 | data setting:  136 
#> Null:  | method setting:  1 | data setting:  137 
#> Null:  | method setting:  1 | data setting:  138 
#> Null:  | method setting:  1 | data setting:  139 
#> Null:  | method setting:  1 | data setting:  140 
#> Null:  | method setting:  1 | data setting:  141 
#> Null:  | method setting:  1 | data setting:  142 
#> Null:  | method setting:  1 | data setting:  143 
#> Null:  | method setting:  1 | data setting:  144 
#> Null:  | method setting:  1 | data setting:  145 
#> Null:  | method setting:  1 | data setting:  146 
#> Null:  | method setting:  1 | data setting:  147 
#> Null:  | method setting:  1 | data setting:  148 
#> Null:  | method setting:  1 | data setting:  149 
#> Null:  | method setting:  1 | data setting:  150 
#> Null:  | method setting:  1 | data setting:  151 
#> Null:  | method setting:  1 | data setting:  152 
#> Null:  | method setting:  1 | data setting:  153 
#> Null:  | method setting:  1 | data setting:  154 
#> Null:  | method setting:  1 | data setting:  155 
#> Null:  | method setting:  1 | data setting:  156 
#> Null:  | method setting:  1 | data setting:  157 
#> Null:  | method setting:  1 | data setting:  158 
#> Null:  | method setting:  1 | data setting:  159 
#> Null:  | method setting:  1 | data setting:  160 
#> Null:  | method setting:  1 | data setting:  161 
#> Null:  | method setting:  1 | data setting:  162 
#> Null:  | method setting:  1 | data setting:  163 
#> Null:  | method setting:  1 | data setting:  164 
#> Null:  | method setting:  1 | data setting:  165 
#> Null:  | method setting:  1 | data setting:  166 
#> Null:  | method setting:  1 | data setting:  167 
#> Null:  | method setting:  1 | data setting:  168 
#> Null:  | method setting:  1 | data setting:  169 
#> Null:  | method setting:  1 | data setting:  170 
#> Null:  | method setting:  1 | data setting:  171 
#> Null:  | method setting:  1 | data setting:  172 
#> Null:  | method setting:  1 | data setting:  173 
#> Null:  | method setting:  1 | data setting:  174 
#> Null:  | method setting:  1 | data setting:  175 
#> Null:  | method setting:  1 | data setting:  176 
#> Null:  | method setting:  1 | data setting:  177 
#> Null:  | method setting:  1 | data setting:  178 
#> Null:  | method setting:  1 | data setting:  179 
#> Null:  | method setting:  1 | data setting:  180 
#> Null:  | method setting:  1 | data setting:  181 
#> Null:  | method setting:  1 | data setting:  182 
#> Null:  | method setting:  1 | data setting:  183 
#> Null:  | method setting:  1 | data setting:  184 
#> Null:  | method setting:  1 | data setting:  185 
#> Null:  | method setting:  1 | data setting:  186 
#> Null:  | method setting:  1 | data setting:  187 
#> Null:  | method setting:  1 | data setting:  188 
#> Null:  | method setting:  1 | data setting:  189 
#> Null:  | method setting:  1 | data setting:  190 
#> Null:  | method setting:  1 | data setting:  191 
#> Null:  | method setting:  1 | data setting:  192 
#> Null:  | method setting:  1 | data setting:  193 
#> Null:  | method setting:  1 | data setting:  194 
#> Null:  | method setting:  1 | data setting:  195 
#> Null:  | method setting:  1 | data setting:  196 
#> Null:  | method setting:  1 | data setting:  197 
#> Null:  | method setting:  1 | data setting:  198 
#> Null:  | method setting:  1 | data setting:  199 
#> Null:  | method setting:  1 | data setting:  200 
#> Null:  | method setting:  1 | data setting:  201 
#> Null:  | method setting:  1 | data setting:  202 
#> Null:  | method setting:  1 | data setting:  203 
#> Null:  | method setting:  1 | data setting:  204 
#> Null:  | method setting:  1 | data setting:  205 
#> Null:  | method setting:  1 | data setting:  206 
#> Null:  | method setting:  1 | data setting:  207 
#> Null:  | method setting:  1 | data setting:  208 
#> Null:  | method setting:  1 | data setting:  209 
#> Null:  | method setting:  1 | data setting:  210 
#> Null:  | method setting:  1 | data setting:  211 
#> Null:  | method setting:  1 | data setting:  212 
#> Null:  | method setting:  1 | data setting:  213 
#> Null:  | method setting:  1 | data setting:  214 
#> Null:  | method setting:  1 | data setting:  215 
#> Null:  | method setting:  1 | data setting:  216 
#> Null:  | method setting:  1 | data setting:  217 
#> Null:  | method setting:  1 | data setting:  218 
#> Null:  | method setting:  1 | data setting:  219 
#> Null:  | method setting:  1 | data setting:  220 
#> Null:  | method setting:  1 | data setting:  221 
#> Null:  | method setting:  1 | data setting:  222 
#> Null:  | method setting:  1 | data setting:  223 
#> Null:  | method setting:  1 | data setting:  224 
#> Null:  | method setting:  1 | data setting:  225 
#> Null:  | method setting:  1 | data setting:  226 
#> Null:  | method setting:  1 | data setting:  227 
#> Null:  | method setting:  1 | data setting:  228 
#> Null:  | method setting:  1 | data setting:  229 
#> Null:  | method setting:  1 | data setting:  230 
#> Null:  | method setting:  1 | data setting:  231 
#> Null:  | method setting:  1 | data setting:  232 
#> Null:  | method setting:  1 | data setting:  233 
#> Null:  | method setting:  1 | data setting:  234 
#> Null:  | method setting:  1 | data setting:  235 
#> Null:  | method setting:  1 | data setting:  236 
#> Null:  | method setting:  1 | data setting:  237 
#> Null:  | method setting:  1 | data setting:  238 
#> Null:  | method setting:  1 | data setting:  239 
#> Null:  | method setting:  1 | data setting:  240 
#> Null:  | method setting:  1 | data setting:  241 
#> Null:  | method setting:  1 | data setting:  242 
#> Null:  | method setting:  1 | data setting:  243 
#> Null:  | method setting:  1 | data setting:  244 
#> Null:  | method setting:  1 | data setting:  245 
#> Null:  | method setting:  1 | data setting:  246 
#> Null:  | method setting:  1 | data setting:  247 
#> Null:  | method setting:  1 | data setting:  248 
#> Null:  | method setting:  1 | data setting:  249 
#> Null:  | method setting:  1 | data setting:  250 
#> Null:  | method setting:  1 | data setting:  251 
#> Null:  | method setting:  1 | data setting:  252 
#> Null:  | method setting:  1 | data setting:  253 
#> Null:  | method setting:  1 | data setting:  254 
#> Null:  | method setting:  1 | data setting:  255 
#> Null:  | method setting:  1 | data setting:  256 
#> Null:  | method setting:  1 | data setting:  257 
#> Null:  | method setting:  1 | data setting:  258 
#> Null:  | method setting:  1 | data setting:  259 
#> Null:  | method setting:  1 | data setting:  260 
#> Null:  | method setting:  1 | data setting:  261 
#> Null:  | method setting:  1 | data setting:  262 
#> Null:  | method setting:  1 | data setting:  263 
#> Null:  | method setting:  1 | data setting:  264 
#> Null:  | method setting:  1 | data setting:  265 
#> Null:  | method setting:  1 | data setting:  266 
#> Null:  | method setting:  1 | data setting:  267 
#> Null:  | method setting:  1 | data setting:  268 
#> Null:  | method setting:  1 | data setting:  269 
#> Null:  | method setting:  1 | data setting:  270 
#> Null:  | method setting:  1 | data setting:  271 
#> Null:  | method setting:  1 | data setting:  272 
#> Null:  | method setting:  1 | data setting:  273 
#> Null:  | method setting:  1 | data setting:  274 
#> Null:  | method setting:  1 | data setting:  275 
#> Null:  | method setting:  1 | data setting:  276 
#> Null:  | method setting:  1 | data setting:  277 
#> Null:  | method setting:  1 | data setting:  278 
#> Null:  | method setting:  1 | data setting:  279 
#> Null:  | method setting:  1 | data setting:  280 
#> Null:  | method setting:  1 | data setting:  281 
#> Null:  | method setting:  1 | data setting:  282 
#> Null:  | method setting:  1 | data setting:  283 
#> Null:  | method setting:  1 | data setting:  284 
#> Null:  | method setting:  1 | data setting:  285 
#> Null:  | method setting:  1 | data setting:  286 
#> Null:  | method setting:  1 | data setting:  287 
#> Null:  | method setting:  1 | data setting:  288 
#> Null:  | method setting:  1 | data setting:  289 
#> Null:  | method setting:  1 | data setting:  290 
#> Null:  | method setting:  1 | data setting:  291 
#> Null:  | method setting:  1 | data setting:  292 
#> Null:  | method setting:  1 | data setting:  293 
#> Null:  | method setting:  1 | data setting:  294 
#> Null:  | method setting:  1 | data setting:  295 
#> Null:  | method setting:  1 | data setting:  296 
#> Null:  | method setting:  1 | data setting:  297 
#> Null:  | method setting:  1 | data setting:  298 
#> Null:  | method setting:  1 | data setting:  299 
#> Null:  | method setting:  1 | data setting:  300 
#> Null:  | method setting:  1 | data setting:  301 
#> Null:  | method setting:  1 | data setting:  302 
#> Null:  | method setting:  1 | data setting:  303 
#> Null:  | method setting:  1 | data setting:  304 
#> Null:  | method setting:  1 | data setting:  305 
#> Null:  | method setting:  1 | data setting:  306 
#> Null:  | method setting:  1 | data setting:  307 
#> Null:  | method setting:  1 | data setting:  308 
#> Null:  | method setting:  1 | data setting:  309 
#> Null:  | method setting:  1 | data setting:  310 
#> Null:  | method setting:  1 | data setting:  311 
#> Null:  | method setting:  1 | data setting:  312 
#> Null:  | method setting:  1 | data setting:  313 
#> Null:  | method setting:  1 | data setting:  314 
#> Null:  | method setting:  1 | data setting:  315 
#> Null:  | method setting:  1 | data setting:  316 
#> Null:  | method setting:  1 | data setting:  317 
#> Null:  | method setting:  1 | data setting:  318 
#> Null:  | method setting:  1 | data setting:  319 
#> Null:  | method setting:  1 | data setting:  320 
#> Null:  | method setting:  1 | data setting:  321 
#> Null:  | method setting:  1 | data setting:  322 
#> Null:  | method setting:  1 | data setting:  323 
#> Null:  | method setting:  1 | data setting:  324 
#> Null:  | method setting:  1 | data setting:  325 
#> Null:  | method setting:  1 | data setting:  326 
#> Null:  | method setting:  1 | data setting:  327 
#> Null:  | method setting:  1 | data setting:  328 
#> Null:  | method setting:  1 | data setting:  329 
#> Null:  | method setting:  1 | data setting:  330 
#> Null:  | method setting:  1 | data setting:  331 
#> Null:  | method setting:  1 | data setting:  332 
#> Null:  | method setting:  1 | data setting:  333 
#> Null:  | method setting:  1 | data setting:  334 
#> Null:  | method setting:  1 | data setting:  335 
#> Null:  | method setting:  1 | data setting:  336 
#> Null:  | method setting:  1 | data setting:  337 
#> Null:  | method setting:  1 | data setting:  338 
#> Null:  | method setting:  1 | data setting:  339 
#> Null:  | method setting:  1 | data setting:  340 
#> Null:  | method setting:  1 | data setting:  341 
#> Null:  | method setting:  1 | data setting:  342 
#> Null:  | method setting:  1 | data setting:  343 
#> Null:  | method setting:  1 | data setting:  344 
#> Null:  | method setting:  1 | data setting:  345 
#> Null:  | method setting:  1 | data setting:  346 
#> Null:  | method setting:  1 | data setting:  347 
#> Null:  | method setting:  1 | data setting:  348 
#> Null:  | method setting:  1 | data setting:  349 
#> Null:  | method setting:  1 | data setting:  350 
#> Null:  | method setting:  1 | data setting:  351 
#> Null:  | method setting:  1 | data setting:  352 
#> Null:  | method setting:  1 | data setting:  353 
#> Null:  | method setting:  1 | data setting:  354 
#> Null:  | method setting:  1 | data setting:  355 
#> Null:  | method setting:  1 | data setting:  356 
#> Null:  | method setting:  1 | data setting:  357 
#> Null:  | method setting:  1 | data setting:  358 
#> Null:  | method setting:  1 | data setting:  359 
#> Null:  | method setting:  1 | data setting:  360 
#> Null:  | method setting:  1 | data setting:  361 
#> Null:  | method setting:  1 | data setting:  362 
#> Null:  | method setting:  1 | data setting:  363 
#> Null:  | method setting:  1 | data setting:  364 
#> Null:  | method setting:  1 | data setting:  365 
#> Null:  | method setting:  1 | data setting:  366 
#> Null:  | method setting:  1 | data setting:  367 
#> Null:  | method setting:  1 | data setting:  368 
#> Null:  | method setting:  1 | data setting:  369 
#> Null:  | method setting:  1 | data setting:  370 
#> Null:  | method setting:  1 | data setting:  371 
#> Null:  | method setting:  1 | data setting:  372 
#> Null:  | method setting:  1 | data setting:  373 
#> Null:  | method setting:  1 | data setting:  374 
#> Null:  | method setting:  1 | data setting:  375
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Null:  | method setting:  1 | data setting:  376 
#> Null:  | method setting:  1 | data setting:  377 
#> Null:  | method setting:  1 | data setting:  378 
#> Null:  | method setting:  1 | data setting:  379 
#> Null:  | method setting:  1 | data setting:  380 
#> Null:  | method setting:  1 | data setting:  381 
#> Null:  | method setting:  1 | data setting:  382 
#> Null:  | method setting:  1 | data setting:  383 
#> Null:  | method setting:  1 | data setting:  384 
#> Null:  | method setting:  1 | data setting:  385 
#> Null:  | method setting:  1 | data setting:  386 
#> Null:  | method setting:  1 | data setting:  387 
#> Null:  | method setting:  1 | data setting:  388 
#> Null:  | method setting:  1 | data setting:  389 
#> Null:  | method setting:  1 | data setting:  390 
#> Null:  | method setting:  1 | data setting:  391 
#> Null:  | method setting:  1 | data setting:  392 
#> Null:  | method setting:  1 | data setting:  393 
#> Null:  | method setting:  1 | data setting:  394 
#> Null:  | method setting:  1 | data setting:  395 
#> Null:  | method setting:  1 | data setting:  396 
#> Null:  | method setting:  1 | data setting:  397 
#> Null:  | method setting:  1 | data setting:  398 
#> Null:  | method setting:  1 | data setting:  399 
#> Null:  | method setting:  1 | data setting:  400 
#> Null:  | method setting:  1 | data setting:  401 
#> Null:  | method setting:  1 | data setting:  402 
#> Null:  | method setting:  1 | data setting:  403 
#> Null:  | method setting:  1 | data setting:  404 
#> Null:  | method setting:  1 | data setting:  405 
#> Null:  | method setting:  1 | data setting:  406 
#> Null:  | method setting:  1 | data setting:  407 
#> Null:  | method setting:  1 | data setting:  408 
#> Null:  | method setting:  1 | data setting:  409 
#> Null:  | method setting:  1 | data setting:  410 
#> Null:  | method setting:  1 | data setting:  411 
#> Null:  | method setting:  1 | data setting:  412 
#> Null:  | method setting:  1 | data setting:  413 
#> Null:  | method setting:  1 | data setting:  414 
#> Null:  | method setting:  1 | data setting:  415 
#> Null:  | method setting:  1 | data setting:  416 
#> Null:  | method setting:  1 | data setting:  417 
#> Null:  | method setting:  1 | data setting:  418 
#> Null:  | method setting:  1 | data setting:  419 
#> Null:  | method setting:  1 | data setting:  420 
#> Null:  | method setting:  1 | data setting:  421 
#> Null:  | method setting:  1 | data setting:  422 
#> Null:  | method setting:  1 | data setting:  423 
#> Null:  | method setting:  1 | data setting:  424 
#> Null:  | method setting:  1 | data setting:  425 
#> Null:  | method setting:  1 | data setting:  426 
#> Null:  | method setting:  1 | data setting:  427 
#> Null:  | method setting:  1 | data setting:  428 
#> Null:  | method setting:  1 | data setting:  429 
#> Null:  | method setting:  1 | data setting:  430 
#> Null:  | method setting:  1 | data setting:  431 
#> Null:  | method setting:  1 | data setting:  432 
#> Null:  | method setting:  1 | data setting:  433 
#> Null:  | method setting:  1 | data setting:  434 
#> Null:  | method setting:  1 | data setting:  435 
#> Null:  | method setting:  1 | data setting:  436 
#> Null:  | method setting:  1 | data setting:  437 
#> Null:  | method setting:  1 | data setting:  438 
#> Null:  | method setting:  1 | data setting:  439 
#> Null:  | method setting:  1 | data setting:  440 
#> Null:  | method setting:  1 | data setting:  441 
#> Null:  | method setting:  1 | data setting:  442 
#> Null:  | method setting:  1 | data setting:  443 
#> Null:  | method setting:  1 | data setting:  444 
#> Null:  | method setting:  1 | data setting:  445 
#> Null:  | method setting:  1 | data setting:  446 
#> Null:  | method setting:  1 | data setting:  447 
#> Null:  | method setting:  1 | data setting:  448 
#> Null:  | method setting:  1 | data setting:  449 
#> Null:  | method setting:  1 | data setting:  450 
#> Null:  | method setting:  1 | data setting:  451 
#> Null:  | method setting:  1 | data setting:  452 
#> Null:  | method setting:  1 | data setting:  453 
#> Null:  | method setting:  1 | data setting:  454 
#> Null:  | method setting:  1 | data setting:  455 
#> Null:  | method setting:  1 | data setting:  456 
#> Null:  | method setting:  1 | data setting:  457 
#> Null:  | method setting:  1 | data setting:  458 
#> Null:  | method setting:  1 | data setting:  459 
#> Null:  | method setting:  1 | data setting:  460 
#> Null:  | method setting:  1 | data setting:  461 
#> Null:  | method setting:  1 | data setting:  462 
#> Null:  | method setting:  1 | data setting:  463 
#> Null:  | method setting:  1 | data setting:  464 
#> Null:  | method setting:  1 | data setting:  465 
#> Null:  | method setting:  1 | data setting:  466 
#> Null:  | method setting:  1 | data setting:  467 
#> Null:  | method setting:  1 | data setting:  468 
#> Null:  | method setting:  1 | data setting:  469 
#> Null:  | method setting:  1 | data setting:  470 
#> Null:  | method setting:  1 | data setting:  471 
#> Null:  | method setting:  1 | data setting:  472 
#> Null:  | method setting:  1 | data setting:  473 
#> Null:  | method setting:  1 | data setting:  474 
#> Null:  | method setting:  1 | data setting:  475 
#> Null:  | method setting:  1 | data setting:  476 
#> Null:  | method setting:  1 | data setting:  477 
#> Null:  | method setting:  1 | data setting:  478 
#> Null:  | method setting:  1 | data setting:  479 
#> Null:  | method setting:  1 | data setting:  480 
#> Null:  | method setting:  1 | data setting:  481 
#> Null:  | method setting:  1 | data setting:  482 
#> Null:  | method setting:  1 | data setting:  483 
#> Null:  | method setting:  1 | data setting:  484 
#> Null:  | method setting:  1 | data setting:  485 
#> Null:  | method setting:  1 | data setting:  486 
#> Null:  | method setting:  1 | data setting:  487 
#> Null:  | method setting:  1 | data setting:  488 
#> Null:  | method setting:  1 | data setting:  489 
#> Null:  | method setting:  1 | data setting:  490 
#> Null:  | method setting:  1 | data setting:  491 
#> Null:  | method setting:  1 | data setting:  492 
#> Null:  | method setting:  1 | data setting:  493 
#> Null:  | method setting:  1 | data setting:  494 
#> Null:  | method setting:  1 | data setting:  495 
#> Null:  | method setting:  1 | data setting:  496 
#> Null:  | method setting:  1 | data setting:  497 
#> Null:  | method setting:  1 | data setting:  498 
#> Null:  | method setting:  1 | data setting:  499 
#> Null:  | method setting:  1 | data setting:  500 
#> Null:  | method setting:  2 | data setting:  1 
#> Null:  | method setting:  2 | data setting:  2 
#> Null:  | method setting:  2 | data setting:  3 
#> Null:  | method setting:  2 | data setting:  4 
#> Null:  | method setting:  2 | data setting:  5 
#> Null:  | method setting:  2 | data setting:  6 
#> Null:  | method setting:  2 | data setting:  7 
#> Null:  | method setting:  2 | data setting:  8 
#> Null:  | method setting:  2 | data setting:  9 
#> Null:  | method setting:  2 | data setting:  10 
#> Null:  | method setting:  2 | data setting:  11 
#> Null:  | method setting:  2 | data setting:  12 
#> Null:  | method setting:  2 | data setting:  13 
#> Null:  | method setting:  2 | data setting:  14 
#> Null:  | method setting:  2 | data setting:  15 
#> Null:  | method setting:  2 | data setting:  16 
#> Null:  | method setting:  2 | data setting:  17 
#> Null:  | method setting:  2 | data setting:  18 
#> Null:  | method setting:  2 | data setting:  19 
#> Null:  | method setting:  2 | data setting:  20 
#> Null:  | method setting:  2 | data setting:  21 
#> Null:  | method setting:  2 | data setting:  22 
#> Null:  | method setting:  2 | data setting:  23 
#> Null:  | method setting:  2 | data setting:  24 
#> Null:  | method setting:  2 | data setting:  25 
#> Null:  | method setting:  2 | data setting:  26 
#> Null:  | method setting:  2 | data setting:  27 
#> Null:  | method setting:  2 | data setting:  28 
#> Null:  | method setting:  2 | data setting:  29 
#> Null:  | method setting:  2 | data setting:  30 
#> Null:  | method setting:  2 | data setting:  31 
#> Null:  | method setting:  2 | data setting:  32 
#> Null:  | method setting:  2 | data setting:  33 
#> Null:  | method setting:  2 | data setting:  34 
#> Null:  | method setting:  2 | data setting:  35 
#> Null:  | method setting:  2 | data setting:  36 
#> Null:  | method setting:  2 | data setting:  37 
#> Null:  | method setting:  2 | data setting:  38 
#> Null:  | method setting:  2 | data setting:  39 
#> Null:  | method setting:  2 | data setting:  40 
#> Null:  | method setting:  2 | data setting:  41 
#> Null:  | method setting:  2 | data setting:  42 
#> Null:  | method setting:  2 | data setting:  43 
#> Null:  | method setting:  2 | data setting:  44 
#> Null:  | method setting:  2 | data setting:  45 
#> Null:  | method setting:  2 | data setting:  46 
#> Null:  | method setting:  2 | data setting:  47 
#> Null:  | method setting:  2 | data setting:  48 
#> Null:  | method setting:  2 | data setting:  49 
#> Null:  | method setting:  2 | data setting:  50 
#> Null:  | method setting:  2 | data setting:  51 
#> Null:  | method setting:  2 | data setting:  52 
#> Null:  | method setting:  2 | data setting:  53 
#> Null:  | method setting:  2 | data setting:  54 
#> Null:  | method setting:  2 | data setting:  55 
#> Null:  | method setting:  2 | data setting:  56 
#> Null:  | method setting:  2 | data setting:  57 
#> Null:  | method setting:  2 | data setting:  58 
#> Null:  | method setting:  2 | data setting:  59 
#> Null:  | method setting:  2 | data setting:  60 
#> Null:  | method setting:  2 | data setting:  61 
#> Null:  | method setting:  2 | data setting:  62 
#> Null:  | method setting:  2 | data setting:  63 
#> Null:  | method setting:  2 | data setting:  64 
#> Null:  | method setting:  2 | data setting:  65 
#> Null:  | method setting:  2 | data setting:  66 
#> Null:  | method setting:  2 | data setting:  67 
#> Null:  | method setting:  2 | data setting:  68 
#> Null:  | method setting:  2 | data setting:  69 
#> Null:  | method setting:  2 | data setting:  70 
#> Null:  | method setting:  2 | data setting:  71 
#> Null:  | method setting:  2 | data setting:  72 
#> Null:  | method setting:  2 | data setting:  73 
#> Null:  | method setting:  2 | data setting:  74 
#> Null:  | method setting:  2 | data setting:  75 
#> Null:  | method setting:  2 | data setting:  76 
#> Null:  | method setting:  2 | data setting:  77 
#> Null:  | method setting:  2 | data setting:  78 
#> Null:  | method setting:  2 | data setting:  79 
#> Null:  | method setting:  2 | data setting:  80 
#> Null:  | method setting:  2 | data setting:  81 
#> Null:  | method setting:  2 | data setting:  82 
#> Null:  | method setting:  2 | data setting:  83 
#> Null:  | method setting:  2 | data setting:  84 
#> Null:  | method setting:  2 | data setting:  85 
#> Null:  | method setting:  2 | data setting:  86 
#> Null:  | method setting:  2 | data setting:  87 
#> Null:  | method setting:  2 | data setting:  88 
#> Null:  | method setting:  2 | data setting:  89 
#> Null:  | method setting:  2 | data setting:  90 
#> Null:  | method setting:  2 | data setting:  91 
#> Null:  | method setting:  2 | data setting:  92 
#> Null:  | method setting:  2 | data setting:  93 
#> Null:  | method setting:  2 | data setting:  94 
#> Null:  | method setting:  2 | data setting:  95 
#> Null:  | method setting:  2 | data setting:  96 
#> Null:  | method setting:  2 | data setting:  97 
#> Null:  | method setting:  2 | data setting:  98 
#> Null:  | method setting:  2 | data setting:  99 
#> Null:  | method setting:  2 | data setting:  100 
#> Null:  | method setting:  2 | data setting:  101 
#> Null:  | method setting:  2 | data setting:  102 
#> Null:  | method setting:  2 | data setting:  103 
#> Null:  | method setting:  2 | data setting:  104 
#> Null:  | method setting:  2 | data setting:  105 
#> Null:  | method setting:  2 | data setting:  106 
#> Null:  | method setting:  2 | data setting:  107 
#> Null:  | method setting:  2 | data setting:  108 
#> Null:  | method setting:  2 | data setting:  109 
#> Null:  | method setting:  2 | data setting:  110 
#> Null:  | method setting:  2 | data setting:  111 
#> Null:  | method setting:  2 | data setting:  112 
#> Null:  | method setting:  2 | data setting:  113 
#> Null:  | method setting:  2 | data setting:  114 
#> Null:  | method setting:  2 | data setting:  115 
#> Null:  | method setting:  2 | data setting:  116 
#> Null:  | method setting:  2 | data setting:  117 
#> Null:  | method setting:  2 | data setting:  118 
#> Null:  | method setting:  2 | data setting:  119 
#> Null:  | method setting:  2 | data setting:  120 
#> Null:  | method setting:  2 | data setting:  121 
#> Null:  | method setting:  2 | data setting:  122 
#> Null:  | method setting:  2 | data setting:  123 
#> Null:  | method setting:  2 | data setting:  124 
#> Null:  | method setting:  2 | data setting:  125 
#> Null:  | method setting:  2 | data setting:  126 
#> Null:  | method setting:  2 | data setting:  127 
#> Null:  | method setting:  2 | data setting:  128 
#> Null:  | method setting:  2 | data setting:  129 
#> Null:  | method setting:  2 | data setting:  130 
#> Null:  | method setting:  2 | data setting:  131 
#> Null:  | method setting:  2 | data setting:  132 
#> Null:  | method setting:  2 | data setting:  133 
#> Null:  | method setting:  2 | data setting:  134 
#> Null:  | method setting:  2 | data setting:  135 
#> Null:  | method setting:  2 | data setting:  136 
#> Null:  | method setting:  2 | data setting:  137 
#> Null:  | method setting:  2 | data setting:  138 
#> Null:  | method setting:  2 | data setting:  139 
#> Null:  | method setting:  2 | data setting:  140 
#> Null:  | method setting:  2 | data setting:  141 
#> Null:  | method setting:  2 | data setting:  142 
#> Null:  | method setting:  2 | data setting:  143 
#> Null:  | method setting:  2 | data setting:  144 
#> Null:  | method setting:  2 | data setting:  145 
#> Null:  | method setting:  2 | data setting:  146 
#> Null:  | method setting:  2 | data setting:  147 
#> Null:  | method setting:  2 | data setting:  148 
#> Null:  | method setting:  2 | data setting:  149 
#> Null:  | method setting:  2 | data setting:  150 
#> Null:  | method setting:  2 | data setting:  151 
#> Null:  | method setting:  2 | data setting:  152 
#> Null:  | method setting:  2 | data setting:  153 
#> Null:  | method setting:  2 | data setting:  154 
#> Null:  | method setting:  2 | data setting:  155 
#> Null:  | method setting:  2 | data setting:  156 
#> Null:  | method setting:  2 | data setting:  157 
#> Null:  | method setting:  2 | data setting:  158 
#> Null:  | method setting:  2 | data setting:  159 
#> Null:  | method setting:  2 | data setting:  160 
#> Null:  | method setting:  2 | data setting:  161 
#> Null:  | method setting:  2 | data setting:  162 
#> Null:  | method setting:  2 | data setting:  163 
#> Null:  | method setting:  2 | data setting:  164 
#> Null:  | method setting:  2 | data setting:  165 
#> Null:  | method setting:  2 | data setting:  166 
#> Null:  | method setting:  2 | data setting:  167 
#> Null:  | method setting:  2 | data setting:  168 
#> Null:  | method setting:  2 | data setting:  169 
#> Null:  | method setting:  2 | data setting:  170 
#> Null:  | method setting:  2 | data setting:  171 
#> Null:  | method setting:  2 | data setting:  172 
#> Null:  | method setting:  2 | data setting:  173 
#> Null:  | method setting:  2 | data setting:  174 
#> Null:  | method setting:  2 | data setting:  175 
#> Null:  | method setting:  2 | data setting:  176 
#> Null:  | method setting:  2 | data setting:  177 
#> Null:  | method setting:  2 | data setting:  178 
#> Null:  | method setting:  2 | data setting:  179 
#> Null:  | method setting:  2 | data setting:  180 
#> Null:  | method setting:  2 | data setting:  181 
#> Null:  | method setting:  2 | data setting:  182 
#> Null:  | method setting:  2 | data setting:  183 
#> Null:  | method setting:  2 | data setting:  184 
#> Null:  | method setting:  2 | data setting:  185 
#> Null:  | method setting:  2 | data setting:  186 
#> Null:  | method setting:  2 | data setting:  187 
#> Null:  | method setting:  2 | data setting:  188 
#> Null:  | method setting:  2 | data setting:  189 
#> Null:  | method setting:  2 | data setting:  190 
#> Null:  | method setting:  2 | data setting:  191 
#> Null:  | method setting:  2 | data setting:  192 
#> Null:  | method setting:  2 | data setting:  193 
#> Null:  | method setting:  2 | data setting:  194 
#> Null:  | method setting:  2 | data setting:  195 
#> Null:  | method setting:  2 | data setting:  196 
#> Null:  | method setting:  2 | data setting:  197 
#> Null:  | method setting:  2 | data setting:  198 
#> Null:  | method setting:  2 | data setting:  199 
#> Null:  | method setting:  2 | data setting:  200 
#> Null:  | method setting:  2 | data setting:  201 
#> Null:  | method setting:  2 | data setting:  202 
#> Null:  | method setting:  2 | data setting:  203 
#> Null:  | method setting:  2 | data setting:  204 
#> Null:  | method setting:  2 | data setting:  205 
#> Null:  | method setting:  2 | data setting:  206 
#> Null:  | method setting:  2 | data setting:  207 
#> Null:  | method setting:  2 | data setting:  208 
#> Null:  | method setting:  2 | data setting:  209 
#> Null:  | method setting:  2 | data setting:  210 
#> Null:  | method setting:  2 | data setting:  211 
#> Null:  | method setting:  2 | data setting:  212 
#> Null:  | method setting:  2 | data setting:  213 
#> Null:  | method setting:  2 | data setting:  214 
#> Null:  | method setting:  2 | data setting:  215 
#> Null:  | method setting:  2 | data setting:  216 
#> Null:  | method setting:  2 | data setting:  217 
#> Null:  | method setting:  2 | data setting:  218 
#> Null:  | method setting:  2 | data setting:  219 
#> Null:  | method setting:  2 | data setting:  220 
#> Null:  | method setting:  2 | data setting:  221 
#> Null:  | method setting:  2 | data setting:  222 
#> Null:  | method setting:  2 | data setting:  223 
#> Null:  | method setting:  2 | data setting:  224 
#> Null:  | method setting:  2 | data setting:  225 
#> Null:  | method setting:  2 | data setting:  226 
#> Null:  | method setting:  2 | data setting:  227 
#> Null:  | method setting:  2 | data setting:  228 
#> Null:  | method setting:  2 | data setting:  229 
#> Null:  | method setting:  2 | data setting:  230 
#> Null:  | method setting:  2 | data setting:  231 
#> Null:  | method setting:  2 | data setting:  232 
#> Null:  | method setting:  2 | data setting:  233 
#> Null:  | method setting:  2 | data setting:  234 
#> Null:  | method setting:  2 | data setting:  235 
#> Null:  | method setting:  2 | data setting:  236 
#> Null:  | method setting:  2 | data setting:  237 
#> Null:  | method setting:  2 | data setting:  238 
#> Null:  | method setting:  2 | data setting:  239 
#> Null:  | method setting:  2 | data setting:  240 
#> Null:  | method setting:  2 | data setting:  241 
#> Null:  | method setting:  2 | data setting:  242 
#> Null:  | method setting:  2 | data setting:  243 
#> Null:  | method setting:  2 | data setting:  244 
#> Null:  | method setting:  2 | data setting:  245 
#> Null:  | method setting:  2 | data setting:  246 
#> Null:  | method setting:  2 | data setting:  247 
#> Null:  | method setting:  2 | data setting:  248 
#> Null:  | method setting:  2 | data setting:  249 
#> Null:  | method setting:  2 | data setting:  250 
#> Null:  | method setting:  2 | data setting:  251 
#> Null:  | method setting:  2 | data setting:  252 
#> Null:  | method setting:  2 | data setting:  253 
#> Null:  | method setting:  2 | data setting:  254 
#> Null:  | method setting:  2 | data setting:  255 
#> Null:  | method setting:  2 | data setting:  256 
#> Null:  | method setting:  2 | data setting:  257 
#> Null:  | method setting:  2 | data setting:  258 
#> Null:  | method setting:  2 | data setting:  259 
#> Null:  | method setting:  2 | data setting:  260 
#> Null:  | method setting:  2 | data setting:  261 
#> Null:  | method setting:  2 | data setting:  262 
#> Null:  | method setting:  2 | data setting:  263 
#> Null:  | method setting:  2 | data setting:  264 
#> Null:  | method setting:  2 | data setting:  265 
#> Null:  | method setting:  2 | data setting:  266 
#> Null:  | method setting:  2 | data setting:  267 
#> Null:  | method setting:  2 | data setting:  268 
#> Null:  | method setting:  2 | data setting:  269 
#> Null:  | method setting:  2 | data setting:  270 
#> Null:  | method setting:  2 | data setting:  271 
#> Null:  | method setting:  2 | data setting:  272 
#> Null:  | method setting:  2 | data setting:  273 
#> Null:  | method setting:  2 | data setting:  274 
#> Null:  | method setting:  2 | data setting:  275 
#> Null:  | method setting:  2 | data setting:  276 
#> Null:  | method setting:  2 | data setting:  277 
#> Null:  | method setting:  2 | data setting:  278 
#> Null:  | method setting:  2 | data setting:  279 
#> Null:  | method setting:  2 | data setting:  280 
#> Null:  | method setting:  2 | data setting:  281 
#> Null:  | method setting:  2 | data setting:  282 
#> Null:  | method setting:  2 | data setting:  283 
#> Null:  | method setting:  2 | data setting:  284 
#> Null:  | method setting:  2 | data setting:  285 
#> Null:  | method setting:  2 | data setting:  286 
#> Null:  | method setting:  2 | data setting:  287 
#> Null:  | method setting:  2 | data setting:  288 
#> Null:  | method setting:  2 | data setting:  289 
#> Null:  | method setting:  2 | data setting:  290 
#> Null:  | method setting:  2 | data setting:  291 
#> Null:  | method setting:  2 | data setting:  292 
#> Null:  | method setting:  2 | data setting:  293 
#> Null:  | method setting:  2 | data setting:  294 
#> Null:  | method setting:  2 | data setting:  295 
#> Null:  | method setting:  2 | data setting:  296 
#> Null:  | method setting:  2 | data setting:  297 
#> Null:  | method setting:  2 | data setting:  298 
#> Null:  | method setting:  2 | data setting:  299 
#> Null:  | method setting:  2 | data setting:  300 
#> Null:  | method setting:  2 | data setting:  301 
#> Null:  | method setting:  2 | data setting:  302 
#> Null:  | method setting:  2 | data setting:  303 
#> Null:  | method setting:  2 | data setting:  304 
#> Null:  | method setting:  2 | data setting:  305 
#> Null:  | method setting:  2 | data setting:  306 
#> Null:  | method setting:  2 | data setting:  307 
#> Null:  | method setting:  2 | data setting:  308 
#> Null:  | method setting:  2 | data setting:  309 
#> Null:  | method setting:  2 | data setting:  310 
#> Null:  | method setting:  2 | data setting:  311 
#> Null:  | method setting:  2 | data setting:  312 
#> Null:  | method setting:  2 | data setting:  313 
#> Null:  | method setting:  2 | data setting:  314 
#> Null:  | method setting:  2 | data setting:  315 
#> Null:  | method setting:  2 | data setting:  316 
#> Null:  | method setting:  2 | data setting:  317 
#> Null:  | method setting:  2 | data setting:  318 
#> Null:  | method setting:  2 | data setting:  319 
#> Null:  | method setting:  2 | data setting:  320 
#> Null:  | method setting:  2 | data setting:  321 
#> Null:  | method setting:  2 | data setting:  322 
#> Null:  | method setting:  2 | data setting:  323 
#> Null:  | method setting:  2 | data setting:  324 
#> Null:  | method setting:  2 | data setting:  325 
#> Null:  | method setting:  2 | data setting:  326 
#> Null:  | method setting:  2 | data setting:  327 
#> Null:  | method setting:  2 | data setting:  328 
#> Null:  | method setting:  2 | data setting:  329 
#> Null:  | method setting:  2 | data setting:  330 
#> Null:  | method setting:  2 | data setting:  331 
#> Null:  | method setting:  2 | data setting:  332 
#> Null:  | method setting:  2 | data setting:  333 
#> Null:  | method setting:  2 | data setting:  334 
#> Null:  | method setting:  2 | data setting:  335 
#> Null:  | method setting:  2 | data setting:  336 
#> Null:  | method setting:  2 | data setting:  337 
#> Null:  | method setting:  2 | data setting:  338 
#> Null:  | method setting:  2 | data setting:  339 
#> Null:  | method setting:  2 | data setting:  340 
#> Null:  | method setting:  2 | data setting:  341 
#> Null:  | method setting:  2 | data setting:  342 
#> Null:  | method setting:  2 | data setting:  343 
#> Null:  | method setting:  2 | data setting:  344 
#> Null:  | method setting:  2 | data setting:  345 
#> Null:  | method setting:  2 | data setting:  346 
#> Null:  | method setting:  2 | data setting:  347 
#> Null:  | method setting:  2 | data setting:  348 
#> Null:  | method setting:  2 | data setting:  349 
#> Null:  | method setting:  2 | data setting:  350 
#> Null:  | method setting:  2 | data setting:  351 
#> Null:  | method setting:  2 | data setting:  352 
#> Null:  | method setting:  2 | data setting:  353 
#> Null:  | method setting:  2 | data setting:  354 
#> Null:  | method setting:  2 | data setting:  355 
#> Null:  | method setting:  2 | data setting:  356 
#> Null:  | method setting:  2 | data setting:  357 
#> Null:  | method setting:  2 | data setting:  358 
#> Null:  | method setting:  2 | data setting:  359 
#> Null:  | method setting:  2 | data setting:  360 
#> Null:  | method setting:  2 | data setting:  361 
#> Null:  | method setting:  2 | data setting:  362 
#> Null:  | method setting:  2 | data setting:  363 
#> Null:  | method setting:  2 | data setting:  364 
#> Null:  | method setting:  2 | data setting:  365 
#> Null:  | method setting:  2 | data setting:  366 
#> Null:  | method setting:  2 | data setting:  367 
#> Null:  | method setting:  2 | data setting:  368 
#> Null:  | method setting:  2 | data setting:  369 
#> Null:  | method setting:  2 | data setting:  370 
#> Null:  | method setting:  2 | data setting:  371 
#> Null:  | method setting:  2 | data setting:  372 
#> Null:  | method setting:  2 | data setting:  373 
#> Null:  | method setting:  2 | data setting:  374 
#> Null:  | method setting:  2 | data setting:  375 
#> Null:  | method setting:  2 | data setting:  376 
#> Null:  | method setting:  2 | data setting:  377 
#> Null:  | method setting:  2 | data setting:  378 
#> Null:  | method setting:  2 | data setting:  379 
#> Null:  | method setting:  2 | data setting:  380 
#> Null:  | method setting:  2 | data setting:  381 
#> Null:  | method setting:  2 | data setting:  382 
#> Null:  | method setting:  2 | data setting:  383 
#> Null:  | method setting:  2 | data setting:  384 
#> Null:  | method setting:  2 | data setting:  385 
#> Null:  | method setting:  2 | data setting:  386 
#> Null:  | method setting:  2 | data setting:  387 
#> Null:  | method setting:  2 | data setting:  388 
#> Null:  | method setting:  2 | data setting:  389 
#> Null:  | method setting:  2 | data setting:  390 
#> Null:  | method setting:  2 | data setting:  391 
#> Null:  | method setting:  2 | data setting:  392 
#> Null:  | method setting:  2 | data setting:  393 
#> Null:  | method setting:  2 | data setting:  394 
#> Null:  | method setting:  2 | data setting:  395 
#> Null:  | method setting:  2 | data setting:  396 
#> Null:  | method setting:  2 | data setting:  397 
#> Null:  | method setting:  2 | data setting:  398 
#> Null:  | method setting:  2 | data setting:  399 
#> Null:  | method setting:  2 | data setting:  400 
#> Null:  | method setting:  2 | data setting:  401 
#> Null:  | method setting:  2 | data setting:  402 
#> Null:  | method setting:  2 | data setting:  403 
#> Null:  | method setting:  2 | data setting:  404 
#> Null:  | method setting:  2 | data setting:  405 
#> Null:  | method setting:  2 | data setting:  406 
#> Null:  | method setting:  2 | data setting:  407 
#> Null:  | method setting:  2 | data setting:  408 
#> Null:  | method setting:  2 | data setting:  409 
#> Null:  | method setting:  2 | data setting:  410 
#> Null:  | method setting:  2 | data setting:  411 
#> Null:  | method setting:  2 | data setting:  412 
#> Null:  | method setting:  2 | data setting:  413 
#> Null:  | method setting:  2 | data setting:  414 
#> Null:  | method setting:  2 | data setting:  415 
#> Null:  | method setting:  2 | data setting:  416 
#> Null:  | method setting:  2 | data setting:  417 
#> Null:  | method setting:  2 | data setting:  418 
#> Null:  | method setting:  2 | data setting:  419 
#> Null:  | method setting:  2 | data setting:  420 
#> Null:  | method setting:  2 | data setting:  421 
#> Null:  | method setting:  2 | data setting:  422 
#> Null:  | method setting:  2 | data setting:  423 
#> Null:  | method setting:  2 | data setting:  424 
#> Null:  | method setting:  2 | data setting:  425 
#> Null:  | method setting:  2 | data setting:  426 
#> Null:  | method setting:  2 | data setting:  427 
#> Null:  | method setting:  2 | data setting:  428 
#> Null:  | method setting:  2 | data setting:  429 
#> Null:  | method setting:  2 | data setting:  430 
#> Null:  | method setting:  2 | data setting:  431 
#> Null:  | method setting:  2 | data setting:  432 
#> Null:  | method setting:  2 | data setting:  433 
#> Null:  | method setting:  2 | data setting:  434 
#> Null:  | method setting:  2 | data setting:  435 
#> Null:  | method setting:  2 | data setting:  436 
#> Null:  | method setting:  2 | data setting:  437 
#> Null:  | method setting:  2 | data setting:  438 
#> Null:  | method setting:  2 | data setting:  439 
#> Null:  | method setting:  2 | data setting:  440 
#> Null:  | method setting:  2 | data setting:  441 
#> Null:  | method setting:  2 | data setting:  442 
#> Null:  | method setting:  2 | data setting:  443 
#> Null:  | method setting:  2 | data setting:  444 
#> Null:  | method setting:  2 | data setting:  445 
#> Null:  | method setting:  2 | data setting:  446 
#> Null:  | method setting:  2 | data setting:  447 
#> Null:  | method setting:  2 | data setting:  448 
#> Null:  | method setting:  2 | data setting:  449 
#> Null:  | method setting:  2 | data setting:  450 
#> Null:  | method setting:  2 | data setting:  451 
#> Null:  | method setting:  2 | data setting:  452 
#> Null:  | method setting:  2 | data setting:  453 
#> Null:  | method setting:  2 | data setting:  454 
#> Null:  | method setting:  2 | data setting:  455 
#> Null:  | method setting:  2 | data setting:  456 
#> Null:  | method setting:  2 | data setting:  457 
#> Null:  | method setting:  2 | data setting:  458 
#> Null:  | method setting:  2 | data setting:  459 
#> Null:  | method setting:  2 | data setting:  460 
#> Null:  | method setting:  2 | data setting:  461 
#> Null:  | method setting:  2 | data setting:  462 
#> Null:  | method setting:  2 | data setting:  463 
#> Null:  | method setting:  2 | data setting:  464 
#> Null:  | method setting:  2 | data setting:  465 
#> Null:  | method setting:  2 | data setting:  466 
#> Null:  | method setting:  2 | data setting:  467 
#> Null:  | method setting:  2 | data setting:  468 
#> Null:  | method setting:  2 | data setting:  469 
#> Null:  | method setting:  2 | data setting:  470 
#> Null:  | method setting:  2 | data setting:  471 
#> Null:  | method setting:  2 | data setting:  472 
#> Null:  | method setting:  2 | data setting:  473 
#> Null:  | method setting:  2 | data setting:  474 
#> Null:  | method setting:  2 | data setting:  475 
#> Null:  | method setting:  2 | data setting:  476 
#> Null:  | method setting:  2 | data setting:  477 
#> Null:  | method setting:  2 | data setting:  478 
#> Null:  | method setting:  2 | data setting:  479 
#> Null:  | method setting:  2 | data setting:  480 
#> Null:  | method setting:  2 | data setting:  481 
#> Null:  | method setting:  2 | data setting:  482 
#> Null:  | method setting:  2 | data setting:  483 
#> Null:  | method setting:  2 | data setting:  484 
#> Null:  | method setting:  2 | data setting:  485 
#> Null:  | method setting:  2 | data setting:  486 
#> Null:  | method setting:  2 | data setting:  487 
#> Null:  | method setting:  2 | data setting:  488 
#> Null:  | method setting:  2 | data setting:  489 
#> Null:  | method setting:  2 | data setting:  490 
#> Null:  | method setting:  2 | data setting:  491 
#> Null:  | method setting:  2 | data setting:  492 
#> Null:  | method setting:  2 | data setting:  493 
#> Null:  | method setting:  2 | data setting:  494 
#> Null:  | method setting:  2 | data setting:  495 
#> Null:  | method setting:  2 | data setting:  496 
#> Null:  | method setting:  2 | data setting:  497 
#> Null:  | method setting:  2 | data setting:  498 
#> Null:  | method setting:  2 | data setting:  499 
#> Null:  | method setting:  2 | data setting:  500 
#> Null:  | method setting:  3 | data setting:  1 
#> Null:  | method setting:  3 | data setting:  2 
#> Null:  | method setting:  3 | data setting:  3 
#> Null:  | method setting:  3 | data setting:  4 
#> Null:  | method setting:  3 | data setting:  5 
#> Null:  | method setting:  3 | data setting:  6 
#> Null:  | method setting:  3 | data setting:  7 
#> Null:  | method setting:  3 | data setting:  8 
#> Null:  | method setting:  3 | data setting:  9 
#> Null:  | method setting:  3 | data setting:  10 
#> Null:  | method setting:  3 | data setting:  11 
#> Null:  | method setting:  3 | data setting:  12 
#> Null:  | method setting:  3 | data setting:  13 
#> Null:  | method setting:  3 | data setting:  14 
#> Null:  | method setting:  3 | data setting:  15 
#> Null:  | method setting:  3 | data setting:  16 
#> Null:  | method setting:  3 | data setting:  17 
#> Null:  | method setting:  3 | data setting:  18 
#> Null:  | method setting:  3 | data setting:  19 
#> Null:  | method setting:  3 | data setting:  20 
#> Null:  | method setting:  3 | data setting:  21 
#> Null:  | method setting:  3 | data setting:  22 
#> Null:  | method setting:  3 | data setting:  23 
#> Null:  | method setting:  3 | data setting:  24 
#> Null:  | method setting:  3 | data setting:  25 
#> Null:  | method setting:  3 | data setting:  26 
#> Null:  | method setting:  3 | data setting:  27 
#> Null:  | method setting:  3 | data setting:  28 
#> Null:  | method setting:  3 | data setting:  29 
#> Null:  | method setting:  3 | data setting:  30 
#> Null:  | method setting:  3 | data setting:  31 
#> Null:  | method setting:  3 | data setting:  32 
#> Null:  | method setting:  3 | data setting:  33 
#> Null:  | method setting:  3 | data setting:  34 
#> Null:  | method setting:  3 | data setting:  35 
#> Null:  | method setting:  3 | data setting:  36 
#> Null:  | method setting:  3 | data setting:  37 
#> Null:  | method setting:  3 | data setting:  38 
#> Null:  | method setting:  3 | data setting:  39 
#> Null:  | method setting:  3 | data setting:  40 
#> Null:  | method setting:  3 | data setting:  41 
#> Null:  | method setting:  3 | data setting:  42 
#> Null:  | method setting:  3 | data setting:  43 
#> Null:  | method setting:  3 | data setting:  44 
#> Null:  | method setting:  3 | data setting:  45 
#> Null:  | method setting:  3 | data setting:  46 
#> Null:  | method setting:  3 | data setting:  47
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Null:  | method setting:  3 | data setting:  48 
#> Null:  | method setting:  3 | data setting:  49 
#> Null:  | method setting:  3 | data setting:  50 
#> Null:  | method setting:  3 | data setting:  51 
#> Null:  | method setting:  3 | data setting:  52 
#> Null:  | method setting:  3 | data setting:  53 
#> Null:  | method setting:  3 | data setting:  54 
#> Null:  | method setting:  3 | data setting:  55 
#> Null:  | method setting:  3 | data setting:  56 
#> Null:  | method setting:  3 | data setting:  57 
#> Null:  | method setting:  3 | data setting:  58 
#> Null:  | method setting:  3 | data setting:  59 
#> Null:  | method setting:  3 | data setting:  60 
#> Null:  | method setting:  3 | data setting:  61 
#> Null:  | method setting:  3 | data setting:  62 
#> Null:  | method setting:  3 | data setting:  63 
#> Null:  | method setting:  3 | data setting:  64 
#> Null:  | method setting:  3 | data setting:  65 
#> Null:  | method setting:  3 | data setting:  66 
#> Null:  | method setting:  3 | data setting:  67 
#> Null:  | method setting:  3 | data setting:  68 
#> Null:  | method setting:  3 | data setting:  69 
#> Null:  | method setting:  3 | data setting:  70 
#> Null:  | method setting:  3 | data setting:  71 
#> Null:  | method setting:  3 | data setting:  72 
#> Null:  | method setting:  3 | data setting:  73 
#> Null:  | method setting:  3 | data setting:  74 
#> Null:  | method setting:  3 | data setting:  75 
#> Null:  | method setting:  3 | data setting:  76 
#> Null:  | method setting:  3 | data setting:  77 
#> Null:  | method setting:  3 | data setting:  78 
#> Null:  | method setting:  3 | data setting:  79 
#> Null:  | method setting:  3 | data setting:  80 
#> Null:  | method setting:  3 | data setting:  81 
#> Null:  | method setting:  3 | data setting:  82 
#> Null:  | method setting:  3 | data setting:  83 
#> Null:  | method setting:  3 | data setting:  84 
#> Null:  | method setting:  3 | data setting:  85 
#> Null:  | method setting:  3 | data setting:  86 
#> Null:  | method setting:  3 | data setting:  87 
#> Null:  | method setting:  3 | data setting:  88 
#> Null:  | method setting:  3 | data setting:  89 
#> Null:  | method setting:  3 | data setting:  90 
#> Null:  | method setting:  3 | data setting:  91 
#> Null:  | method setting:  3 | data setting:  92 
#> Null:  | method setting:  3 | data setting:  93 
#> Null:  | method setting:  3 | data setting:  94 
#> Null:  | method setting:  3 | data setting:  95 
#> Null:  | method setting:  3 | data setting:  96 
#> Null:  | method setting:  3 | data setting:  97 
#> Null:  | method setting:  3 | data setting:  98 
#> Null:  | method setting:  3 | data setting:  99 
#> Null:  | method setting:  3 | data setting:  100 
#> Null:  | method setting:  3 | data setting:  101
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Null:  | method setting:  3 | data setting:  102 
#> Null:  | method setting:  3 | data setting:  103 
#> Null:  | method setting:  3 | data setting:  104 
#> Null:  | method setting:  3 | data setting:  105 
#> Null:  | method setting:  3 | data setting:  106 
#> Null:  | method setting:  3 | data setting:  107 
#> Null:  | method setting:  3 | data setting:  108 
#> Null:  | method setting:  3 | data setting:  109 
#> Null:  | method setting:  3 | data setting:  110 
#> Null:  | method setting:  3 | data setting:  111 
#> Null:  | method setting:  3 | data setting:  112 
#> Null:  | method setting:  3 | data setting:  113 
#> Null:  | method setting:  3 | data setting:  114 
#> Null:  | method setting:  3 | data setting:  115 
#> Null:  | method setting:  3 | data setting:  116 
#> Null:  | method setting:  3 | data setting:  117 
#> Null:  | method setting:  3 | data setting:  118 
#> Null:  | method setting:  3 | data setting:  119 
#> Null:  | method setting:  3 | data setting:  120 
#> Null:  | method setting:  3 | data setting:  121 
#> Null:  | method setting:  3 | data setting:  122 
#> Null:  | method setting:  3 | data setting:  123 
#> Null:  | method setting:  3 | data setting:  124 
#> Null:  | method setting:  3 | data setting:  125 
#> Null:  | method setting:  3 | data setting:  126 
#> Null:  | method setting:  3 | data setting:  127 
#> Null:  | method setting:  3 | data setting:  128 
#> Null:  | method setting:  3 | data setting:  129 
#> Null:  | method setting:  3 | data setting:  130 
#> Null:  | method setting:  3 | data setting:  131 
#> Null:  | method setting:  3 | data setting:  132 
#> Null:  | method setting:  3 | data setting:  133 
#> Null:  | method setting:  3 | data setting:  134 
#> Null:  | method setting:  3 | data setting:  135 
#> Null:  | method setting:  3 | data setting:  136 
#> Null:  | method setting:  3 | data setting:  137 
#> Null:  | method setting:  3 | data setting:  138 
#> Null:  | method setting:  3 | data setting:  139 
#> Null:  | method setting:  3 | data setting:  140 
#> Null:  | method setting:  3 | data setting:  141 
#> Null:  | method setting:  3 | data setting:  142 
#> Null:  | method setting:  3 | data setting:  143 
#> Null:  | method setting:  3 | data setting:  144 
#> Null:  | method setting:  3 | data setting:  145 
#> Null:  | method setting:  3 | data setting:  146 
#> Null:  | method setting:  3 | data setting:  147 
#> Null:  | method setting:  3 | data setting:  148 
#> Null:  | method setting:  3 | data setting:  149 
#> Null:  | method setting:  3 | data setting:  150 
#> Null:  | method setting:  3 | data setting:  151 
#> Null:  | method setting:  3 | data setting:  152 
#> Null:  | method setting:  3 | data setting:  153 
#> Null:  | method setting:  3 | data setting:  154 
#> Null:  | method setting:  3 | data setting:  155 
#> Null:  | method setting:  3 | data setting:  156 
#> Null:  | method setting:  3 | data setting:  157 
#> Null:  | method setting:  3 | data setting:  158 
#> Null:  | method setting:  3 | data setting:  159 
#> Null:  | method setting:  3 | data setting:  160 
#> Null:  | method setting:  3 | data setting:  161 
#> Null:  | method setting:  3 | data setting:  162 
#> Null:  | method setting:  3 | data setting:  163 
#> Null:  | method setting:  3 | data setting:  164 
#> Null:  | method setting:  3 | data setting:  165 
#> Null:  | method setting:  3 | data setting:  166 
#> Null:  | method setting:  3 | data setting:  167 
#> Null:  | method setting:  3 | data setting:  168 
#> Null:  | method setting:  3 | data setting:  169 
#> Null:  | method setting:  3 | data setting:  170 
#> Null:  | method setting:  3 | data setting:  171 
#> Null:  | method setting:  3 | data setting:  172 
#> Null:  | method setting:  3 | data setting:  173 
#> Null:  | method setting:  3 | data setting:  174 
#> Null:  | method setting:  3 | data setting:  175 
#> Null:  | method setting:  3 | data setting:  176 
#> Null:  | method setting:  3 | data setting:  177 
#> Null:  | method setting:  3 | data setting:  178
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Null:  | method setting:  3 | data setting:  179 
#> Null:  | method setting:  3 | data setting:  180 
#> Null:  | method setting:  3 | data setting:  181 
#> Null:  | method setting:  3 | data setting:  182 
#> Null:  | method setting:  3 | data setting:  183 
#> Null:  | method setting:  3 | data setting:  184 
#> Null:  | method setting:  3 | data setting:  185 
#> Null:  | method setting:  3 | data setting:  186 
#> Null:  | method setting:  3 | data setting:  187 
#> Null:  | method setting:  3 | data setting:  188 
#> Null:  | method setting:  3 | data setting:  189 
#> Null:  | method setting:  3 | data setting:  190 
#> Null:  | method setting:  3 | data setting:  191 
#> Null:  | method setting:  3 | data setting:  192 
#> Null:  | method setting:  3 | data setting:  193 
#> Null:  | method setting:  3 | data setting:  194 
#> Null:  | method setting:  3 | data setting:  195 
#> Null:  | method setting:  3 | data setting:  196 
#> Null:  | method setting:  3 | data setting:  197 
#> Null:  | method setting:  3 | data setting:  198 
#> Null:  | method setting:  3 | data setting:  199 
#> Null:  | method setting:  3 | data setting:  200 
#> Null:  | method setting:  3 | data setting:  201 
#> Null:  | method setting:  3 | data setting:  202 
#> Null:  | method setting:  3 | data setting:  203 
#> Null:  | method setting:  3 | data setting:  204 
#> Null:  | method setting:  3 | data setting:  205 
#> Null:  | method setting:  3 | data setting:  206 
#> Null:  | method setting:  3 | data setting:  207 
#> Null:  | method setting:  3 | data setting:  208
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Null:  | method setting:  3 | data setting:  209 
#> Null:  | method setting:  3 | data setting:  210 
#> Null:  | method setting:  3 | data setting:  211 
#> Null:  | method setting:  3 | data setting:  212 
#> Null:  | method setting:  3 | data setting:  213 
#> Null:  | method setting:  3 | data setting:  214 
#> Null:  | method setting:  3 | data setting:  215 
#> Null:  | method setting:  3 | data setting:  216 
#> Null:  | method setting:  3 | data setting:  217 
#> Null:  | method setting:  3 | data setting:  218 
#> Null:  | method setting:  3 | data setting:  219 
#> Null:  | method setting:  3 | data setting:  220 
#> Null:  | method setting:  3 | data setting:  221 
#> Null:  | method setting:  3 | data setting:  222 
#> Null:  | method setting:  3 | data setting:  223 
#> Null:  | method setting:  3 | data setting:  224 
#> Null:  | method setting:  3 | data setting:  225 
#> Null:  | method setting:  3 | data setting:  226 
#> Null:  | method setting:  3 | data setting:  227 
#> Null:  | method setting:  3 | data setting:  228 
#> Null:  | method setting:  3 | data setting:  229 
#> Null:  | method setting:  3 | data setting:  230 
#> Null:  | method setting:  3 | data setting:  231 
#> Null:  | method setting:  3 | data setting:  232 
#> Null:  | method setting:  3 | data setting:  233 
#> Null:  | method setting:  3 | data setting:  234 
#> Null:  | method setting:  3 | data setting:  235 
#> Null:  | method setting:  3 | data setting:  236 
#> Null:  | method setting:  3 | data setting:  237 
#> Null:  | method setting:  3 | data setting:  238 
#> Null:  | method setting:  3 | data setting:  239 
#> Null:  | method setting:  3 | data setting:  240 
#> Null:  | method setting:  3 | data setting:  241 
#> Null:  | method setting:  3 | data setting:  242 
#> Null:  | method setting:  3 | data setting:  243 
#> Null:  | method setting:  3 | data setting:  244 
#> Null:  | method setting:  3 | data setting:  245 
#> Null:  | method setting:  3 | data setting:  246 
#> Null:  | method setting:  3 | data setting:  247 
#> Null:  | method setting:  3 | data setting:  248 
#> Null:  | method setting:  3 | data setting:  249 
#> Null:  | method setting:  3 | data setting:  250
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Null:  | method setting:  3 | data setting:  251 
#> Null:  | method setting:  3 | data setting:  252 
#> Null:  | method setting:  3 | data setting:  253 
#> Null:  | method setting:  3 | data setting:  254 
#> Null:  | method setting:  3 | data setting:  255 
#> Null:  | method setting:  3 | data setting:  256 
#> Null:  | method setting:  3 | data setting:  257 
#> Null:  | method setting:  3 | data setting:  258 
#> Null:  | method setting:  3 | data setting:  259 
#> Null:  | method setting:  3 | data setting:  260 
#> Null:  | method setting:  3 | data setting:  261 
#> Null:  | method setting:  3 | data setting:  262 
#> Null:  | method setting:  3 | data setting:  263 
#> Null:  | method setting:  3 | data setting:  264 
#> Null:  | method setting:  3 | data setting:  265 
#> Null:  | method setting:  3 | data setting:  266 
#> Null:  | method setting:  3 | data setting:  267 
#> Null:  | method setting:  3 | data setting:  268 
#> Null:  | method setting:  3 | data setting:  269 
#> Null:  | method setting:  3 | data setting:  270 
#> Null:  | method setting:  3 | data setting:  271 
#> Null:  | method setting:  3 | data setting:  272 
#> Null:  | method setting:  3 | data setting:  273 
#> Null:  | method setting:  3 | data setting:  274 
#> Null:  | method setting:  3 | data setting:  275 
#> Null:  | method setting:  3 | data setting:  276 
#> Null:  | method setting:  3 | data setting:  277 
#> Null:  | method setting:  3 | data setting:  278 
#> Null:  | method setting:  3 | data setting:  279 
#> Null:  | method setting:  3 | data setting:  280 
#> Null:  | method setting:  3 | data setting:  281 
#> Null:  | method setting:  3 | data setting:  282 
#> Null:  | method setting:  3 | data setting:  283 
#> Null:  | method setting:  3 | data setting:  284 
#> Null:  | method setting:  3 | data setting:  285 
#> Null:  | method setting:  3 | data setting:  286 
#> Null:  | method setting:  3 | data setting:  287 
#> Null:  | method setting:  3 | data setting:  288 
#> Null:  | method setting:  3 | data setting:  289 
#> Null:  | method setting:  3 | data setting:  290 
#> Null:  | method setting:  3 | data setting:  291 
#> Null:  | method setting:  3 | data setting:  292 
#> Null:  | method setting:  3 | data setting:  293 
#> Null:  | method setting:  3 | data setting:  294 
#> Null:  | method setting:  3 | data setting:  295 
#> Null:  | method setting:  3 | data setting:  296 
#> Null:  | method setting:  3 | data setting:  297 
#> Null:  | method setting:  3 | data setting:  298 
#> Null:  | method setting:  3 | data setting:  299 
#> Null:  | method setting:  3 | data setting:  300 
#> Null:  | method setting:  3 | data setting:  301 
#> Null:  | method setting:  3 | data setting:  302 
#> Null:  | method setting:  3 | data setting:  303 
#> Null:  | method setting:  3 | data setting:  304 
#> Null:  | method setting:  3 | data setting:  305 
#> Null:  | method setting:  3 | data setting:  306 
#> Null:  | method setting:  3 | data setting:  307 
#> Null:  | method setting:  3 | data setting:  308 
#> Null:  | method setting:  3 | data setting:  309 
#> Null:  | method setting:  3 | data setting:  310 
#> Null:  | method setting:  3 | data setting:  311 
#> Null:  | method setting:  3 | data setting:  312 
#> Null:  | method setting:  3 | data setting:  313 
#> Null:  | method setting:  3 | data setting:  314 
#> Null:  | method setting:  3 | data setting:  315 
#> Null:  | method setting:  3 | data setting:  316 
#> Null:  | method setting:  3 | data setting:  317 
#> Null:  | method setting:  3 | data setting:  318 
#> Null:  | method setting:  3 | data setting:  319 
#> Null:  | method setting:  3 | data setting:  320 
#> Null:  | method setting:  3 | data setting:  321 
#> Null:  | method setting:  3 | data setting:  322 
#> Null:  | method setting:  3 | data setting:  323 
#> Null:  | method setting:  3 | data setting:  324 
#> Null:  | method setting:  3 | data setting:  325 
#> Null:  | method setting:  3 | data setting:  326 
#> Null:  | method setting:  3 | data setting:  327 
#> Null:  | method setting:  3 | data setting:  328 
#> Null:  | method setting:  3 | data setting:  329 
#> Null:  | method setting:  3 | data setting:  330 
#> Null:  | method setting:  3 | data setting:  331 
#> Null:  | method setting:  3 | data setting:  332 
#> Null:  | method setting:  3 | data setting:  333 
#> Null:  | method setting:  3 | data setting:  334 
#> Null:  | method setting:  3 | data setting:  335 
#> Null:  | method setting:  3 | data setting:  336 
#> Null:  | method setting:  3 | data setting:  337 
#> Null:  | method setting:  3 | data setting:  338 
#> Null:  | method setting:  3 | data setting:  339 
#> Null:  | method setting:  3 | data setting:  340 
#> Null:  | method setting:  3 | data setting:  341 
#> Null:  | method setting:  3 | data setting:  342 
#> Null:  | method setting:  3 | data setting:  343 
#> Null:  | method setting:  3 | data setting:  344 
#> Null:  | method setting:  3 | data setting:  345 
#> Null:  | method setting:  3 | data setting:  346 
#> Null:  | method setting:  3 | data setting:  347 
#> Null:  | method setting:  3 | data setting:  348 
#> Null:  | method setting:  3 | data setting:  349 
#> Null:  | method setting:  3 | data setting:  350 
#> Null:  | method setting:  3 | data setting:  351 
#> Null:  | method setting:  3 | data setting:  352 
#> Null:  | method setting:  3 | data setting:  353 
#> Null:  | method setting:  3 | data setting:  354 
#> Null:  | method setting:  3 | data setting:  355 
#> Null:  | method setting:  3 | data setting:  356 
#> Null:  | method setting:  3 | data setting:  357 
#> Null:  | method setting:  3 | data setting:  358 
#> Null:  | method setting:  3 | data setting:  359 
#> Null:  | method setting:  3 | data setting:  360 
#> Null:  | method setting:  3 | data setting:  361 
#> Null:  | method setting:  3 | data setting:  362 
#> Null:  | method setting:  3 | data setting:  363 
#> Null:  | method setting:  3 | data setting:  364 
#> Null:  | method setting:  3 | data setting:  365 
#> Null:  | method setting:  3 | data setting:  366 
#> Null:  | method setting:  3 | data setting:  367 
#> Null:  | method setting:  3 | data setting:  368 
#> Null:  | method setting:  3 | data setting:  369 
#> Null:  | method setting:  3 | data setting:  370 
#> Null:  | method setting:  3 | data setting:  371 
#> Null:  | method setting:  3 | data setting:  372 
#> Null:  | method setting:  3 | data setting:  373 
#> Null:  | method setting:  3 | data setting:  374 
#> Null:  | method setting:  3 | data setting:  375 
#> Null:  | method setting:  3 | data setting:  376 
#> Null:  | method setting:  3 | data setting:  377 
#> Null:  | method setting:  3 | data setting:  378 
#> Null:  | method setting:  3 | data setting:  379 
#> Null:  | method setting:  3 | data setting:  380 
#> Null:  | method setting:  3 | data setting:  381 
#> Null:  | method setting:  3 | data setting:  382 
#> Null:  | method setting:  3 | data setting:  383 
#> Null:  | method setting:  3 | data setting:  384 
#> Null:  | method setting:  3 | data setting:  385 
#> Null:  | method setting:  3 | data setting:  386 
#> Null:  | method setting:  3 | data setting:  387 
#> Null:  | method setting:  3 | data setting:  388 
#> Null:  | method setting:  3 | data setting:  389 
#> Null:  | method setting:  3 | data setting:  390 
#> Null:  | method setting:  3 | data setting:  391 
#> Null:  | method setting:  3 | data setting:  392 
#> Null:  | method setting:  3 | data setting:  393 
#> Null:  | method setting:  3 | data setting:  394 
#> Null:  | method setting:  3 | data setting:  395 
#> Null:  | method setting:  3 | data setting:  396 
#> Null:  | method setting:  3 | data setting:  397 
#> Null:  | method setting:  3 | data setting:  398 
#> Null:  | method setting:  3 | data setting:  399 
#> Null:  | method setting:  3 | data setting:  400 
#> Null:  | method setting:  3 | data setting:  401 
#> Null:  | method setting:  3 | data setting:  402 
#> Null:  | method setting:  3 | data setting:  403 
#> Null:  | method setting:  3 | data setting:  404 
#> Null:  | method setting:  3 | data setting:  405 
#> Null:  | method setting:  3 | data setting:  406 
#> Null:  | method setting:  3 | data setting:  407 
#> Null:  | method setting:  3 | data setting:  408 
#> Null:  | method setting:  3 | data setting:  409 
#> Null:  | method setting:  3 | data setting:  410 
#> Null:  | method setting:  3 | data setting:  411 
#> Null:  | method setting:  3 | data setting:  412 
#> Null:  | method setting:  3 | data setting:  413 
#> Null:  | method setting:  3 | data setting:  414 
#> Null:  | method setting:  3 | data setting:  415 
#> Null:  | method setting:  3 | data setting:  416 
#> Null:  | method setting:  3 | data setting:  417 
#> Null:  | method setting:  3 | data setting:  418 
#> Null:  | method setting:  3 | data setting:  419 
#> Null:  | method setting:  3 | data setting:  420 
#> Null:  | method setting:  3 | data setting:  421 
#> Null:  | method setting:  3 | data setting:  422 
#> Null:  | method setting:  3 | data setting:  423 
#> Null:  | method setting:  3 | data setting:  424 
#> Null:  | method setting:  3 | data setting:  425 
#> Null:  | method setting:  3 | data setting:  426 
#> Null:  | method setting:  3 | data setting:  427 
#> Null:  | method setting:  3 | data setting:  428 
#> Null:  | method setting:  3 | data setting:  429 
#> Null:  | method setting:  3 | data setting:  430 
#> Null:  | method setting:  3 | data setting:  431 
#> Null:  | method setting:  3 | data setting:  432 
#> Null:  | method setting:  3 | data setting:  433 
#> Null:  | method setting:  3 | data setting:  434 
#> Null:  | method setting:  3 | data setting:  435 
#> Null:  | method setting:  3 | data setting:  436 
#> Null:  | method setting:  3 | data setting:  437 
#> Null:  | method setting:  3 | data setting:  438 
#> Null:  | method setting:  3 | data setting:  439 
#> Null:  | method setting:  3 | data setting:  440 
#> Null:  | method setting:  3 | data setting:  441 
#> Null:  | method setting:  3 | data setting:  442 
#> Null:  | method setting:  3 | data setting:  443 
#> Null:  | method setting:  3 | data setting:  444 
#> Null:  | method setting:  3 | data setting:  445 
#> Null:  | method setting:  3 | data setting:  446 
#> Null:  | method setting:  3 | data setting:  447 
#> Null:  | method setting:  3 | data setting:  448 
#> Null:  | method setting:  3 | data setting:  449 
#> Null:  | method setting:  3 | data setting:  450 
#> Null:  | method setting:  3 | data setting:  451 
#> Null:  | method setting:  3 | data setting:  452 
#> Null:  | method setting:  3 | data setting:  453 
#> Null:  | method setting:  3 | data setting:  454 
#> Null:  | method setting:  3 | data setting:  455 
#> Null:  | method setting:  3 | data setting:  456 
#> Null:  | method setting:  3 | data setting:  457 
#> Null:  | method setting:  3 | data setting:  458 
#> Null:  | method setting:  3 | data setting:  459 
#> Null:  | method setting:  3 | data setting:  460 
#> Null:  | method setting:  3 | data setting:  461 
#> Null:  | method setting:  3 | data setting:  462 
#> Null:  | method setting:  3 | data setting:  463 
#> Null:  | method setting:  3 | data setting:  464 
#> Null:  | method setting:  3 | data setting:  465 
#> Null:  | method setting:  3 | data setting:  466 
#> Null:  | method setting:  3 | data setting:  467 
#> Null:  | method setting:  3 | data setting:  468 
#> Null:  | method setting:  3 | data setting:  469 
#> Null:  | method setting:  3 | data setting:  470 
#> Null:  | method setting:  3 | data setting:  471 
#> Null:  | method setting:  3 | data setting:  472 
#> Null:  | method setting:  3 | data setting:  473 
#> Null:  | method setting:  3 | data setting:  474 
#> Null:  | method setting:  3 | data setting:  475 
#> Null:  | method setting:  3 | data setting:  476 
#> Null:  | method setting:  3 | data setting:  477 
#> Null:  | method setting:  3 | data setting:  478
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Null:  | method setting:  3 | data setting:  479 
#> Null:  | method setting:  3 | data setting:  480 
#> Null:  | method setting:  3 | data setting:  481 
#> Null:  | method setting:  3 | data setting:  482 
#> Null:  | method setting:  3 | data setting:  483 
#> Null:  | method setting:  3 | data setting:  484 
#> Null:  | method setting:  3 | data setting:  485 
#> Null:  | method setting:  3 | data setting:  486 
#> Null:  | method setting:  3 | data setting:  487 
#> Null:  | method setting:  3 | data setting:  488 
#> Null:  | method setting:  3 | data setting:  489 
#> Null:  | method setting:  3 | data setting:  490 
#> Null:  | method setting:  3 | data setting:  491 
#> Null:  | method setting:  3 | data setting:  492 
#> Null:  | method setting:  3 | data setting:  493 
#> Null:  | method setting:  3 | data setting:  494 
#> Null:  | method setting:  3 | data setting:  495 
#> Null:  | method setting:  3 | data setting:  496 
#> Null:  | method setting:  3 | data setting:  497 
#> Null:  | method setting:  3 | data setting:  498
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning in predict.lm(model_list_rct[[x]], newdata = filter(df, S == 1)):
#> prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Null:  | method setting:  3 | data setting:  499 
#> Null:  | method setting:  3 | data setting:  500
```

``` r

simulation_report # Type I error and Power
#>   method_description         bias variance      mse coverage type_I_error
#> 1           IPW, DID -0.282537033 3.187900 3.267727    0.942        0.058
#> 2          AIPW, DID  0.001684041 3.328328 3.328331    0.942        0.058
#> 3            OR, DID  0.035746079 1.459605 1.460883    0.960        0.040
# simulation hypo test
```

The above code generates a report for the simulation results.

## References

- Zhou X, Pang H, Drake C, Burger HU, Zhu J (2024). “Estimating
  treatment effect in randomized trial after control to treatment
  crossover using external controls.” *Journal of Biopharmaceutical
  Statistics*. doi:
  [10.1080/10543406.2024.2444222](https://doi.org/10.1080/10543406.2024.2444222).
- Shi L, Pang H, Chen C, Zhu J (2025). “rdborrow: an R package for
  causal inference incorporating external controls in randomized
  controlled trials with longitudinal outcomes.” *Journal of
  Biopharmaceutical Statistics*, 35(6), 1043-1066. doi:
  [10.1080/10543406.2025.2489283](https://doi.org/10.1080/10543406.2025.2489283).
