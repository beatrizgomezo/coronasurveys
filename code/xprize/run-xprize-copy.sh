#/bin/bash


# Run the predictions for each prescriptor

for i in 0 1 2 3 4 5 6 7 8 9
do
 
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

