#/bin/bash

outfile="out.$$"

starthistory="2020-11-01" # Date from which the IPS files start
startdate="2021-01-01" # Date from which predictions start
today=`date +%Y-%m-%d` # Date from which prescriptions start
# enddate="2021-04-30"  # Last date considered
enddate=`date -v+89d +%Y-%m-%d`  # Last date considered (today plus 89 days)

# Generate the IPS file from the Oxford repository, propagating the last IP until enddate

echo --- Downloading and completing IPS file from $starthistory to $enddate

Rscript complete-IPS.R "$starthistory" "$enddate" > $outfile 2>&1


# Run predictor with real IPS
echo --- Running predictor with real IPS from $startdate to $enddate

python standard_predictor/predict.py -s "$startdate" -e "$enddate" \
  -ip ./data/IPS-latest-full.csv -o ./predictions/real-IPS-predictions.csv >> $outfile 2>&1



echo -- Adding fatalities, hospital, ICU, cost, and interventions to real IPS predictions from $startdate to $enddate

echo --- With weights fixed_equal_costs.csv

Rscript add-deaths-hospital-cost-IPS.R "$startdate" "$enddate" \
  ./predictions/real-IPS-predictions.csv ../../data/xprize/cs-tasks/real-IPS-predictions-fixed_equal_costs.csv \
  ./data/IPS-latest-full.csv ./data/fixed_equal_costs.csv >> $outfile 2>&1


echo --- With weights uniform_random_costs.csv

Rscript add-deaths-hospital-cost-IPS.R "$startdate" "$enddate" \
  ./predictions/real-IPS-predictions.csv ../../data/xprize/cs-tasks/real-IPS-predictions-uniform_random_costs.csv \
  ./data/IPS-latest-full.csv ./data/uniform_random_costs.csv >> $outfile 2>&1
