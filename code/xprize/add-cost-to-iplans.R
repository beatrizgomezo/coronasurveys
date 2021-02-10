# load library
library(tidyverse)
#library(data.table)
# library(readxl)
# library(httr)

args <- commandArgs(trailingOnly = T)

print(args)
cat("usage: command iplan_file cost_file output_file\n")

iplan_file <- args[1]
cost_file <- args[2]
output_file <- args[3]

country_region_list <- "./data/countries_regions.csv"

process_country_region <- function(regiondf, df, costs) {
  
  country <- regiondf$CountryName[1]
  region <- regiondf$RegionName[1]
  
  cat("\n working on ", country, region, "\n")
  
  df <- df[(df$CountryName == country) & 
                  (df$RegionName == region),]
  dfcost <- costs[(costs$CountryName == country) & 
                    (as.character(costs$RegionName) == as.character(region)),]
  
  # Computes the cost of the vectors
  for (i in 1:nrow(df)) {
    df[i, "Cost"] <- as.matrix(df[i, c("C1_School.closing","C2_Workplace.closing",
                                       "C3_Cancel.public.events","C4_Restrictions.on.gatherings",
                                       "C5_Close.public.transport","C6_Stay.at.home.requirements",
                                       "C7_Restrictions.on.internal.movement","C8_International.travel.controls",
                                       "H1_Public.information.campaigns","H2_Testing.policy",
                                       "H3_Contact.tracing","H6_Facial.Coverings")]) %*% t(as.matrix(dfcost[1, 3:14]))
  }
  
  return(df)
}

# ---------------------- main 

costs <- read.csv(cost_file, check.names = FALSE, stringsAsFactors=FALSE)
costs$RegionName[is.na(costs$RegionName)] <- ""

dfc <- read.csv(iplan_file, stringsAsFactors=FALSE) #, check.names = FALSE)
dfc$RegionName[is.na(dfc$RegionName)] <- ""
dfc$Date <- as.Date(dfc$Date)

dfc <- read.csv(iplan_file, stringsAsFactors=FALSE) #, check.names = FALSE)
dfc$RegionName[is.na(dfc$RegionName)] <- ""
dfc$Date <- as.Date(dfc$Date)

regiondf <- read.csv(country_region_list, stringsAsFactors=FALSE)
regiondf$RegionName[is.na(regiondf$RegionName)] <- ""
regiondf <- regiondf[,c("CountryName", "RegionName")]
n <- nrow(regiondf)

# print(n)

df2 <- process_country_region(as.data.frame(regiondf[1,]), dfc, costs)

if (n>1) {
  for (i in 2:n) {
    df2 <- bind_rows(df2, process_country_region(as.data.frame(regiondf[i,]), dfc, costs))
  }
}

df2 <- df2[order(df2$CountryName,df2$RegionName,df2$Date),]
write.csv(df2, output_file, row.names = F)
