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

libs <- c("tidyverse", "brms", "bayesplot", "tidybayes", "patchwork","shinystan")
sapply(libs, require, character.only = TRUE)

## ---------------------------
## settings
## ---------------------------

## set number of cores to use to speed things up
options(mc.cores=parallel::detectCores())

## set a seed so things stay the same
my_seed <- 20231118

## ---------------------------
## input
## ---------------------------

df <- readRDS("college.RDS")

## ---------------------------
## show data set
## ---------------------------

df

## -----------------------------------------------------------------------------
## simple regression: intercept only (average college-going rate)
## -----------------------------------------------------------------------------

## likelihood of going to college
fit <- brm(college ~ 1,
           data = df,
           family = bernoulli("logit"),
           seed = my_seed)

## show summary stats
summary(fit)

## helper function: inverse logit
inv_logit <- function(x) { 1 / (1 + exp(-x)) }

## convert intercept value to probability scale
inv_logit(1.12)

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

## show distribution of intercept (our main parameter)
mcmc_areas(fit, prob = 0.95, pars = "b_Intercept") +
  labs(
    title = "Posterior distribution (log scale)",
    subtitle = "with median and 95% interval"
  )

## show distribution of transformed intercept (our main parameter)
## using helper function
mcmc_areas(fit, prob = 0.95, pars = "b_Intercept",
           transformation = list("b_Intercept" = inv_logit)) +
  labs(
    title = "Posterior distribution (probability)",
    subtitle = "with median and 95% interval; prior: student_t(0,3,2.5)"
  )

## ---------------------------
## check prior
## ---------------------------

## show prior from first model
prior_summary(fit)

## change to normal prior for comparison
fit <- brm(college ~ 1,
           data = df,
           family = bernoulli("logit"),
           seed = my_seed,
           prior = set_prior("normal(0,20)", class = "Intercept"))

## check prior
prior_summary(fit)

## show summary stats
summary(fit)

## show distribution of transformed intercept (our main parameter)
## using helper function
mcmc_areas(fit, prob = 0.95, pars = "b_Intercept",
           transformation = list("b_Intercept" = inv_logit)) +
  labs(
    title = "Posterior distribution (probability)",
    subtitle = "with median and 95% interval; prior: normal(0,20)",
  )

## ---------------------------
## posterior predictive check
## ---------------------------

## plot our posterior predictive values against the college-going rate
## that is observed in the data
ppc_stat(y = df |> pull(college) |> c(),
         yrep = posterior_epred(fit),
         stat = mean)

## -----------------------------------------------------------------------------
## speed up trick
## -----------------------------------------------------------------------------

## since we're using categorical variables (rather than continuous variables),
## collapse binary data (bernoulli) into smaller data set of successes/trials
## (binomial) to take advantage of sufficient statistics
df_tmp <- df |>
  summarise(college = sum(college),
            n = n())

## likelihood of going to college using binomial
fit <- brm(college | trials(n) ~ 1,
           data = df_tmp,
           family = binomial("logit"),
           seed = my_seed)

## show summary stats
summary(fit)

## -----------------------------------------------------------------------------
## multiple regression across groups
## -----------------------------------------------------------------------------

## collapse into groups of race/ethnicity by gender by poverty level
df_tmp <- df |>
  group_by(raceeth, gender, pov185) |>
  summarise(college = sum(college),
            n = n(),
            .groups = "drop")

## likelihood of going to college using binomial
fit <- brm(college | trials(n) ~ raceeth + gender + pov185 +
             (1 | raceeth:gender:pov185),
           data = df_tmp,
           family = binomial("logit"),
           seed = my_seed)

## show summary stats
summary(fit)

## ---------------------------
## posterior predictions
## ---------------------------

## create a design matrix (data frame) of all possible groups in our model
df_design <- expand.grid(raceeth = df |> distinct(raceeth) |> pull() |> c(),
                         gender = df |> distinct(gender) |> pull() |> c(),
                         pov185 = df |> distinct(pov185) |> pull() |> c(),
                         stringsAsFactors = FALSE) |>
  as_tibble() |>
  arrange(raceeth, gender, pov185) |>
  mutate(n = 100,
         group = paste(raceeth, gender, pov185, sep = "_"))

## get posterior predictions but in long form that's better for plotting
pp <- df_design |>
  add_epred_draws(fit,
                  ndraws = 500,
                  allow_new_levels = TRUE)

## compute mean posterior by group to get order for plot
pp_mean <- pp |>
  summarise(pp_mean = mean(.epred),
            .groups = "drop") |>
  arrange(pp_mean) |>
  mutate(plot_index = row_number(),
         plot_index = factor(plot_index,
                             levels = plot_index,
                             labels = group)) |>
  select(group, pp_mean, plot_index)

## join means back to main pp tibble and plot densities for each group
bayes_g <- pp |>
  left_join(pp_mean, by = "group") |>
  ggplot(aes(y = plot_index, x = .epred)) +
  stat_pointinterval(.width = 0.95, linewidth = 0.7, size = 1) +
  scale_x_continuous(breaks = seq(0, 100, 10),
                     minor_breaks = seq(0, 100, 5)) +
  labs(
    title = "Posterior predictive distributions of college enrollment",
    y = "Group: race/ethnicity + gender + poverty status (185%)",
    x = "Rate of college attendance"
  ) +
  theme_bw()
bayes_g

## -----------------------------------------------------------------------------
## quick comparison to frequentist approach
## -----------------------------------------------------------------------------

## fit logit model
lm_fit <- glm(cbind(college, n - college) ~ raceeth * gender * pov185,
              data = df_tmp,
              family = binomial("logit"))

## show summary
summary(lm_fit)

## generage response predictions (meaning transform to probability scale)
lm_pred <- predict(lm_fit,
                   newdata = df_design,
                   se.fit = TRUE,
                   type = "response")

## wrangle data and join plot_index from Bayes plot so everything aligns; plot
## means and 95 CIs to match prior plot
freq_g <- tibble(group = df_design$group,
                 pred = lm_pred$fit * 100,
                 se = lm_pred$se.fit * 100) |>
  mutate(ci95lo = pred + se * qnorm(0.025),
         ci95hi = pred + se * qnorm(0.975)) |>
  left_join(pp_mean, by = "group") |>
  ggplot(aes(y = plot_index, x = pred)) +
  geom_linerange(aes(xmin = ci95lo, xmax = ci95hi)) +
  geom_point(aes(x = pred)) +
  scale_x_continuous(breaks = seq(0, 100, 10),
                     minor_breaks = seq(0, 100, 5)) +
  annotate("rect", xmin = -Inf, xmax = 0, ymin = 0, ymax = Inf, alpha = 0.1) +
  annotate("rect", xmin = 100, xmax = Inf, ymin = 0, ymax = Inf, alpha = 0.1) +
  labs(
    title = "Frequentist predictions of college enrollment",
    y = "Group: race/ethnicity + gender + poverty status (185%)",
    x = "Rate of college attendance"
  ) +
  theme_bw()

## use patchwork to compare figures
freq_g / bayes_g &
  theme_bw(base_size = 6)

## -----------------------------------------------------------------------------
## comparison
## -----------------------------------------------------------------------------

## filter to two group comparison
pp_comp <- pp |>
  filter(group %in% c("white_male_above", "white_male_below"))

## plot two groups to make comparison clearer
comp_g <- pp_comp |>
  ggplot(aes(y = group, x = .epred)) +
  stat_pointinterval(.width = 0.95, linewidth = 0.7, size = 1) +
  scale_x_continuous(breaks = seq(0, 100, 5),
                     minor_breaks = seq(0, 100, 1)) +
  labs(
    title = "Posterior predictive distributions of college enrollment",
    y = "Group: race/ethnicity + gender + poverty status (185%)",
    x = "Rate of college attendance"
  ) +
  theme_bw()
comp_g
## wrangle data to subtract one group of predicitions from the other to get
## estimate of difference
pp_diff <- tibble(wma = pp_comp |> filter(group == "white_male_above") |> pull(.epred),
                  wmb = pp_comp |> filter(group == "white_male_below") |> pull(.epred),
                  diff = wma - wmb)

## plot density of difference
diff_g <- pp_diff |>
  ggplot(aes(x = diff)) +
  geom_density() +
  geom_vline(xintercept = pp_diff$diff |> mean(), linetype = "dashed") +
  scale_x_continuous(breaks = seq(0, 100, 1),
                     minor_breaks = seq(0, 100, 0.5)) +
   labs(
     title = "Difference in attendance rates",
     subtitle = "(White, male, above 185%) - (White, male, below 185%)",
     y = "Density",
     x = "Percentage point difference"
   ) +
  theme_bw()
diff_g

## -----------------------------------------------------------------------------
## end script
## -----------------------------------------------------------------------------
