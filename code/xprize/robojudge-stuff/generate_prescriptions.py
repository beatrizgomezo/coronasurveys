"""
Reads the "prescription tasks" file locally (or from a locally visible remote mount). For each date pair (start date
and end date) requested, runs the designated prescription module, using the supplied interventions plan,
to generate the prescriptions.
"""

# Copyright 2021 (c) Cognizant Digital Business, Evolutionary AI. All rights reserved. Issued under the Apache 2.0 License.
# Modified for Coronasurveys by Davide Frey davide.frey@inria.fr 
import argparse
import logging
import os
import subprocess
from os.path import isfile, expanduser

import pandas as pd
from pandas import DataFrame

logging.basicConfig(
    format='%(asctime)s %(name)-20s %(levelname)-8s %(message)s',


def get_prescriptions_tasks(requested_prescriptions_file):
    """
    Reads the file containing the list of prescriptions to be generated.
    :param requested_prescriptions_file: Path to the CSV file containing the prescriptions to be generated
    :return: A Pandas DataFrame containing the prescriptions to be generated, one row per requested prescription
    """
    # Don't want to parse dates here as we'll be sending them as strings to the spawned process command line
    return pd.read_csv(
        requested_prescriptions_file,
        encoding="ISO-8859-1"
    )


def do_main():
    """
    Main line for this module
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--requested-prescriptions-file",
                        dest="requested_prescriptions_file",
                        type=str,
                        required=True,
                        help="Path to the filename containing dates for prescriptions to be generated, IP costs and "
                             "requested output files.")
    parser.add_argument("-p", "--prescription-module",
                        dest="prescription_module",
                        type=str,
                        required=True,
                        help="Path to the python script that should be run to generate prescriptions. According to the "
                             "API conversion this script should be named prescribe.py")
    parser.add_argument("-v", "--validation-module",
                        dest="validation_module",
                        type=str,
                        required=True,
                        help="Path to the python script that should be run to validate prescriptions. Any errors found "
                             "in the prescriptions will be written to stdout")
    args = parser.parse_args()

    LOGGER.info(f'Generating prescriptions from file {args.requested_prescriptions_file}')
    requested_prescriptions_df = get_prescriptions_tasks(args.requested_prescriptions_file)
    generate_prescriptions(requested_prescriptions_df, args.prescription_module, args.validation_module)


if __name__ == '__main__':
    do_main()
