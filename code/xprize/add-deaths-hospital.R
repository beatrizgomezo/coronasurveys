# load library
library(tidyverse)
library(data.table)
# library(readxl)
# library(httr)

args <- commandArgs(trailingOnly = T)

print(args)
cat("usage: command cases_file output_file\n")

cases_file <- args[1]
output_file <- args[2]

country_region_list <- "./data/countries_regions.csv"

onset_to_death_window <- 13 # CDC web site
onset_to_hospital <- 6 # CDC web site
cases_in_hospital <- 0.25 # Augusto's study in our draft
hospital_in_icu <- 0.30 # CDC web site <50: 23.8%, 50-64: 36.1%, >64: 35.3%
IFR <- 0.01 # 1% IFR


process_country_region <- function(regiondf, df) {
  
  country <- regiondf$CountryName[1]
  region <- regiondf$RegionName[1]
  
  # cat("\n working on ", country, region, "\n")
  
  df <- df[(df$CountryName == country) & 
                  (df$RegionName == region),]
  
  df$PredictedDailyNewDeaths <- NA
  df$PredictedDailyNewHospital <- NA
  df$PredictedDailyNewICU <- NA
  
  # Change df$PredictedDailyNewDeaths
  df$PredictedDailyNewDeaths <- shift(df$PredictedDailyNewCases * IFR, 
                                        n = onset_to_death_window, 
                                        fill = NA)
  
  # Hospital cases
  df$PredictedDailyNewHospital <- shift(df$PredictedDailyNewCases * cases_in_hospital, 
                                        n = onset_to_hospital, 
                                        fill = NA)
  
  df$PredictedDailyNewICU <- df$PredictedDailyNewHospital * hospital_in_icu
  
  return(df)
}

# ---------------------- main 

dfc <- read.csv(cases_file, stringsAsFactors=FALSE) #, check.names = FALSE)
dfc$Date <- as.Date(dfc$Date)

regiondf <- read.csv(country_region_list, stringsAsFactors=FALSE)
regiondf$RegionName[is.na(regiondf$RegionName)] <- ""
regiondf <- regiondf[,c("CountryName", "RegionName")]
n <- nrow(regiondf)

# print(n)

df2 <- process_country_region(as.data.frame(regiondf[1,]), dfc)

if (n>1) {
  for (i in 2:n) {
    df2 <- bind_rows(df2, process_country_region(as.data.frame(regiondf[i,]), dfc))
  }
}

df2 <- df2[order(df2$CountryName,df2$RegionName,df2$Date),]
write.csv(df2, output_file, row.names = F)
