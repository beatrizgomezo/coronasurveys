#/bin/bash

if [ "$#" -ne 1 ]; then
  echo "illegal number of parameters"
  exit 1
fi

weightfile=$1
outfile="out.$$"

starthistory="2020-11-01" # Date from which the IPS files start
startdate="2021-01-01" # Date from which predictions start
today=`date +%Y-%m-%d` # Date from which prescriptions start
# enddate="2021-04-30"  # Last date considered
enddate=`date -v+89d +%Y-%m-%d`  # Last date considered (today plus 89 days)


# Run CoronaSurveys prescriptor from today to enddate

echo --- Running prescriptor $today $enddate

echo --- With weights fixed_equal_costs.csv

python prescribe.py -s $today -e "$enddate" -ip ./data/IPS-latest-full.csv \
  -c ./data/fixed_equal_costs.csv -o ./prescriptions/fixed_equal_costs.csv

echo --- With weights uniform_random_costs.csv

python prescribe.py -s $today -e "$enddate" -ip ./data/IPS-latest-full.csv \
  -c ./data/uniform_random_costs.csv -o ./prescriptions/uniform_random_costs.csv


# Run the predictions for each prescriptor

for i in 0 1 2 3 4 5 6 7 8 9
do
  echo --- Preparing IPS for predictor $i for $startdate $today $enddate

  echo --- With weights fixed_equal_costs.csv

  Rscript prepare-prediction.R $startdate $today $enddate ./data/IPS-latest-full.csv \
    ./prescriptions/fixed_equal_costs.csv $i ./prescriptions/fixed_equal_costs-${i}.csv


  echo --- With weights uniform_random_costs.csv

  Rscript prepare-prediction.R $startdate $today $enddate ./data/IPS-latest-full.csv \
    ./prescriptions/uniform_random_costs.csv $i ./prescriptions/uniform_random_costs-${i}.csv

   
  echo --- Running predictor $i from $today to $enddate

  echo --- With weights fixed_equal_costs.csv

  python standard_predictor/predict.py -s "$today" -e "$enddate" \
    -ip ./prescriptions/fixed_equal_costs-${i}.csv -o ./predictions/fixed_equal_costs-${i}.csv

  echo --- With weights uniform_random_costs.csv

  python standard_predictor/predict.py -s "$today" -e "$enddate" \
    -ip ./prescriptions/uniform_random_costs-${i}.csv -o ./predictions/uniform_random_costs-${i}.csv


  echo -- Adding fatalities, hospital, ICU, Cost

  echo --- With weights fixed_equal_costs.csv 

  Rscript add-deaths-hospital-cost.R ./predictions/fixed_equal_costs-${i}.csv ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv \
    $i ./prescriptions/fixed_equal_costs.csv ./data/fixed_equal_costs.csv

  echo --- With weights uniform_random_costs.csv 

  Rscript add-deaths-hospital-cost.R ./predictions/uniform_random_costs-${i}.csv ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv \
    $i ./prescriptions/uniform_random_costs.csv ./data/uniform_random_costs.csv 

  echo -- Summarizing
  echo --- With weights fixed_equal_costs.csv

  Rscript performance-summary.R ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv \
    ../../data/xprize/cs-tasks/fixed_equal_costs-summary-${i}.csv $i

  echo --- With weights uniform_random_costs.csv 

  Rscript performance-summary.R ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv \
    ../../data/xprize/cs-tasks/uniform_random_costs-summary-${i}.csv $i
done

