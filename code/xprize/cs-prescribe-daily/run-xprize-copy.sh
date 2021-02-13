#/bin/bash


# Run the predictions for each prescriptor

for i in 0 1 2 3 4 5 6 7 8 9
do

  echo -- Adding fatalities, hospital, ICU, Cost
  echo -- Rscript add-deaths-hospital-cost.R ./predictions/fixed_equal_costs-${i}.csv ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv \
    $i ./prescriptions/fixed_equal_costs.csv ./data/fixed_equal_costs.csv 

  Rscript add-deaths-hospital-cost.R ./predictions/fixed_equal_costs-${i}.csv ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv \
    $i ./prescriptions/fixed_equal_costs.csv ./data/fixed_equal_costs.csv

  echo -- Rscript add-deaths-hospital-cost.R ./predictions/uniform_random_costs-${i}.csv ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv \
    $i ./prescriptions/uniform_random_costs.csv ./data/uniform_random_costs.csv 


  Rscript add-deaths-hospital-cost.R ./predictions/uniform_random_costs-${i}.csv ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv \
    $i ./prescriptions/uniform_random_costs.csv ./data/uniform_random_costs.csv 

 

  echo -- Summarizing
  echo -- Rscript performance-summary.R ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv \
    ../../data/xprize/cs-tasks/fixed_equal_costs-summary-${i}.csv $i

  Rscript performance-summary.R ../../data/xprize/cs-tasks/fixed_equal_costs-${i}.csv \
    ../../data/xprize/cs-tasks/fixed_equal_costs-summary-${i}.csv $i

  echo -- Rscript performance-summary.R ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv \
    ../../data/xprize/cs-tasks/uniform_random_costs-summary-${i}.csv $i

  Rscript performance-summary.R ../../data/xprize/cs-tasks/uniform_random_costs-${i}.csv \
    ../../data/xprize/cs-tasks/uniform_random_costs-summary-${i}.csv $i
done

