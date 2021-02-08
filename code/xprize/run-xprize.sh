#/bin/bash

starthistory="2020-11-01"
startdate="2021-01-01"
today=`date +%Y-%m-%d`
enddate="2021-02-28"

# Generate the IPS file from the Oxford repository, propagating the last IP until enddate

echo --- Downloading and completing IPS file
echo Rscript complete-IPS.R "$starthistory" "$enddate"

Rscript complete-IPS.R "$starthistory" "$enddate"


# Run predictor with real IPS
echo --- Running predictor with real IPS
echo --- python standard_predictor/predict.py -s "$startdate" -e "$enddate" -ip ./data/IPS-latest-full.csv -o ../../data/xprize/cs-tasks/real-IPS-predictions.csv

python standard_predictor/predict.py -s "$startdate" -e "$enddate" -ip ./data/IPS-latest-full.csv -o ../../data/xprize/cs-tasks/real-IPS-predictions.csv



# Run our prescriptor from today to enddate

echo --- Running prescriptor
echo --- python prescribe.py -s $today -e "$enddate" -ip ./data/IPS-latest-full.csv -c ./data/fixed_equal_costs.csv -o ./prescriptions/fixed_equal_costs.csv

python prescribe.py -s $today -e "$enddate" -ip ./data/IPS-latest-full.csv -c ./data/fixed_equal_costs.csv -o ./prescriptions/fixed_equal_costs.csv

echo --- python prescribe.py -s $today -e "$enddate" -ip ./data/IPS-latest-full.csv -c ./data/uniform_random_costs.csv -o ./prescriptions/uniform_random_costs.csv

python prescribe.py -s $today -e "$enddate" -ip ./data/IPS-latest-full.csv -c ./data/uniform_random_costs.csv -o ./prescriptions/uniform_random_costs.csv


# Run the predictions for each prescriptor

for i in 0 1 2 3 4 5 6 7 8 9
do
  echo --- Preparing IPS for predictor $i
  echo --- Rscript prepare-prediction.R $starthistory $today $enddate ./data/IPS-latest-full.csv \
    ./prescriptions/fixed_equal_costs.csv $i ./prescriptions/fixed_equal_costs-${i}.csv

  Rscript prepare-prediction.R $starthistory $today $enddate ./data/IPS-latest-full.csv \
    ./prescriptions/fixed_equal_costs.csv $i ./prescriptions/fixed_equal_costs-${i}.csv


  echo --- Rscript prepare-prediction.R $starthistory $today $enddate ./data/IPS-latest-full.csv \
    ./prescriptions/uniform_random_costs.csv $i ./prescriptions/uniform_random_costs-${i}.csv

  Rscript prepare-prediction.R $starthistory $today $enddate ./data/IPS-latest-full.csv \
    ./prescriptions/uniform_random_costs.csv $i ./prescriptions/uniform_random_costs-${i}.csv

   
  echo --- Running predictor $i
  echo --- python standard_predictor/predict.py -s "$startdate" -e "$enddate" -ip ./prescriptions/fixed_equal_costs-${i}.csv -o ./predictions/fixed_equal_costs-${i}.csv

  python standard_predictor/predict.py -s "$startdate" -e "$enddate" -ip ./prescriptions/fixed_equal_costs-${i}.csv -o ./predictions/fixed_equal_costs-${i}.csv

  echo --- python standard_predictor/predict.py -s "$startdate" -e "$enddate" -ip ./prescriptions/uniform_random_costs-${i}.csv -o ./predictions/uniform_random_costs-${i}.csv

  python standard_predictor/predict.py -s "$startdate" -e "$enddate" -ip ./prescriptions/uniform_random_costs-${i}.csv -o ./predictions/uniform_random_costs-${i}.csv


  echo -- Adding fatalities, hospital, ICU
  echo -- Rscript add-deaths-hospital.R ./predictions/fixed_equal_costs-${i}.csv ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv

  Rscript add-deaths-hospital.R ./predictions/fixed_equal_costs-${i}.csv ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv

  echo -- Rscript add-deaths-hospital.R ./predictions/uniform_random_costs-${i}.csv ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv

  Rscript add-deaths-hospital.R ./predictions/uniform_random_costs-${i}.csv ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv


  #rm ./prescriptions/fixed_equal_costs-${i}.csv ./predictions/fixed_equal_costs-${i}.csv
done

