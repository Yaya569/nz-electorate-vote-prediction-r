# New Zealand Electorate Vote Prediction
# Predictive modelling using demographic data and Lasso regression

library(readxl)
library(dplyr)
library(stringr)
library(janitor)
library(readr)
library(tidymodels)

# ---------------------------------------------------------
# 1. Load and prepare electorate profile data
# ---------------------------------------------------------

load_profile_data <- function(file_path) {
  
  profiles <- read_excel(
    file_path,
    sheet = "Percent"
  ) %>%
    clean_names()
  
  names(profiles)[1] <- "Electorate"
  
  second_col <- names(profiles)[2]
  
  profiles_clean <- profiles %>%
    filter(
      !is.na(Electorate),
      trimws(as.character(Electorate)) != ""
    ) %>%
    filter(
      trimws(as.character(.data[[second_col]])) == ".."
    )
  
  numeric_columns <- setdiff(
    names(profiles_clean),
    "Electorate"
  )
  
  profiles_clean[numeric_columns] <- lapply(
    profiles_clean[numeric_columns],
    function(x) suppressWarnings(as.numeric(x))
  )
  
  profiles_clean %>%
    mutate(
      Electorate = str_trim(as.character(Electorate))
    ) %>%
    select(
      Electorate,
      where(is.numeric)
    )
}


# ---------------------------------------------------------
# 2. Load and prepare 2023 voting data
# ---------------------------------------------------------

load_vote_data <- function(file_path) {
  
  votes <- read_csv(
    file_path,
    show_col_types = FALSE
  ) %>%
    mutate(
      Electorate = str_trim(as.character(Electorate))
    )
  
  act_columns <- names(votes)[
    str_detect(
      names(votes),
      regex("ACT", ignore_case = TRUE)
    )
  ]
  
  national_columns <- names(votes)[
    str_detect(
      names(votes),
      regex("NATIONAL", ignore_case = TRUE)
    )
  ]
  
  nz_first_columns <- names(votes)[
    str_detect(
      names(votes),
      regex(
        "NEW\\.ZEALAND\\.FIRST|NEW ZEALAND FIRST|NZ\\.? FIRST",
        ignore_case = TRUE
      )
    )
  ]
  
  party_columns <- unique(
    c(
      act_columns,
      national_columns,
      nz_first_columns
    )
  )
  
  votes %>%
    filter(
      !str_detect(
        Electorate,
        regex(
          "Totals|Total|Combined",
          ignore_case = TRUE
        )
      )
    ) %>%
    mutate(
      across(
        all_of(party_columns),
        ~ as.numeric(
          str_replace_all(
            as.character(.x),
            ",",
            ""
          )
        )
      )
    ) %>%
    group_by(Electorate) %>%
    summarise(
      GovtVotes2023 = sum(
        c_across(all_of(party_columns)),
        na.rm = TRUE
      ),
      .groups = "drop"
    )
}


# ---------------------------------------------------------
# 3. Combine demographic and voting data
# ---------------------------------------------------------

prepare_model_data <- function(profile_data, vote_data) {
  
  inner_join(
    profile_data,
    vote_data,
    by = "Electorate"
  )
}


# ---------------------------------------------------------
# 4. Build Lasso regression workflow
# ---------------------------------------------------------

build_lasso_workflow <- function(model_data) {
  
  recipe_model <- recipe(
    GovtVotes2023 ~ .,
    data = model_data %>%
      select(-Electorate)
  ) %>%
    step_impute_median(
      all_predictors()
    ) %>%
    step_nzv(
      all_predictors()
    ) %>%
    step_normalize(
      all_predictors()
    )
  
  model_spec <- linear_reg(
    penalty = tune(),
    mixture = 1
  ) %>%
    set_engine("glmnet")
  
  workflow() %>%
    add_recipe(recipe_model) %>%
    add_model(model_spec)
}


# ---------------------------------------------------------
# 5. Tune the regularisation penalty
# ---------------------------------------------------------

tune_lasso_model <- function(workflow_model, model_data) {
  
  folds <- vfold_cv(
    model_data,
    v = min(10, nrow(model_data))
  )
  
  penalty_grid <- tibble(
    penalty = 10^seq(
      -3,
      3,
      length.out = 50
    )
  )
  
  tuning_results <- tune_grid(
    workflow_model,
    resamples = folds,
    grid = penalty_grid,
    metrics = metric_set(
      rmse,
      mae
    ),
    control = control_grid(
      save_pred = TRUE
    )
  )
  
  tuning_results
}


# ---------------------------------------------------------
# 6. Evaluate cross-validation performance
# ---------------------------------------------------------

evaluate_model <- function(tuning_results) {
  
  predictions <- collect_predictions(
    tuning_results
  )
  
  rmse_value <- predictions %>%
    rmse(
      truth = GovtVotes2023,
      estimate = .pred
    ) %>%
    pull(.estimate)
  
  mae_value <- predictions %>%
    mae(
      truth = GovtVotes2023,
      estimate = .pred
    ) %>%
    pull(.estimate)
  
  mape_value <- predictions %>%
    mutate(
      absolute_percentage_error =
        abs(GovtVotes2023 - .pred) /
        pmax(GovtVotes2023, 1)
    ) %>%
    summarise(
      mape = mean(
        absolute_percentage_error,
        na.rm = TRUE
      )
    ) %>%
    pull(mape) * 100
  
  tibble(
    RMSE = rmse_value,
    MAE = mae_value,
    MAPE = mape_value
  )
}


# ---------------------------------------------------------
# 7. Extract important model coefficients
# ---------------------------------------------------------

extract_coefficients <- function(
  final_workflow,
  best_penalty
) {
  
  fitted_model <- extract_fit_engine(
    final_workflow
  )
  
  coefficient_matrix <- as.matrix(
    coef(
      fitted_model,
      s = best_penalty
    )
  )
  
  tibble(
    Feature = rownames(coefficient_matrix),
    Coefficient = as.numeric(
      coefficient_matrix
    )
  ) %>%
    arrange(
      desc(abs(Coefficient))
    )
}


# ---------------------------------------------------------
# 8. Example analysis workflow
# ---------------------------------------------------------

# The original datasets are not included in this repository.
# The following workflow shows how the analysis was performed
# when the datasets were available locally.

# profile_data <- load_profile_data(
#   "data/electorate_profiles_2020-data_file.xlsx"
# )
#
# vote_data <- load_vote_data(
#   "data/votes2023.csv"
# )
#
# model_data <- prepare_model_data(
#   profile_data,
#   vote_data
# )
#
# lasso_workflow <- build_lasso_workflow(
#   model_data
# )
#
# tuning_results <- tune_lasso_model(
#   lasso_workflow,
#   model_data
# )
#
# best_model <- select_best(
#   tuning_results,
#   metric = "rmse"
# )
#
# final_workflow <- finalize_workflow(
#   lasso_workflow,
#   best_model
# )
#
# final_fit <- fit(
#   final_workflow,
#   data = model_data
# )
#
# performance <- evaluate_model(
#   tuning_results
# )
#
# print(performance)
#
# coefficients <- extract_coefficients(
#   final_fit,
#   best_model$penalty
# )
#
# print(coefficients)


# ---------------------------------------------------------
# 9. Reported cross-validation results
# ---------------------------------------------------------

# RMSE: 1,793.99 votes
# MAE:  1,454.51 votes
# MAPE: 9.04%


# ---------------------------------------------------------
# 10. Interpretation
# ---------------------------------------------------------

# The Lasso model was selected because the electorate profile
# dataset contains a large number of potential predictors.
# Regularisation helps reduce the influence of less useful
# variables while retaining predictors that contribute to
# predictive performance.
#
# Cross-validation provides an estimate of how accurately the
# model is expected to perform on unseen electorate data.
#
# The final model achieved a cross-validation RMSE of
# approximately 1,794 votes and a MAPE of approximately 9%.
#
# These results suggest that demographic characteristics
# contain useful information for predicting combined votes
# for National, ACT and New Zealand First.
#
# The coefficients should be interpreted as predictive
# associations rather than causal effects.
