
##### _targets.R

#### Libraries ####
library(targets)
library(tarchetypes)
library(tidymodels)
library(tidyverse)
library(modeltime)
library(timetk)


#### Source Functions ####
tar_source("functions/data_preparation_functions.R")
tar_source("functions/models_functions.R")

list(
  
  #### Load the file 
  tar_target(
    name = air_quality_file,
    command = "data/data_date.csv",
    format = "file"
    ),
  
  #### Read the data ####
  tar_target(
    name = air_quality_data,
    command = read.csv(air_quality_file)
  ),
  
  #### Data Pre-processing and Cleaning ####
  tar_target(
    name = air_quality_cleaned,
    command = data_prep(data = air_quality_data)
  ),
  
  #### Data Extensions ####
  tar_target(
    name = air_quality_extend,
    command = extend_data(data = air_quality_cleaned,horizon = "1 month")
  ),
  
  ###### Future Data #####
  tar_target(
    name = future_data,
    command = air_quality_extend %>% filter(is.na(aqi_value))
  ),
  
  ##### Prepared data #####
  tar_target(
    name = air_quality_preprocessed,
    command = air_quality_extend %>% drop_na()
  ),
  
  #### Grouping ####
  
  ##### Group air_quality_preprocessed ####
  tar_group_by(
    name = group_air_quality_preprocessed,
    command = air_quality_preprocessed,
    country
    ),
  
  ##### Group future_data ####
  tar_group_by(
    name = group_future_data,
    command = future_data,
    country
    ),
  
  #### Branching ####
  
  ##### Branch group_air_quality_preprocessed ####
  tar_target(
    name = branch_air_quality_preprocessed,
    command = group_air_quality_preprocessed,
    pattern = map(group_air_quality_preprocessed)
    ),
  
  ##### Branch group_future_data ####
  tar_target(
    name = branch_future_data,
    command = group_future_data,
    pattern = map(group_future_data)
    ),
  
  #### Split the data #####
  tar_target(
    name = split_group_air_quality_preprocessed,
    command = split_grouped_ts_data(
      data = branch_air_quality_preprocessed,
      horizon = "1 month"
      ),
    pattern = map(branch_air_quality_preprocessed) 
  ),
  
  #### Modeling ####
  
  ##### Model 1 ARIMA ####
  tar_target(
    name = Arima_model,
    command = arima_flow(
      splits_tbl = split_group_air_quality_preprocessed),
    pattern = map(split_group_air_quality_preprocessed) 
    ),
  
  ##### Model 2 Prophet ####
  tar_target(
    name = Prophet_model,
    command = prophet_flow(
      splits_tbl = split_group_air_quality_preprocessed),
    pattern = map(split_group_air_quality_preprocessed)
    ),
  
  ##### Model 3 Glmnet ####
  tar_target(
    name = Glmnet_model,
    command = glmnet_flow(
      splits_tbl = split_group_air_quality_preprocessed),
    pattern = map(split_group_air_quality_preprocessed) 
  ),
  
  ##### Model 4 XGB ####
  tar_target(
    name = Xgb_model,
    command = xgb_flow(
      splits_tbl = split_group_air_quality_preprocessed),
    pattern = map(split_group_air_quality_preprocessed)
    ),
  
  ##### Model 5 NNETAR ####
  tar_target(
    name = Nnetar_model,
    command = nnetar_flow(
      splits_tbl = split_group_air_quality_preprocessed),
    pattern = map(split_group_air_quality_preprocessed)
    ),
  
  #### Test Acc ####
  
  ###### Arima Acc ####
  tar_target(
    name = arima_acc,
    command = model_acc(Arima_model),
    pattern = map(Arima_model)
    ),
  
  ###### Prophet Acc ####
  tar_target(
    name = prophet_acc,
    command = model_acc(Prophet_model),
    pattern = map(Prophet_model)
  ),
  
  ###### Glmnet Acc ####
  tar_target(
    name = glmnet_acc,
    command = model_acc(Glmnet_model),
    pattern = map(Glmnet_model)
  ),
  
  ###### XGB Acc ####
  tar_target(
    name = xgb_acc,
    command = model_acc(Xgb_model),
    pattern = map(Xgb_model)
  ),
  
  ###### NNETAR Acc ####
  tar_target(
    name = nnetar_acc,
    command = model_acc(Nnetar_model),
    pattern = map(Nnetar_model)
  ),

   ##### Compare Model ####
  tar_target(
    name = comp_models,
    command = compare_best_acc(
      arima_acc,
      prophet_acc,
      glmnet_acc,
      xgb_acc,
      nnetar_acc
      ),
    pattern = map(
      arima_acc,
      prophet_acc,
      glmnet_acc,
      xgb_acc,
      nnetar_acc
    )
  ),
  ##### Select Models ####
  tar_target(
    name = best_models,
    command = select_best_models(
      acc_table = comp_models,
      Nnetar_model,
      Xgb_model,
      Glmnet_model,
      Prophet_model,
      Arima_model
      ),
    pattern = map(
      Nnetar_model,
      Xgb_model,
      Glmnet_model,
      Prophet_model,
      Arima_model,
      comp_models
      )
    ),
  
  #### Refit best models and final forecast  ####
  tar_target(
    name = refit_models,
    command = refit_model(
      model_tbl = best_models,
      data = branch_air_quality_preprocessed
      ),
    pattern = map(
      best_models,
      branch_air_quality_preprocessed)
    ),
  
##### Forecast ####
tar_target(
  name = final_forecast,
  command = forecast_best(
    refit = refit_models,
    future = branch_future_data,
    data_prep = branch_air_quality_preprocessed
    ),
  pattern = map(
    refit_models,
    branch_future_data,
    branch_air_quality_preprocessed
    )
  )
)




