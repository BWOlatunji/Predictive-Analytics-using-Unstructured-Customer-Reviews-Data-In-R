# LIBRARIES ----

# Text & ML
library(tidymodels) # Machine Learning
library(textrecipes) # Text Preprocessing
library(stopwords)
# Core
library(tidyverse)
library(janitor)
library(readxl)
library(jsonlite)
library(timetk)

# Data sourcing
acme_oyster_house_reviews <- read_rds("data/acme_oyster_house_reviews.rds")

acme_oyster_house_reviews_clean_tbl <- acme_oyster_house_reviews %>%
  mutate(
    date = parse_date2(date)
  )


acme_oyster_house_reviews_clean_tbl %>% glimpse()


# DATA EXPERIMENTATION --------

acme_customer_reviews_quarterly_tbl <- acme_oyster_house_reviews_clean_tbl %>%
  summarise_by_time(
    score_mean   = mean(stars),
    score_median = median(stars),
    .by          = "quarter",
    .date_var = date
  ) 

acme_customer_reviews_quarterly_tbl %>%
  pivot_longer(
    cols      = -date, 
    names_to  = "category",
    values_to = "value"
  ) %>%
  group_by(category) %>%
  plot_time_series(
    date, 
    value
  )

acme_oyster_house_reviews_clean_tbl %>%
  select(date, stars) %>%
  plot_time_series_boxplot(
    .date_var = date, 
    .value    = stars,
    .period   = "year"
  )


# ** Putting it all together ----
acme_data <- acme_oyster_house_reviews_clean_tbl |> 
  select(stars,text)

text_recipe_5B <- recipe(stars ~ ., data = acme_data) %>%
  step_tokenize(text) %>%
  step_stopwords(text) %>%
  step_ngram(
    text,
    num_tokens     = 3, 
    min_num_tokens = 1
  ) %>%
  step_tokenfilter(
    text,
    max_tokens = 1000
  ) %>%
  step_tfidf(text)


text_recipe_5B %>% prep() %>% juice()


# MACHINE LEARNING (MODELING) ----
# - Find a model that estimates the star rating from 
#   unstructured text

# * Data Splitting ----


set.seed(123)
splits <- initial_split(acme_data, prop = 0.80)

training(splits)
testing(splits)  

# * Preprocessing ----
text_recipe <- recipe(stars ~ ., data = training(splits)) %>%
  step_tokenize(text) %>%
  step_stopwords(text) %>%
  step_ngram(
    text,
    num_tokens     = 3, 
    min_num_tokens = 1
  ) %>%
  step_tokenfilter(
    text,
    max_tokens = 50
  ) %>%
  step_tfidf(text)

text_recipe %>% prep() %>% bake(training(splits)) 
text_recipe %>% prep() %>% bake(testing(splits))  

# * Modeling ----

# ** XGBoost 1 ----

model_spec_xgb_1 <- boost_tree(
  mode       = "regression",
  learn_rate = 0.30
) %>% 
  set_engine("xgboost")

wflw_xgb_1 <- workflow() %>%
  add_model(model_spec_xgb_1) %>%
  add_recipe(text_recipe) %>%
  fit(training(splits))

wflw_xgb_1


# * Evaluate Model ----

predictions_xgb_tbl <- wflw_xgb_1 %>%
  predict(testing(splits)) %>%
  bind_cols(testing(splits), .) 

predictions_xgb_tbl

# ** Check Model Error vs Naive Guessing ----
predictions_xgb_tbl %>%
  yardstick::rmse(stars, .pred)

predictions_xgb_tbl %>%
  mutate(.naive = mean(stars)) %>%
  yardstick::rmse(stars, .naive)

# ** Check Variance Explained ----
predictions_xgb_tbl %>%
  yardstick::rsq(stars, .pred)

predictions_xgb_tbl %>%
  ggplot(aes(stars, .pred)) +
  geom_jitter(alpha = 0.5, size = 5, width = 0.1, height = 0) +
  geom_smooth()


# EXPLORE THE MODEL ----

# * Feature importance ----

xgb_feature_importance_tbl <- wflw_xgb_1 %>%
  extract_fit_parsnip() %>%
  pluck("fit") %>%
  xgboost::xgb.importance(model = .) %>%
  as_tibble() %>%
  slice(1:20)

xgb_feature_importance_tbl %>%
  ggplot(aes(Gain, fct_rev(as_factor(Feature)))) +
  geom_point()

# WHAT INSIGHTS BASED ON SELECTED FEATURE IMPORTANCE? ----

# * keyword: "recipe" ----
bake(prep(text_recipe), testing(splits)) %>%
  select(tfidf_text_food) %>%
  bind_cols(
    testing(splits) %>% select(stars)
  ) %>%
  group_by(stars) %>%
  summarise(mean_text_food = mean(tfidf_text_food)) %>%
  ungroup()


# * keyword: "oysters" ----
bake(prep(text_recipe), testing(splits)) %>%
  select(tfidf_text_oysters) %>%
  bind_cols(
    testing(splits) %>% select(stars)
  ) %>%
  group_by(stars) %>%
  summarise(mean_tfidf_text_oysters = mean(tfidf_text_oysters)) %>%
  ungroup()


# * keyword: "delicious" ----
bake(prep(text_recipe), testing(splits)) %>%
  select(tfidf_text_delicious) %>%
  bind_cols(
    testing(splits) %>% select(stars)
  ) %>%
  group_by(stars) %>%
  summarise(mean_tfidf_text_delicious = mean(tfidf_text_delicious)) %>%
  ungroup()

# CONCLUSIONS ----
# - See the slide deck




