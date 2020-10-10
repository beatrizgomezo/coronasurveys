library(tidyr)
library(dplyr)

responses_path <- "../data/aggregate/rivas-arganda/"
data_path <- "../data/common-data/rivas-arganda/regions-tree-population.csv"
estimates_path <- "../data/estimates-rivas-arganda/"

# responses_path <- "../coronasurveys/data/aggregate/rivas-arganda/"
# data_path <- "../coronasurveys/data/common-data/rivas-arganda/regions-tree-population.csv"
# estimates_path <- "./estimates-rivas-arganda/"

country_iso <- "ES"
ci_level <- 0.95
max_ratio <- 1/3
num_responses = 1000
age <- 7
smooth_param <- 25


remove_outliers <- function(dt, max_ratio = 1/3) {
  #remove outliers of reach.
  dt <- dt[!is.na(dt$reach),]
  dt <- dt[dt$reach != 0, ]
  dt <- dt[!is.na(dt$cases),]
  cat("Responses after removing reach=NA or cases=NA or reach=0 :", nrow(dt), "\n")
  
  cutoff <- boxplot.stats(dt$reach, coef=1.5)$stats[5] # changed cutoff to upper fence
  dt <- dt[dt$reach <= cutoff, ]
  cat("Responses after removing ouliers with reach cutoff", cutoff, ":", nrow(dt), "\n")

  # remove outliers based on max cases/reach ratio
  dt$ratio <- dt$cases/dt$reach
  #cutoff <- boxplot.stats(dt$ratio, coef=1.5)$stats[5] # changed cutoff to upper fence
  cutoff <- max_ratio
  dt <- dt[dt$ratio<cutoff, ]
  cat("Responses after removing ouliers with cases/reach cutoff", cutoff, ":", nrow(dt), "\n")
  
  # remove outliers based on max fatalities/reach ratio
  #dt <- dt[!is.na(dt$fatalities),]
  dt$ratio <- dt$fatalities/dt$reach
  #cutoff <- boxplot.stats(dt$ratio, coef=1.5)$stats[5] # changed cutoff to upper fence
  cutoff <- 1/10
  #dt <- dt[dt$ratio<cutoff, ]
  dt <- dt %>% filter(is.na(dt$ratio) | dt$ratio<cutoff)
  cat("Responses after removing ouliers with fatalities/reach cutoff", cutoff, ":", nrow(dt), "\n")

  return(dt)
}

#######

smooth_column_cum <- function(df_in, col_s, basis_dim = 15){
  
  ## List of packages
  packages = c("scam")
  ## Install&load all
  package.check <- lapply(
    packages,
    FUN = function(x) {
      if (!require(x, character.only = TRUE)) {
        install.packages(x, dependencies = TRUE)
        library(x, character.only = TRUE)
      }
    }
  )
  
  # add a number of "day" column:
  to.smooth <- df_in
  to.smooth$day <- 1:nrow(to.smooth)
  
  # change the name of column to be smoothed:
  colnames(to.smooth)[colnames(to.smooth) == col_s] = "y"
  
  # first non zero element to be smoothed:
  frst_n_zero <- head(to.smooth[to.smooth$y!=0, "day"], 1)
  
  cat("Smoothing starting at row ", frst_n_zero, "..\n")
  
  # data to be smoothed:
  to.smooth <- to.smooth[frst_n_zero:nrow(df_in), ]
  
  # Mono-smoothing with scam ----
  b1 <- scam(y ~ s(day, k = basis_dim, bs="mpi",m=2),
             family=gaussian(link="identity"), data=to.smooth)
  
  # save to column "xxx_smooth":
  df_in$y_smooth <- NA
  df_in[frst_n_zero:nrow(df_in) , "y_smooth"] <- b1$fitted.values
  colnames(df_in)[colnames(df_in) == "y_smooth"] <- paste0(col_s, 
                                                           "_smooth")
  return(df_in)
}

smooth_column <- function(df_in, col_s, basis_dim = 15){
  
  ## List of packages
  packages = c("scam")
  ## Install&load all
  package.check <- lapply(
    packages,
    FUN = function(x) {
      if (!require(x, character.only = TRUE)) {
        install.packages(x, dependencies = TRUE)
        library(x, character.only = TRUE)
      }
    }
  )
  
  # add a number of "day" column:
  to.smooth <- df_in
  to.smooth$day <- 1:nrow(to.smooth)
  
  # change the name of column to be smoothed:
  colnames(to.smooth)[colnames(to.smooth) == col_s] = "y"
  
  # first non zero element to be smoothed:
  frst_n_zero <- head(to.smooth[to.smooth$y!=0, "day"], 1)
  
  cat("Smoothing starting at row ", frst_n_zero, "..\n")
  
  # data to be smoothed:
  to.smooth <- to.smooth[frst_n_zero:nrow(df_in), ]
  
  # Mono-smoothing with scam ----
  # b1 <- scam(y ~ s(day, k = basis_dim, bs="mpi",m=2),
  #            family=gaussian(link="identity"), data=to.smooth)
  b1 <- gam(y ~ s(day, k = basis_dim, bs="ps"),
            data=to.smooth)
  
  # save to column "xxx_smooth":
  df_in$y_smooth <- NA
  df_in[frst_n_zero:nrow(df_in) , "y_smooth"] <- b1$fitted.values
  colnames(df_in)[colnames(df_in) == "y_smooth"] <- paste0(col_s, 
                                                           "_smooth")
  return(df_in)
}

############################



process_ratio <- function(dt, numerator, denominator, control, cummulative=TRUE){
  dta <- dt[!is.na(dt[[numerator]]),]
  dta <- dta[!is.na(dta[[denominator]]),]
  dta <- dta[dta[[numerator]] <= dta[[control]],]
  if (cummulative){
    #Remove duplicated cookies keeping the most recent response
    dta <- dta[!duplicated(dta$cookie, fromLast=TRUE, incomparables = c("")),]
  }
  
  if (nrow(dta)>0){
    #cat("- Max ", numerator, max(dta[[numerator]]), "\n"  )
    p_est <- sum(dta[[numerator]])/sum(dta[[denominator]])
    level <- ci_level
    z <- qnorm(level+(1-level)/2)
    se <- sqrt(p_est*(1-p_est))/sqrt(sum(dta[[denominator]]))
    return(list(val=p_est, low=max(0,p_est-z*se), upp=p_est+z*se, error=z*se, std=se, suma=sum(dta[[numerator]])))
  }
  else {
    return(list(val=NA, low=NA, upp=NA, error=NA, std=NA, suma=NA))
  }
}

# calculate_ci <- function(p_est, level, pop_size) {
#  z <- qnorm(level+(1-level)/2)
#  se <- sqrt(p_est*(1-p_est))/sqrt(pop_size)
#  return(list(p_est=est, low=max(0,p_est-z*se), upp=p_est+z*se)) #, error=z*se))
# }

process_region <- function(dt, reg, name, pop, dates, num_responses = 100, age = 7){
  cat("Working with", nrow(dt), "responses\n"  )
  #list of dates
  # dates <- as.character(seq.Date(as.Date(dt$timestamp[1]), as.Date(tail(dt$timestamp,1)), by = "days"))
  # dates <- gsub("-","/", dates)
  
  region <- c()
  regionname <- c()
  population <- c()
  
  sample_size <- c()
  reach <- c()
  
  p_cases <- c()
  p_cases_low <- c()
  p_cases_high <- c()

  cases  <- c()
  cases_est <- c()
  cases_low <- c()
  cases_high <- c()
  
  p_recovered <- c()
  p_recovered_low <- c()
  p_recovered_high <- c()
  
  p_fatalities <- c()
  p_fatalities_low <- c()
  p_fatalities_high <- c()

  fatalities <- c()
  fatalities_est <- c()
  fatalities_low <- c()
  fatalities_high <- c()
  
  p_recentcases <- c()
  p_recentcases_low <- c()
  p_recentcases_high <- c()

  recentcases <- c()
  recentcases_est <- c()
  recentcases_low <- c()
  recentcases_high <- c()
  
  p_recentcasesnursing <- c()
  p_recentcasesnursing_low <- c()
  p_recentcasesnursing_high <- c()
  
  recentcasesnursing_est <- c()
  recentcasesnursing_low <- c()
  recentcasesnursing_high <- c()
  
  p_stillsick <- c()
  p_stillsick_low <- c()
  p_stillsick_high <- c()
  
  p_hospital <- c()
  p_hospital_low <- c()
  p_hospital_high <- c()
  
  hospital_est <- c()
  hospital_low <- c()
  hospital_high <- c()

  p_recenthospital <- c()
  p_recenthospital_low <- c()
  p_recenthospital_high <- c()
  
  p_severe <- c()
  p_severe_low <- c()
  p_severe_high <- c()
  
  p_icu <- c()
  p_icu_low <- c()
  p_icu_high <- c()
  
  icu_est <- c()
  icu_low <- c()
  icu_high <- c()
  
  p_tested <- c()
  p_tested_low <- c()
  p_tested_high <- c()
  
  p_positive <- c()
  p_positive_low <- c()
  p_positive_high <- c()
  
  for (j in dates){
    #Keep responses at most "age" old
    subcondition <- (as.Date(dt$timestamp) > (as.Date(j)-age)  & as.Date(dt$timestamp) <= as.Date(j) )
    dt_date <- dt[subcondition, ]
    #Remove duplicated cookies keeping the most recent response
    # dt_date <- dt_date[!duplicated(dt_date$cookie, fromLast=TRUE, incomparables = c("")),]
    #Keep all the responses of the day or at most num_responses
    nr <- nrow(dt[as.Date(dt_date$timestamp) == as.Date(j), ])
    dt_date <- tail(dt_date, max(num_responses,nr))

    region <- c(region, reg)
    regionname <- c(regionname, name)
    population <- c(population, pop)
    
    sample_size <- c(sample_size, nrow(dt_date))
    reach <- c(reach, sum(dt_date$reach))
    
    est <- process_ratio(dt_date, "cases", "reach", "reach")
    p_cases <- c(p_cases, est$val)
    p_cases_low <- c(p_cases_low, est$low)
    p_cases_high <- c(p_cases_high, est$upp)
    
    cases  <- c(cases, est$suma)
    cases_est <- c(cases_est, pop*est$val)
    cases_low <- c(cases_low, pop*est$low)
    cases_high <- c(cases_high, pop*est$upp)
 
    est <- process_ratio(dt_date, "recentcases", "reach", "cases", cummulative=FALSE)
    p_recentcases <- c(p_recentcases, est$val)
    p_recentcases_low <- c(p_recentcases_low, est$low)
    p_recentcases_high <- c(p_recentcases_high, est$upp)
    
    est <- process_ratio(dt_date, "recentcases", "reach", "cases", cummulative=FALSE)
    recentcases <- c(recentcases, est$suma)
    recentcases_est <- c(recentcases_est, pop * est$val)
    recentcases_low <- c(recentcases_low, pop * est$low)
    recentcases_high <- c(recentcases_high, pop * est$upp)
    
    est <- process_ratio(dt_date, "recenthospital", "reach", "cases", cummulative=FALSE)
    p_recenthospital <- c(p_recenthospital, est$val)
    p_recenthospital_low <- c(p_recenthospital_low, est$low)
    p_recenthospital_high <- c(p_recenthospital_high, est$upp)
    
    if (j < as.POSIXct("2020-08-19")) {
      est <- process_ratio(dt_date, "recovered", "reach", "cases")
      p_recovered <- c(p_recovered, est$val)
      p_recovered_low <- c(p_recovered_low, est$low)
      p_recovered_high <- c(p_recovered_high, est$upp)
      
      est <- process_ratio(dt_date, "fatalities", "reach", "cases")
      p_fatalities <- c(p_fatalities, est$val)
      p_fatalities_low <- c(p_fatalities_low, est$low)
      p_fatalities_high <- c(p_fatalities_high, est$upp)
      
      est <- process_ratio(dt_date, "fatalities", "reach", "cases")
      fatalities <- c(fatalities, est$suma)
      fatalities_est <- c(fatalities_est, pop * est$val)
      fatalities_low <- c(fatalities_low, pop * est$low)
      fatalities_high <- c(fatalities_high, pop * est$upp)
      
      est <- process_ratio(dt_date, "recentcasesnursing", "reach", "recentcases", cummulative=FALSE)
      p_recentcasesnursing <- c(p_recentcasesnursing, est$val)
      p_recentcasesnursing_low <- c(p_recentcasesnursing_low, est$low)
      p_recentcasesnursing_high <- c(p_recentcasesnursing_high, est$upp)
      
      est <- process_ratio(dt_date, "recentcasesnursing", "reach", "recentcases", cummulative=FALSE)
      recentcasesnursing_est <- c(recentcasesnursing_est, pop * est$val)
      recentcasesnursing_low <- c(recentcasesnursing_low, pop * est$low)
      recentcasesnursing_high <- c(recentcasesnursing_high, pop * est$upp)
      
      est <- process_ratio(dt_date, "stillsick", "reach", "cases")
      p_stillsick <- c(p_stillsick, est$val)
      p_stillsick_low <- c(p_stillsick_low, est$low)
      p_stillsick_high <- c(p_stillsick_high, est$upp)
      
      est <- process_ratio(dt_date, "hospital", "reach", "cases")
      p_hospital <- c(p_hospital, est$val)
      p_hospital_low <- c(p_hospital_low, est$low)
      p_hospital_high <- c(p_hospital_high, est$upp)
      
      est <- process_ratio(dt_date, "hospital", "reach", "cases")
      hospital_est <- c(hospital_est, pop * est$val)
      hospital_low <- c(hospital_low, pop * est$low)
      hospital_high <- c(hospital_high, pop * est$upp)
      
      est <- process_ratio(dt_date, "severe", "reach", "cases")
      p_severe <- c(p_severe, est$val)
      p_severe_low <- c(p_severe_low, est$low)
      p_severe_high <- c(p_severe_high, est$upp)
      
      est <- process_ratio(dt_date, "icu", "reach", "cases")
      p_icu <- c(p_icu, est$val)
      p_icu_low <- c(p_icu_low, est$low)
      p_icu_high <- c(p_icu_high, est$upp)
      
      est <- process_ratio(dt_date, "icu", "reach", "cases")
      icu_est <- c(icu_est, pop * est$val)
      icu_low <- c(icu_low, pop * est$low)
      icu_high <- c(icu_high, pop * est$upp)
      
      est <- process_ratio(dt_date, "tested", "reach", "reach")
      p_tested <- c(p_tested, est$val)
      p_tested_low <- c(p_tested_low, est$low)
      p_tested_high <- c(p_tested_high, est$upp)
      
      est <- process_ratio(dt_date, "positive", "tested", "tested")
      p_positive <- c(p_positive, est$val)
      p_positive_low <- c(p_positive_low, est$low)
      p_positive_high <- c(p_positive_high, est$upp)
    }
    else {
      p_recovered <- c(p_recovered, NA)
      p_recovered_low <- c(p_recovered_low, NA)
      p_recovered_high <- c(p_recovered_high, NA)
      
      p_fatalities <- c(p_fatalities, NA)
      p_fatalities_low <- c(p_fatalities_low, NA)
      p_fatalities_high <- c(p_fatalities_high, NA)
      
      fatalities <- c(fatalities, NA)
      fatalities_est <- c(fatalities_est, NA)
      fatalities_low <- c(fatalities_low, NA)
      fatalities_high <- c(fatalities_high, NA)
      
      p_recentcasesnursing <- c(p_recentcasesnursing, NA)
      p_recentcasesnursing_low <- c(p_recentcasesnursing_low, NA)
      p_recentcasesnursing_high <- c(p_recentcasesnursing_high, NA)
      
      recentcasesnursing_est <- c(recentcasesnursing_est, NA)
      recentcasesnursing_low <- c(recentcasesnursing_low, NA)
      recentcasesnursing_high <- c(recentcasesnursing_high, NA)
      
      p_stillsick <- c(p_stillsick, NA)
      p_stillsick_low <- c(p_stillsick_low, NA)
      p_stillsick_high <- c(p_stillsick_high, NA)
      
      p_hospital <- c(p_hospital, NA)
      p_hospital_low <- c(p_hospital_low, NA)
      p_hospital_high <- c(p_hospital_high, NA)
      
      hospital_est <- c(hospital_est, NA)
      hospital_low <- c(hospital_low, NA)
      hospital_high <- c(hospital_high, NA)
      
      p_severe <- c(p_severe, NA)
      p_severe_low <- c(p_severe_low, NA)
      p_severe_high <- c(p_severe_high, NA)
      
      p_icu <- c(p_icu, NA)
      p_icu_low <- c(p_icu_low, NA)
      p_icu_high <- c(p_icu_high, NA)
      
      icu_est <- c(icu_est, NA)
      icu_low <- c(icu_low, NA)
      icu_high <- c(icu_high, NA)
      
      p_tested <- c(p_tested, NA)
      p_tested_low <- c(p_tested_low, NA)
      p_tested_high <- c(p_tested_high, NA)
      
      p_positive <- c(p_positive, NA)
      p_positive_low <- c(p_positive_low, NA)
      p_positive_high <- c(p_positive_high, NA)
    }
    
  }
  
  dd <- data.frame(date = dates,
                   region,
                   regionname,
                   population,
                   sample_size,
                   reach,
                   cases,
                   recentcases,
                   fatalities,
                   
                   cases_est,
                   cases_low,
                   cases_high,
                   
                   p_cases,
                   p_cases_low,
                   p_cases_high,
                   
                   recentcases_est,
                   recentcases_low,
                   recentcases_high,
                   
                   p_recentcases,
                   p_recentcases_low,
                   p_recentcases_high,
                   
                   p_recenthospital,
                   p_recenthospital_low,
                   p_recenthospital_high,
                   
                   recentcasesnursing_est,
                   recentcasesnursing_low,
                   recentcasesnursing_high,
                   
                   fatalities_est,
                   fatalities_low,
                   fatalities_high,
                   
                   hospital_est,
                   hospital_low,
                   hospital_high,
                   
                   icu_est,
                   icu_low,
                   icu_high,
                   
                   p_recovered,
                   p_recovered_low,
                   p_recovered_high,
                   
                   p_fatalities,
                   p_fatalities_low,
                   p_fatalities_high,
                   
                   p_recentcasesnursing,
                   p_recentcasesnursing_low,
                   p_recentcasesnursing_high,
                   
                   p_stillsick,
                   p_stillsick_low,
                   p_stillsick_high,
                   
                   p_hospital,
                   p_hospital_low,
                   p_hospital_high,
                   
                   p_severe,
                   p_severe_low,
                   p_severe_high,
                   
                   p_icu,
                   p_icu_low,
                   p_icu_high,
                   
                   p_tested,
                   p_tested_low,
                   p_tested_high,
                   
                   p_positive,
                   p_positive_low,
                   p_positive_high,
                   
                   stringsAsFactors = F)
  
  return(dd)
}




cat("Rivas-Arganda daily script run at ", as.character(Sys.time()), "\n\n")

file_path <- paste0(responses_path, country_iso, "-aggregate.csv")
dt <- read.csv(file_path, as.is = T)
cat("Received ", nrow(dt), " responses\n\n")
names(dt) <- tolower(names(dt))

#list of regions
region_tree <- read.csv(data_path, as.is = T)
names(region_tree) <- tolower(names(region_tree))
regions <- region_tree$provincecode
region_names <- region_tree$regionname
populations <- region_tree$population

#list of dates
dates_dash <- as.character(seq.Date(as.Date(dt$timestamp[1]), as.Date(tail(dt$timestamp,1)), by = "days"))
dates <- gsub("-","/", dates_dash)

# #list responses per date
# for (i in 1:length(regions)){
#   dta <- dt[dt$iso.3166.2==regions[i],]
#   cat("From ", regions[i], " received ", nrow(dta), " responses\n")
#   for (j in 1:length(dates)){
#     dtaa <- dta[dta$timestamp==dates[j],]
#     cat("-- On day ", dates[j], "received", nrow(dtaa), " responses, \n")
#   }
# }
# cat("\n")

dt <- remove_outliers(dt,max_ratio)

dw <- data.frame(date=c(),
                 region=c(),
                 regionname=c(),
                 population=c(),
                 sample_size=c(),
                 reach=c(),
                 cases=c(),
                 recentcases=c(),
                 fatalities=c(),
                 
                 
                 cases_est=c(),
                 cases_low=c(),
                 cases_high=c(),
                 
                 p_cases=c(),
                 p_cases_low=c(),
                 p_cases_high=c(),
                 
                 recentcases_est=c(),
                 recentcases_low=c(),
                 recentcases_high=c(),
                 
                 p_recentcases=c(),
                 p_recentcases_low=c(),
                 p_recentcases_high=c(),
                 
                 p_recenthospital=c(),
                 p_recenthospital_low=c(),
                 p_recenthospital_high=c(),
                 
                 recentcasesnursing_est=c(),
                 recentcasesnursing_low=c(),
                 recentcasesnursing_high=c(),
                 
                 fatalities_est=c(),
                 fatalities_low=c(),
                 fatalities_high=c(),
                 
                 hospital_est=c(),
                 hospital_low=c(),
                 hospital_high=c(),
                 
                 icu_est=c(),
                 icu_low=c(),
                 icu_high=c(),
                 
                 p_recovered=c(),
                 p_recovered_low=c(),
                 p_recovered_high=c(),
                 
                 p_fatalities=c(),
                 p_fatalities_low=c(),
                 p_fatalities_high=c(),
                 
                 p_recentcasesnursing=c(),
                 p_recentcasesnursing_low=c(),
                 p_recentcasesnursing_high=c(),
                 
                 p_stillsick=c(),
                 p_stillsick_low=c(),
                 p_stillsick_high=c(),
                 
                 p_hospital=c(),
                 p_hospital_low=c(),
                 p_hospital_high=c(),
                 
                 p_severe=c(),
                 p_severe_low=c(),
                 p_severe_high=c(),
                 
                 p_icu=c(),
                 p_icu_low=c(),
                 p_icu_high=c(),
                 
                 p_tested=c(),
                 p_tested_low=c(),
                 p_tested_high=c(),
                 
                 p_positive=c(),
                 p_positive_low=c(),
                 p_positive_high=c(),
                 
                 stringsAsFactors = F)

for (i in 1:length(regions)){
  reg <- regions[i]
  name <- region_names[i]
  cat("Processing", reg, "\n")
  dd <- process_region(dt[dt$iso.3166.2 == reg, ], reg, name, pop=populations[i], dates, num_responses, age)
  
  # smoothed p_cases and CI:
  dd <- smooth_column_cum(dd, "p_cases", smooth_param)
  dd <- smooth_column_cum(dd, "p_cases_low", smooth_param)
  dd <- smooth_column_cum(dd, "p_cases_high", smooth_param)
  
  # smoothed p_cases and CI:
  dd <- smooth_column(dd, "p_recentcases", smooth_param)
  dd$p_recentcases_smooth <- ifelse(dd$p_recentcases_smooth < 0, 0, dd$p_recentcases_smooth)
  dd <- smooth_column(dd, "p_recentcases_low", smooth_param)
  dd$p_recentcases_low_smooth <- ifelse(dd$p_recentcases_low_smooth > dd$p_recentcases_smooth, 
                                        dd$p_recentcases_smooth, dd$p_recentcases_low_smooth)
  dd$p_recentcases_low_smooth <- ifelse(dd$p_recentcases_low_smooth < 0, 0, dd$p_recentcases_low_smooth)
  dd <- smooth_column(dd, "p_recentcases_high", smooth_param)
  dd$p_recentcases_high_smooth <- ifelse(dd$p_recentcases_high_smooth < dd$p_recentcases_smooth, 
                                         dd$p_recentcases_smooth, dd$p_recentcases_high_smooth)
  
  
  cat("- Writing estimates for:", reg, "\n")
  write.csv(dd, paste0(estimates_path, reg, "-estimate.csv"), row.names = FALSE)
  dw <- rbind(dw, dd)
}

for (j in 1:length(dates)){
  write.csv(dw[dw$date == dates[j], ], paste0(estimates_path, country_iso, "-", dates_dash[j], "-estimate.csv"), row.names = FALSE)
}


