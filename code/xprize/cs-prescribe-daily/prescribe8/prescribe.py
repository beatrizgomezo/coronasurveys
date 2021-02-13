# Copyright 2020 (c) Cognizant Digital Business, Evolutionary AI. All rights reserved. Issued under the Apache 2.0 License.

import argparse
import numpy as np
import pandas as pd

import os
import sys

sys.path.append(os.path.realpath(os.path.join(os.path.dirname(__file__), "..", "logger")))
import coronasurveys_utils

from pathlib import Path

from helpers.utils import IP_COLS, HIST_DATA_FILE_PATH
from helpers.train_prescriptor import Prescriptor

ups = '/..' * 2
root_path = os.path.dirname(os.path.realpath(__file__)) + ups
sys.path.append(root_path)
from standard_predictor.xprize_predictor import XPrizePredictor

import re
import time


ROOT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
MODEL_WEIGHTS_FILE = os.path.join(ROOT_DIR, "../standard_predictor/models", "trained_model_weights.h5")
DATA_FILE = HIST_DATA_FILE_PATH


def prescribe(start_date_str: str,
              end_date_str: str,
              path_to_hist_file: str,
              path_to_cost_file: str,
              output_file_path) -> None:

    start_date = pd.to_datetime(start_date_str, format='%Y-%m-%d')
    end_date = pd.to_datetime(end_date_str, format='%Y-%m-%d')

    prescriptor = Prescriptor(data_path=DATA_FILE, path_to_cost_file=path_to_cost_file,
                              start_date=start_date_str, end_date=end_date_str)

    df = prescriptor.df

    del prescriptor

    countries = df['CountryName'].unique()

    prescription_df = {
        'PrescriptionIndex': [],
        'CountryName': [],
        'RegionName': [],
        'Date': []
    }
    for npi_col in IP_COLS:
        prescription_df[npi_col] = []

    prescription_index = 8

    predictor = XPrizePredictor(MODEL_WEIGHTS_FILE, df=df).predictor
    for country_name in countries:
        cdf = df[df['CountryName'] == country_name]
        regions = cdf['RegionName'].fillna('').unique()
        for region_name in regions:
            geo_id = country_name + ('' if region_name == '' else ' / ' + region_name)

            prescriptor = Prescriptor(df=df, path_to_cost_file=path_to_cost_file, _predictor=predictor,
                                      start_date=start_date_str, end_date=end_date_str)
            prescriptor.set_countries([geo_id])
            if geo_id not in prescriptor.geo_costs:
                # print("costs not found for", geo_id)
                continue

            # print('Processing', geo_id)

            model, _ = prescriptor.trainer(geo_id)
            prescriptions, _ = prescriptor.predict(model, start_date_str, end_date_str, geo_id)
            prescriptions = list(np.int_(prescriptions[:, 1:]))

            for i, date in enumerate(pd.date_range(start_date, end_date)):
                prescription_df['PrescriptionIndex'].append(prescription_index)
                prescription_df['CountryName'].append(country_name)
                prescription_df['RegionName'].append(region_name)
                prescription_df['Date'].append(date.strftime("%Y-%m-%d"))
                for j, npi_col in enumerate(IP_COLS):
                    prescription_df[npi_col].append(prescriptions[i][j])

            del prescriptor
            del model

    prescription_df = pd.DataFrame(prescription_df)

    # Create the output path
    os.makedirs(os.path.dirname(output_file_path), exist_ok=True)

    # Save to a csv file
    prescription_df.to_csv(output_file_path, index=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--start_date",
                        dest="start_date",
                        type=str,
                        required=True,
                        help="Start date from which to prescribe, included, as YYYY-MM-DD."
                             "For example 2020-08-01")
    parser.add_argument("-e", "--end_date",
                        dest="end_date",
                        type=str,
                        required=True,
                        help="End date for the last prescription, included, as YYYY-MM-DD."
                             "For example 2020-08-31")
    parser.add_argument("-ip", "--interventions_past",
                        dest="prior_ips_file",
                        type=str,
                        required=True,
                        help="The path to a .csv file of previous intervention plans")
    parser.add_argument("-c", "--intervention_costs",
                        dest="cost_file",
                        type=str,
                        required=True,
                        help="Path to a .csv file containing the cost of each IP for each geo")
    parser.add_argument("-o", "--output_file",
                        dest="output_file",
                        type=str,
                        required=True,
                        help="The path to an intervention plan .csv file")
    args = parser.parse_args()

    start = time.time()

    log_name = "default"
    matches = re.findall(r'/(prescribe\d+)', os.path.dirname(os.path.realpath(__file__)))
    if len(matches) > 0:
        log_name = matches[0]

    logger = coronasurveys_utils.named_log(str(log_name), log_name)

    logger.info(f"Generating prescriptions from {args.start_date} to {args.end_date}...")

    try:
        prescribe(args.start_date, args.end_date, args.prior_ips_file, args.cost_file, args.output_file)

    except OSError as error:
        logger.info(error)
    except:
        logger.info("Unexpected error: %s", sys.exc_info()[0])
        raise
    else:
        logger.info("Successfully executed %s", os.path.realpath(__file__))

    print("Done!")
    logger.info("Duration: %s seconds", coronasurveys_utils.secondsToStr(time.time() - start))
