# Copyright 2020 (c) Cognizant Digital Business, Evolutionary AI. All rights reserved. Issued under the Apache 2.0 License.

import os
import sys
import math
import subprocess
import tempfile
import urllib.request
import numpy as np
import pandas as pd
from pathlib import Path

ups = '/..' * 2
root_path = os.path.dirname(os.path.realpath(__file__)) + ups
sys.path.append(root_path)

from .scenario_generator import get_raw_data, generate_scenario
from standard_predictor.predict import predict

# Path to where this script lives
ROOT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))

# Data directory (we will download the Oxford data to here)
DATA_PATH = ROOT_DIR.parent

# URL for Oxford data
DATA_URL = Path(DATA_PATH) / 'OxCGRT_latest.csv'

# Path to Oxford data file
HIST_DATA_FILE_PATH = Path(DATA_PATH) / 'OxCGRT_latest.csv'

NB_LOOKBACK_DAYS = 21

# Path to predictor module
PREDICT_MODULE = ROOT_DIR.parent / 'standard_predictor' / 'predict.py'

POPULATION_FILE = ROOT_DIR.parent / 'population.csv'

CASES_COL = ['ConfirmedCases', 'ConfirmedDeaths', 'GeoID', 'population',
             'CountryName', 'RegionName', 'CountryCode', 'Date']

PRED_CASES_COL = ['PredictedDailyNewCases']

UNDOT = True


def undot_dict(list):
    return list if not UNDOT else {key.replace('.', ' '): list[key] for key in list.keys()}


def undot(list):
    return list if not UNDOT else [item.replace('.', ' ') for item in list]


def _dot(list):
    return [item.replace(' ', '.') for item in list]


IP_COLS = undot(['C1_School.closing',
           'C2_Workplace.closing',
           'C3_Cancel.public.events',
           'C4_Restrictions.on.gatherings',
           'C5_Close.public.transport',
           'C6_Stay.at.home.requirements',
           'C7_Restrictions.on.internal.movement',
           'C8_International.travel.controls',
           'H1_Public.information.campaigns',
           'H2_Testing.policy',
           'H3_Contact.tracing',
           'H6_Facial.Coverings'])

IP_MAX_VALUES = undot_dict({
    'C1_School.closing': 3,
    'C2_Workplace.closing': 3,
    'C3_Cancel.public.events': 2,
    'C4_Restrictions.on.gatherings': 4,
    'C5_Close.public.transport': 2,
    'C6_Stay.at.home.requirements': 3,
    'C7_Restrictions.on.internal.movement': 2,
    'C8_International.travel.controls': 4,
    'H1_Public.information.campaigns': 2,
    'H2_Testing.policy': 3,
    'H3_Contact.tracing': 2,
    'H6_Facial.Coverings': 4
})


def policy(prescribed_ips, costs):
    if np.sum(prescribed_ips) <= len(prescribed_ips):
        return prescribed_ips

    schools_col = 0
    workplaces_col = 1
    public_events_col = 2
    gatherings_col = 3
    transport_col = 4
    stay_at_home_col = 5

    costs = costs.squeeze()[-1]

    if prescribed_ips[stay_at_home_col] >= 1:  # == IP_MAX_VALUES[IP_COLS[stay_at_home_col]]:
        schools_col_key = IP_COLS[schools_col]
        workplaces_col_key = IP_COLS[workplaces_col]
        public_events_col_key = IP_COLS[public_events_col]
        gatherings_col_key = IP_COLS[gatherings_col]

        prescribed_ips[schools_col] = min(max(IP_MAX_VALUES[schools_col_key] // math.ceil(costs[schools_col]), 1),
                                          prescribed_ips[schools_col])  # 0
        prescribed_ips[workplaces_col] = min(max(IP_MAX_VALUES[workplaces_col_key] // math.ceil(costs[workplaces_col]),
                                                 1), prescribed_ips[workplaces_col])  # 0
        prescribed_ips[public_events_col] = min(max(IP_MAX_VALUES[public_events_col_key] //
                                                    math.ceil(costs[public_events_col]), 1),
                                          prescribed_ips[public_events_col])  # 0
        prescribed_ips[gatherings_col] = min(max(IP_MAX_VALUES[gatherings_col_key] // math.ceil(costs[gatherings_col]), 1),
                                          prescribed_ips[gatherings_col])  # 0

    sorted_costs_idx = costs.argsort()[::-1]
    range_ = costs[sorted_costs_idx[0]] - costs[sorted_costs_idx[-1]]
    min_ = .1 * range_ + costs[sorted_costs_idx[-1]]
    middle = .5 * range_ + costs[sorted_costs_idx[-1]]
    max_ = .9 * range_ + costs[sorted_costs_idx[-1]]
    # print(costs, min_, middle, max_)

    for i, ip in enumerate(IP_COLS):
        if costs[i] <= min_:
            prescribed_ips[i] = max(min(IP_MAX_VALUES[ip], IP_MAX_VALUES[ip] // (1 if costs[i] == 0 else
                                                                                 math.ceil(costs[i])) + 1),
                                    prescribed_ips[i])
        elif costs[i] <= middle:
            prescribed_ips[i] = min(IP_MAX_VALUES[ip] // (math.ceil(costs[i]) + 1), prescribed_ips[i])
        elif costs[i] >= max_:
            prescribed_ips[i] = min(max(0, IP_MAX_VALUES[ip] // (1 if costs[i] == 0 else
                                                                 math.ceil(costs[i])) - 1), prescribed_ips[i])
        else:
            if prescribed_ips[i] == IP_MAX_VALUES[ip]:
                prescribed_ips[i] = min(max(0, IP_MAX_VALUES[ip] // (1 if costs[i] == 0 else
                                                                     math.ceil(costs[i])) - 1),
                                        prescribed_ips[i] // (1 if costs[i] == 0 else
                                                              math.ceil(costs[i])))
            elif prescribed_ips[i] > 0:
                prescribed_ips[i] = min(max(0, IP_MAX_VALUES[ip] // (1 if costs[i] == 0 else
                                                                     math.ceil(costs[i])) - 1), prescribed_ips[i] - 1)

    return prescribed_ips


def add_geo_id(df):
    df["GeoID"] = np.where(df["RegionName"].fillna('').str.len() == 0,
                           df["CountryName"],
                           df["CountryName"] + ' / ' + df["RegionName"])
    return df


# Function that performs basic loading and preprocessing of historical df
def prepare_historical_df():
    # Download data if it we haven't done that yet.
    if not os.path.exists(HIST_DATA_FILE_PATH):
        if not os.path.exists(DATA_PATH):
            os.makedirs(DATA_PATH)
        urllib.request.urlretrieve(DATA_URL, HIST_DATA_FILE_PATH)

    # Load raw historical data
    df = pd.read_csv(HIST_DATA_FILE_PATH,
                     parse_dates=['Date'],
                     encoding="ISO-8859-1",
                     error_bad_lines=False)
    df['RegionName'] = df['RegionName'].fillna("")

    # Add GeoID column for easier manipulation
    df = add_geo_id(df)

    # Add new cases column
    df['NewCases'] = df.groupby('GeoID').ConfirmedCases.diff().fillna(0)

    # Fill any missing case values by interpolation and setting NaNs to 0
    df.update(df.groupby('GeoID').NewCases.apply(
        lambda group: group.interpolate()).fillna(0))

    # Fill any missing IPs by assuming they are the same as previous day
    for ip_col in IP_MAX_VALUES:
        df.update(df.groupby('GeoID')[ip_col].ffill().fillna(0))

    return df


# Function to load an IPs file, e.g., passed to prescribe.py
def load_ips_file(path_to_ips_file):
    df = pd.read_csv(path_to_ips_file,
                     parse_dates=['Date'],
                     encoding="ISO-8859-1",
                     error_bad_lines=False)
    df['RegionName'] = df['RegionName'].fillna("")
    df = add_geo_id(df)
    return df


# Function that wraps predictor in order to query
# predictor when prescribing.
def get_predictions(start_date_str, end_date_str, pres_df, countries=None):
    # Concatenate prescriptions with historical data
    countries = [c.replace("__", "") for c in countries]

    raw_df = get_raw_data(HIST_DATA_FILE_PATH)
    hist_df = generate_scenario(start_date_str, end_date_str, raw_df,
                                countries=countries, scenario='Historical')
    start_date = pd.to_datetime(start_date_str, format='%Y-%m-%d')
    hist_df = hist_df[hist_df.Date < start_date_str]
    ips_df = pd.concat([hist_df, pres_df])

    with tempfile.NamedTemporaryFile() as tmp_ips_file:
        # Write ips_df to file
        ips_df.to_csv(tmp_ips_file.name, index=False)

        with tempfile.NamedTemporaryFile() as tmp_pred_file:
            # Run script to generate predictions
            try:
                predict(start_date_str, end_date_str, tmp_ips_file.name, tmp_pred_file.name)
                """
                output_str = subprocess.check_output(
                    [
                        'conda activate xprize',
                        'conda activate xprize',
                        'conda activate xprize',
                        'python', str(PREDICT_MODULE) + \
                        ' --start_date ' + start_date_str + \
                        ' --end_date ' + end_date_str + \
                        ' --interventions_plan ' + tmp_ips_file.name + \
                        ' --output_file ' + tmp_pred_file.name
                    ],
                    stderr=subprocess.STDOUT
                )

                # Print output from running script
                print(output_str.decode("utf-8"))
                """
            except Exception as e:
                print(e)

            # Load predictions to return
            df = pd.read_csv(tmp_pred_file.name)

    return df
