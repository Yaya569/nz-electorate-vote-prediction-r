# Predicting New Zealand Electorate Votes in R

Predictive modelling of New Zealand electorate voting patterns using demographic data and regularised regression.

## Project Overview

This project explores whether demographic characteristics of New Zealand electorates can be used to predict the combined 2023 vote total for the parties that formed the government following the 2023 New Zealand general election.

Demographic profile data were combined with electorate-level voting results to create a modelling dataset. A regularised regression approach was then used to handle the large number of potential predictors relative to the number of electorates.

The project demonstrates a practical workflow for predictive modelling, including data preparation, feature preprocessing, regularisation, cross-validation and model evaluation.

## Data

The analysis combines two datasets:

* New Zealand electorate demographic profile data
* 2023 electorate-level voting results

The demographic data contain a large number of percentage-based characteristics for each electorate.

The target variable represents the combined number of votes received by:

* National
* ACT
* New Zealand First

The original datasets are not reproduced in this repository.

## Data Preparation

The analysis involved several data preparation steps:

* Cleaning and standardising variable names
* Removing irrelevant rows from the demographic dataset
* Converting numeric variables into appropriate numeric formats
* Cleaning electorate names before joining datasets
* Extracting the relevant party vote columns
* Converting vote counts into numeric values
* Combining National, ACT and New Zealand First votes into a single target variable
* Joining demographic and voting data by electorate

## Modelling Approach

The dataset contains substantially more potential predictors than would be appropriate for an ordinary unregularised regression model.

A **Lasso regression** model was therefore used to perform prediction while simultaneously shrinking less useful coefficients towards zero.

The modelling workflow included:

1. Median imputation for missing predictor values
2. Near-zero variance feature removal
3. Predictor normalisation
4. Lasso regression using `glmnet`
5. Ten-fold cross-validation
6. Tuning of the regularisation penalty
7. Evaluation using RMSE, MAE and MAPE

## Model Evaluation

Cross-validation was used to estimate out-of-sample prediction performance.

The final cross-validation results were:

| Metric |         Result |
| ------ | -------------: |
| RMSE   | 1,793.99 votes |
| MAE    | 1,454.51 votes |
| MAPE   |          9.04% |

The MAE indicates that the model's predictions differed from the observed combined vote total by approximately 1,455 votes on average.

The MAPE of approximately 9% provides a scale-independent measure of prediction error relative to the observed vote totals.

## Feature Selection

Lasso regularisation reduced the contribution of many predictors while retaining a subset of features with non-zero coefficients.

The largest absolute coefficients in the fitted model included:

* `x162`
* `x76`
* `x96`
* `x88`
* `x269`
* `x95`
* `x344`
* `x44`
* `x173`

These coefficients identify demographic variables that contributed most strongly to the fitted predictions.

Because the original demographic dataset contains coded variables, coefficient magnitude should be interpreted as a modelling result rather than as evidence of a causal relationship.

## Key Takeaways

This project demonstrates how regularised regression can be used when working with a high-dimensional dataset containing many potential predictors.

The results suggest that electorate-level demographic characteristics contain useful information for predicting combined government-party vote totals, while cross-validation provides a more realistic assessment of predictive performance than training-set accuracy alone.

The analysis also demonstrates the importance of preprocessing and model selection when the number of candidate predictors is large relative to the number of observations.

## Tools & Skills

* R
* tidyverse
* readxl
* tidymodels
* glmnet
* Data Cleaning
* Feature Engineering
* Regularised Regression
* Lasso Regression
* Cross-Validation
* Predictive Modelling
* Model Evaluation
* Statistical Analysis

## Repository Structure

```text
nz-electorate-vote-prediction-r/
├── README.md
└── analysis.R
```

## Notes

The original datasets are not included in this repository. The project focuses on demonstrating the analytical workflow, modelling approach and interpretation.

This repository is an independent portfolio adaptation of statistical modelling work originally completed as part of university coursework.

## Citations and Acknowledgements

The underlying electorate demographic data were produced from New Zealand official statistical information, and the voting data are based on the 2023 New Zealand general election.

Generative AI was used to assist with code organisation, documentation and portfolio presentation.
