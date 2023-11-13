################################################################################
##
## [ PROJ ] A Gentle Introduction to Bayesian Analysis with Applications
##           to QuantCrit | ASHE Workshop
## [ FILE ] analysis.R 
## [ INIT ] 18 November 2023
## [ AUTH ] Alberto Guzman-Alvarez, Taylor Burtch, Benjamin Skinner
##
################################################################################

## ---------------------------
## libraries
## ---------------------------

libs <- c("tidyverse", "brms", "haven", "bayesplot")
sapply(libs, require, character.only = TRUE)

## ---------------------------
## settings
## ---------------------------

## set number of cores to use to speed things up
options(mc.cores=parallel::detectCores())

## set a seed so things stay the same
my_seed <- 20231118




## ## ---------------------------
## ## input
## ## ---------------------------
## 
## ## using Stata version of data so we have labels; need haven::read_dta()
## df <- read_dta("hsls_small.dta")

## ---------------------------
## show data set
## ---------------------------

df

## ---------------------------
## simple regression
## ---------------------------

## likelihood of going to college
fit <- brm(x4evratndclg ~ 1,
           data = df |> zap_labels(),
           family = bernoulli("logit"),
           seed = my_seed)


## show summary stats
summary(fit)
## show distribution of intercept (our main parameter)
mcmc_areas(fit, prob = 0.95, pars = "b_Intercept") +
  labs(
    title = "Posterior distribution",
    subtitle = "with median and 95% interval"
  )

## show trace of chains for intercept (our main parameter)
color_scheme_set("mix-blue-pink")
mcmc_trace(fit |> as_draws(inc_warmup = TRUE),
           pars = "b_Intercept", n_warmup = 1000,
           window = c(0, 50)) +
  labs(
    title = "Trace of posterior chains",
    subtitle = "Draws: 0 to 50"
  )

## show trace of chains for intercept (our main parameter)
color_scheme_set("mix-blue-pink")
mcmc_trace(fit |> as_draws(inc_warmup = TRUE),
           pars = "b_Intercept", n_warmup = 1000,
           window = c(500, 2000)) +
  labs(
    title = "Trace of posterior chains",
    subtitle = "Draws: 500 to 2000"
  )

## convert to posterior prediction
ppc_dens_overlay(y = fit$y,
                 yrep = posterior_predict(fit, draws = 50))

## -----------------------------------------------------------------------------
## end script
## -----------------------------------------------------------------------------
