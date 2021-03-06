library(tidyr)
library(dplyr)
# install.packages("xtable")
library("xtable")

responses_path <- "../data/aggregate/"
data_path <- "../data/common-data/regions-tree-population.csv"
estimates_path <- "../data/estimates-regions/"

# responses_path <- "../coronasurveys/data/aggregate/"
# data_path <- "../coronasurveys/data/common-data/regions-tree-population.csv"
# estimates_path <- "./estimates-regions/"

countries <- c("ES")
ci_level <- 0.95
cases_cutoff <- 1/3
fatalities_cutoff <- 1/2
recent_cutoff <- 1/2

max_responses <- 100
max_age <- 150
max_age_recent <- 15
sampling <- 100000 # If the reach is < population/sampling the estimate is NA
sampling_recent <- 100000 # If the reach is < population/sampling_recent the estimate is NA


remove_outliers <- function(dt, ratio_cutoff=1/3, fatalities_cutoff=1/10) {
  cat("Total responses :", nrow(dt), "\n")
    #remove outliers of reach.
  dt <- dt[!is.na(dt$reach),]
  dt <- dt[dt$reach != 0, ]
  dt <- dt[!is.na(dt$cases),]
  cat("Responses after removing reach=NA or cases=NA or reach=0 :", nrow(dt), "\n")
  
  #Compute cutoffs
  reach_cutoff <- boxplot.stats(dt$reach, coef=1.5)$stats[5] # changed cutoff to upper fence

  # dt$ratio <- dt$cases/dt$reach
  # cases_cutoff <- boxplot.stats(dt$ratio, coef=1.5)$stats[5] # changed cutoff to upper fence
  # 
  # dt$ratio <- dt$fatalities/dt$reach
  # fatalities_cutoff <- boxplot.stats(dt$ratio, coef=1.5)$stats[5] # changed cutoff to upper fence
  # 
  # dt$ratio <- dt$recentcases/dt$reach
  # recent_cutoff <- boxplot.stats(dt$ratio, coef=1.5)$stats[5] # changed cutoff to upper fence
  
  # remove outliers based on ratios
  dt <- dt[dt$reach <= reach_cutoff, ]
  cat("Responses after removing ouliers with reach cutoff", 
      reach_cutoff, ":", nrow(dt), "\n")
  
  dt <- dt[(dt$cases/dt$reach) <= cases_cutoff, ]
  cat("Responses after removing ouliers with cases/reach cutoff", 
      cases_cutoff, ":", nrow(dt), "\n")
  
  dt <- dt %>% filter(is.na(dt$fatalities) | (dt$fatalities/dt$reach) <= fatalities_cutoff)
  cat("Responses after removing ouliers with fatalities/reach cutoff", 
      fatalities_cutoff, ":", nrow(dt), "\n")

  dt <- dt %>% filter(is.na(dt$recentcases) | (dt$recentcases/dt$reach) <= recent_cutoff)
  cat("Responses after removing ouliers with recent/reach cutoff", 
      recent_cutoff, ":", nrow(dt), "\n")
  
  cat("\n")
  return(dt)
}

process_ratio <- function(dt, numerator, denominator, control){
  dta <- dt[!is.na(dt[[numerator]]),]
  dta <- dta[!is.na(dta[[denominator]]),]
  dta <- dta[dta[[numerator]] <= dta[[control]],]
  if (nrow(dta)>0){
    p_est <- sum(dta[[numerator]])/sum(dta[[denominator]])
    level <- ci_level
    z <- qnorm(level+(1-level)/2)
    se <- sqrt(p_est*(1-p_est))/sqrt(sum(dta[[denominator]]))
    return(list(val=p_est, low=max(0,p_est-z*se), upp=p_est+z*se, error=z*se, std=se))
  }
  else {
    return(list(val=NA, low=NA, upp=NA, error=NA, std=NA))
  }
}


process_region <- function(dt, reg, 
                           # name, 
                           pop, dates, max_responses = 1000, max_age = 1000, recent_max_age=7){
  cat("Working with", nrow(dt), "responses\n"  )

  region <- c()
  # regionname <- c()
  sample_size <- c()
  reach <- c()
  sample_size_recent <- c()
  reach_recent <- c()
  
  p_cases <- c()
  p_cases_error <- c()

  p_fatalities <- c()
  p_fatalities_error <- c()

  p_recentcases <- c()
  p_recentcases_error <- c()
  
  p_cases_daily <- c()
  p_cases_daily_error <- c()
  
  p_stillsick <- c()
  p_stillsick_error <- c()
  
  population <- c()
  
  for (j in dates){
    #Keep responses at most "max_age" old
    subcondition <- (as.Date(dt$timestamp) > (as.Date(j)-max_age) & as.Date(dt$timestamp) <= as.Date(j))
    dt_date <- dt[subcondition, ]
    
    #Remove duplicated cookies keeping the most recent response
    dt_date <- dt_date[!duplicated(dt_date$cookie, fromLast=TRUE, incomparables = c("")),]
    
    # #Keep all the responses of the day or at most max_responses
    # nr <- nrow(dt[as.Date(dt_date$timestamp) == as.Date(j), ])
    # dt_date <- tail(dt_date, max(max_responses,nr))
    #Keep at most max_responses
    dt_date <- tail(dt_date, max_responses)
    
    #Keep responses at most "max_age_recent" old for recent computations
    dt_recent <- dt_date
    subcondition <- (as.Date(dt_recent$timestamp) > (as.Date(j)-max_age_recent) & as.Date(dt_recent$timestamp) <= as.Date(j) )
    dt_recent <- dt_recent[subcondition, ]
    
    # cat("Responses for the date", nrow(dt_date), "recent:", nrow(dt_recent), "\n")
    
    region <- c(region, reg)
    # regionname <- c(regionname, name)
    sample_size <- c(sample_size, nrow(dt_date))
    reach <- c(reach, sum(dt_date$reach))
    
    sample_size_recent <- c(sample_size_recent, nrow(dt_recent))
    reach_recent <- c(reach_recent, sum(dt_recent$reach))

    if (sum(dt_date$reach) >= pop/sampling){
      est <- process_ratio(dt_date, "cases", "reach", "reach")
      p_cases <- c(p_cases, est$val)
      p_cases_error <- c(p_cases_error, est$error)
      
      est <- process_ratio(dt_date, "fatalities", "reach", "cases")
      p_fatalities <- c(p_fatalities, est$val)
      p_fatalities_error <- c(p_fatalities_error, est$error)
    }
    else {
      # cat("Low reach\n"  )
      p_cases <- c(p_cases, NA)
      p_cases_error <- c(p_cases_error, NA)
      p_fatalities <- c(p_fatalities, NA)
      p_fatalities_error <- c(p_fatalities_error, NA)
    }

    if (sum(dt_recent$reach) >= pop/sampling_recent){
      est <- process_ratio(dt_recent, "recentcases", "reach", "cases")
      p_recentcases <- c(p_recentcases, est$val)
      p_recentcases_error <- c(p_recentcases_error, est$error)
      
      dt_recent$cases_daily <- dt_recent$recentcases / 7
      est <- process_ratio(dt_recent, "cases_daily", "reach", "cases")
      p_cases_daily <- c(p_cases_daily, est$val)
      p_cases_daily_error <- c(p_cases_daily_error, est$error)
      
      est <- process_ratio(dt_recent, "stillsick", "reach", "cases")
      p_stillsick <- c(p_stillsick, est$val)
      p_stillsick_error <- c(p_stillsick_error, est$error)
    }
    else {
      # cat("Low reach_recent\n"  )
      p_recentcases <- c(p_recentcases, NA)
      p_recentcases_error <- c(p_recentcases_error, NA)
      p_cases_daily <- c(p_cases_daily, NA)
      p_cases_daily_error <- c(p_cases_daily_error, NA)
      p_stillsick <- c(p_stillsick, NA)
      p_stillsick_error <- c(p_stillsick_error, NA)
    }
    
    population <- c(population, pop)
  }
  
  dd <- data.frame(date = dates,
                   region,
                   # regionname,
                   population,
                   sample_size,
                   reach,
                   sample_size_recent,
                   reach_recent,
                   
                   p_cases,
                   p_cases_error,

                   p_fatalities,
                   p_fatalities_error,

                   p_recentcases,
                   p_recentcases_error,
                   
                   p_cases_daily,
                   p_cases_daily_error,
                   
                   p_stillsick,
                   p_stillsick_error,

                   stringsAsFactors = F)
  
  return(dd)
}


#### Start of main body

for (co in 1:length(countries)){
  
  country_iso <- countries[co]

cat("Country ", country_iso, " region daily script run at ", as.character(Sys.time()), "\n\n")

#list of regions
region_tree <- read.csv(data_path, as.is = T)
names(region_tree) <- tolower(names(region_tree))
region_tree <- region_tree[region_tree$countrycode==country_iso,]
regions <- unique(region_tree$regioncode)
# region_names <- region_tree$regionname
# populations <- region_tree$population

file_path <- paste0(responses_path, country_iso, "-aggregate.csv")
dt <- read.csv(file_path, as.is = T)
cat("Received ", nrow(dt), " responses\n\n")
names(dt) <- tolower(names(dt))

#change region name to province name for single-province regions
#dt <- change_region_province(dt)
# dt$iso.3166.2[dt$iso.3166.2=="ESAS"] <- "ESO"
# dt$iso.3166.2[dt$iso.3166.2=="ESCB"] <- "ESS"
# dt$iso.3166.2[dt$iso.3166.2=="ESIB"] <- "ESPM"
# dt$iso.3166.2[dt$iso.3166.2=="ESMC"] <- "ESMU"
# dt$iso.3166.2[dt$iso.3166.2=="ESMD"] <- "ESM"
# dt$iso.3166.2[dt$iso.3166.2=="ESNC"] <- "ESNA"
# dt$iso.3166.2[dt$iso.3166.2=="ESRI"] <- "ESLO"

#change province name to region name for single-province regions
#dt <- change_region_province(dt)
dt$iso.3166.2[dt$iso.3166.2=="ESO"] <-  "ESAS"
dt$iso.3166.2[dt$iso.3166.2=="ESS"] <-  "ESCB"
dt$iso.3166.2[dt$iso.3166.2=="ESPM"] <-  "ESIB"
dt$iso.3166.2[dt$iso.3166.2=="ESMU"] <-  "ESMC"
dt$iso.3166.2[dt$iso.3166.2=="ESM"] <-  "ESMD"
dt$iso.3166.2[dt$iso.3166.2=="ESNA"] <-  "ESNC"
dt$iso.3166.2[dt$iso.3166.2=="ESLO"] <-  "ESRI"


#list of dates
dates_dash <- as.character(seq.Date(as.Date(dt$timestamp[1]), as.Date(tail(dt$timestamp,1)), by = "days"))
dates <- gsub("-","/", dates_dash)

#list responses per region
for (i in 1:length(regions)){
  dta <- dt[dt$iso.3166.2==regions[i],]
  cat("From ", regions[i], " received ", nrow(dta), " responses\n")
  # for (j in 1:length(dates)){
  #   dtaa <- dta[dta$timestamp==dates[j],]
  #   cat("-- On day ", dates[j], "received", nrow(dtaa), " responses, \n")
  # }
}
cat("\n")

dt <- remove_outliers(dt, cases_cutoff, fatalities_cutoff)

dw <- data.frame(date=c(),
                 region=c(),
                 # regionname=c(),
                 population=c(),
                 sample_size=c(),
                 reach=c(),
                 sample_size_recent=c(),
                 reach_recent=c(),

                 p_cases=c(),
                 p_cases_error=c(),

                 p_fatalities=c(),
                 p_fatalities_error=c(),

                 p_recentcases=c(),
                 p_recentcases_error=c(),
                 
                 p_cases_daily=c(),
                 p_cases_daily_error=c(),
                 
                 p_stillsick=c(),
                 p_stillsick_error=c(),

                 stringsAsFactors = F)

# #computation of 300 responses-----------------------------------------------
# dates <- c("2020/04/20")
# #Keep responses at most "max_age" old
# subcondition <- (as.Date(dt$timestamp) <= as.Date("2020/04/20"))
# dt <- dt[subcondition, ]
# 
# #Remove duplicated cookies keeping the most recent response
# dt <- dt[!duplicated(dt$cookie, fromLast=TRUE, incomparables = c("")),]
# 
# #Keep 300 responses 
# dt <- tail(dt, 300)
# #end 300 responses-----------------------------------------------------------

for (i in 1:length(regions)){
  reg <- regions[i]
  cat("Processing", reg, #region_names[i], 
      "\n")
  rt <- region_tree[region_tree$regioncode == reg,]
  pop <- sum(rt$population)
  dd <- process_region(dt[dt$iso.3166.2 == reg, ], reg, # name=region_names[i], 
                       pop, dates, max_responses, max_age, recent_max_age)
  #cat("- Writing estimates for:", reg, region_names[i], "\n")
  write.csv(dd, paste0(estimates_path, country_iso, "/", reg, "-estimate.csv"), row.names = FALSE)
  dw <- rbind(dw, dd)
}

for (j in 1:length(dates)){
  write.csv(dw[dw$date == dates[j], ], paste0(estimates_path, country_iso, "/", country_iso, "-", dates_dash[j], "-estimate.csv"), row.names = FALSE)
}

dw_latest <- dw[dw$date == dates[length(dates)], ]
rownames(dw_latest) <- NULL
write.csv(dw_latest, paste0(estimates_path, country_iso, "/", country_iso, "-latest-estimate.csv"), row.names = FALSE)
# print(xtable(dw_latest), type="html", file=paste0(estimates_path, country_iso, "/", country_iso, "-latest-estimate.html"))

subcondition <- (as.Date(dw$date) >= as.Date("2020-04-13") & as.Date(dw$date) <= as.Date("2020-04-27"))
dw_ene <- dw[subcondition, ]
dw_ene <- dw_ene %>% select(date, region, population, sample_size, reach, p_cases, p_cases_error)
write.csv(dw_ene, paste0(estimates_path, country_iso, "/", country_iso, "-enecovid-estimate.csv"), row.names = FALSE)
}

