import sys
import os
import argparse
import subprocess
import re
import time

sys.path.append(os.path.expanduser("~/work/logger"))
import utils

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

    rScriptFile, ext = os.path.splitext(sys.argv[0])
    rScriptFile += ".R"

    log_name = "default"
    matches = re.findall(r'/(prescribe\d+)', os.path.dirname(os.path.realpath(__file__)))
    if len(matches) > 0:
        log_name = matches[0]

    logger = utils.named_log(str(log_name))

    rScriptFile, ext = os.path.splitext(sys.argv[0])
    rScriptFile += ".R"

    try:
        r_cmd = [
            "Rscript",
            "--vanilla",
            rScriptFile,
            args.start_date,
            args.end_date,
            os.path.expanduser(args.prior_ips_file),
            os.path.expanduser(args.cost_file),
            os.path.expanduser(args.output_file),
            os.path.dirname(os.path.realpath(__file__))
        ]

        logger.info("R command: " + ' '.join(r_cmd))

        subprocess.call(r_cmd)
    except OSError as error:
        logger.info(error)
    except:
        logger.info("Unexpected error: %s", sys.exc_info()[0])
        raise
    else:
        logger.info("Successfully executed %s", os.path.realpath(__file__))

    logger.info("Duration: %s seconds", utils.secondsToStr(time.time() - start))