
ccfrdata <- read.csv("../data/estimates-ccfr-based/PlotData/PT-estimate.csv")
casedata <- read.csv("../data/estimates-confirmed/PlotData/PT-estimate.csv")



#r <- ccfrdata$cases_daily/ccfrdata$cases

l <- length(casedata$cum_cases)
#rc <- c(0)

#for (i in 2:l)
#{
#  c <- casedata$cases[i]/casedata$cum_cases[i-1]
#  p <- 1-c
#  x <- (r[i]-r[i-1]*p)/c
#  rc <- c(rc,x)
#}

ec <- ccfrdata$p_cases*ccfrdata$population[1]
ec[1] <- 0
ec[is.na(ec)] <- 0

ecc <- c(0)

a <- 0
ecc[1] <- ec[1]

for (i in 2:l)
{
  if (ec[i] < ec[i-1])
  {
    d <- ec[i] - ec[i-1]
    ecc[i] <- ec[i-1]
    ec[i+1] <- ec[i+1] - d
  }
  else
  {
    ecc[i] <- ec[i]
  }
}

ed <- diff(ecc)

d <- ccfrdata$deaths/0.0138

ds <- d[-(1:12)]

smoo <- 5

plot(runmed(ccfrdata$cases,smoo),type="l",ylim=c(0,max(ed))); lines(runmed(ed,smoo),type="l",lty=2); lines(runmed(ds,smoo),type="l",lty=3)

legend(x="topleft", legend=c("RT-PCR cases", "cCFR based cases estimate","death based cases estimate"), lty=1:3, cex=1)
abline(h=0,lty=1)

sum(ccfrdata$cases)
sum(ed)
sum(d)

(sum(ed)/0.66)/ccfrdata$population[1]

#plot(ccfrdata$cases,type="l",lty=1,ylim=c(0,10000))
#lines(ccfrdata$cases_daily,lty=2)

#lines(runmed(ccfrdata$cases_daily,smoo),type="l",lty=4)

