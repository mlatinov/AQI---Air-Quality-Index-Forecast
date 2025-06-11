
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
    command = extend_data(data = air_quality_cleaned,horizon = "3 months")
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
    command = split_grouped_ts_data() 
  )
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
)