#/bin/bash

python prescribe.py -s "2021-02-06" -e "2021-02-28" -ip ./data/IPS-latest-full.csv -c ./data/fixed_equal_costs.csv -o ../../data/xprize/2021-02-06-prescribe.csv

#python standard_predictor/predict.py -s "2021-02-06" -e "2021-02-28" -ip ./data/IPS-latest-full.csv -o ../../data/xprize/2021-02-06-predict0.csv
