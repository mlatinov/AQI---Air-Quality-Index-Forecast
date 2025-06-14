
##### Modeling Functions #####

###### Model 1 ARIMA ####
arima_flow <- function(splits_tbl){
  
  tar_group <- splits_tbl %>% pull(tar_group) %>% unique()
  
  train_tbl <- splits_tbl %>%
    pull(split) %>%
    pluck(1) %>%
    training()
  
  arima_wf <- workflow() %>%
    add_model(
      spec = arima_reg() %>% 
        set_engine("auto_arima")
    )%>%
    add_recipe(
      recipe = recipe(aqi_value ~ date,data = train_tbl)
    ) %>%
    fit(train_tbl)
  
  ret <- tibble(
    tar_group = tar_group,
    wflw_fit = list(arima_wf)
  )
  
  ret <- splits_tbl %>%
    mutate(wflw_fit  = list(arima_wf))
  
  return(ret)
  
}

###### Model 2 PROPHET ####
prophet_flow <- function(splits_tbl){
  
  
  tar_group <- splits_tbl %>% pull(tar_group) %>% unique()
  
  train_tbl <- splits_tbl %>%
    pull(split) %>%
    pluck(1) %>%
    training()
  
  prophet_fw <- workflow() %>%
    add_model(
      spec = prophet_reg() %>%
        set_engine("prophet")
      ) %>%
    add_recipe(
      recipe = recipe(aqi_value ~ date,data = train_tbl)
      ) %>%
    fit(train_tbl)
  
  ret <- tibble(
    tar_group = tar_group,
    wflw_fit = list(prophet_fw)
  )
  
  ret <- splits_tbl %>%
    mutate(wflw_fit  = list(prophet_fw))
  
  return(ret)
}

###### Model 3 GLMNET ####
glmnet_flow <- function(splits_tbl){
  
  tar_group <- splits_tbl %>% pull(tar_group) %>% unique()
  
  train_tbl <- splits_tbl %>%
    pull(split) %>%
    pluck(1) %>%
    training()
  
  glmnet_fw <- workflow() %>%
    add_model(
      spec = linear_reg(
        penalty = 0.1) %>%
        set_engine("glmnet") %>%
        set_mode("regression")
    ) %>%
    add_recipe(
      recipe = recipe(aqi_value ~ .,data = train_tbl)%>%
        step_rm(date) %>%   
        step_nzv(all_predictors()) %>%
        step_normalize(all_numeric_predictors()) %>%
        step_dummy(all_nominal_predictors(), one_hot = TRUE)
        ) %>%
    fit(train_tbl)
  
  ret <- tibble(
    tar_group = tar_group,
    wflw_fit = list(glmnet_fw)
  )
  
  ret <- splits_tbl %>%
    mutate(wflw_fit = list(glmnet_fw))
  
  return(ret)
}

###### Model 4 XGB ####
xgb_flow <- function(splits_tbl){
  
  tar_group <- splits_tbl %>% pull(tar_group) %>% unique()
  
  train_tbl <- splits_tbl %>%
    pull(split) %>%
    pluck(1) %>%
    training()
  
  xgb_wf <- workflow() %>%
    add_model(
      spec = boost_tree()%>%
        set_mode("regression") %>%
        set_engine("xgboost")
      ) %>%
    add_recipe(
      recipe = recipe(aqi_value ~ .,data = train_tbl) %>%
        step_rm(date) %>%   
        step_nzv(all_predictors()) %>%
        step_dummy(all_nominal_predictors(),one_hot = TRUE)
      ) %>%
    fit(train_tbl)
  
  ret <- tibble(
    tar_group  = tar_group,
    wflw_fit = list(xgb_wf)
  )
  
  ret <- splits_tbl %>%
    mutate(wflw_fit = list(xgb_wf))
  
  return(ret)
}

##### Model 5 NNETAR ####
nnetar_flow <- function(splits_tbl){
  
  tar_group <- splits_tbl %>% pull(tar_group) %>% unique()
  
  train_tbl <- splits_tbl %>%
    pull(split) %>%
    pluck(1) %>%
    training()
  
  nnetar_wf <- workflow() %>%
    add_model(
      spec = nnetar_reg() %>%
        set_engine("nnetar")
    ) %>% 
    add_recipe(
      recipe = recipe(aqi_value ~ .,data = train_tbl)
      ) %>%
    fit(train_tbl)
  
  ret <- tibble(
    tar_group = tar_group,
    wflw_fit = list(nnetar_wf)
  )
  
  ret <- splits_tbl %>%
    mutate(wflw_fit = list(nnetar_wf))
  
  return(ret)
}

##### Test Functions ####

###### Test ACC ####
model_acc <- function(model_tbl) {
  
  tar_group <- model_tbl %>% pull(tar_group) %>% unique()
  
  test_tbl <- model_tbl %>%
    pull(split) %>%
    pluck(1) %>%
    testing()
  
  wf <- model_tbl %>% 
    pull(wflw_fit) %>%
    pluck(1)
  
  modeltime_table(
    wf 
  ) %>%
    modeltime_accuracy(test_tbl) %>%
    add_column(tar_group = tar_group,.before = 1)
}

##### Compare Models ####
compare_best_acc <- function(...){
  
  bind_rows(...) %>%
    group_by(tar_group) %>%
    slice_min(rmse,n = 1) %>%
    ungroup()
  
}

##### Select Best Models ####
select_best_models <- function(acc_table,...){
  
  bind_rows(...) %>%
    mutate(.model_desc = map_chr(wflw_fit,.f = get_model_description)) %>%
    filter(.model_desc %in% acc_table$.model_desc)
  
}


##### Refit best models ####
refit_model <- function(model_tbl , data){
  
  tar_group <- model_tbl %>% pull(tar_group) %>% unique()
  
  modeltime_table(
    model_tbl$wflw_fit[[1]]
  ) %>% 
    modeltime_refit(data) %>%
    mutate(tar_group = tar_group)

}

#### Forecast future
forecast_best <- function(refit,future,data_prep){
  
  refit %>%
    select(-tar_group) %>%
    modeltime_forecast(
      new_data = future,
      actual_data = data_prep,
      keep_data = TRUE
      )
}
























