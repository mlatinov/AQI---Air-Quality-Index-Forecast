

##### Data preparation Function ####

data_prep <- function(data){
  
  
  data %>%
    
    # Remove Status 
    select(-Status) %>%
    
    # Change the names 
    rename(
      date = Date,
      country = Country,
      aqi_value = AQI.Value,
    ) %>%
    
    # Remove Dublicated values
    distinct(country, date, .keep_all = TRUE) %>%
    
    # Convert date to date class
    mutate(
      date = ymd(date)
    ) %>%
    
    # Group by country
    group_by(country) %>%
    
    # Regulalize the time series 
    pad_by_time(
      .date_var = date,
      .by = "day",                    # ensure daily frequency
      .pad_value = NA,                # fill new rows with NA
      .fill_na_direction = "none"     # leave NAs for downstream handling
    ) %>%
    
    # Impute The missing Values 
    mutate(
      aqi_value = ts_impute_vec(aqi_value, period = 7)
    ) %>%
    
    # Add time series features 
    tk_augment_timeseries_signature(.date_var = date) %>%
    
    # Add lags
    tk_augment_lags(
      .value = aqi_value,
      .lags = c(7,14,21),
      .names = c("lag_7","lag_14","lag_21")
    )%>%
    
    # Add Rolling Features
    tk_augment_slidify(
      .value = aqi_value,
      .period = c(10,30,60,90),
      .f = mean,
      .partial = TRUE,
      .names = c("MA_10","MA_30","MA_60","MA_90")
    ) %>%
    
    # Add holiday features
    tk_augment_holiday_signature(
      .date_var = date,
      .locale_set = c( "World")
    ) %>%
    
    # Ungroup
    ungroup()
}

#### Data Extension Function ####
extend_data <- function(data,horizon = "3 months"){
  
  data %>%
    distinct() %>%
    group_by(country) %>%
    
    # Extend the data by horizon
    future_frame(.date_var = date,.length_out = horizon,.bind_data = TRUE) %>%
    ungroup() %>%
    distinct()
  
}

##### Split Function ####
split_grouped_ts_data <- function(data ,horizon){
  
  
  
  
  
}













