import os
import logging

from time import time, strftime, localtime
from datetime import datetime, timedelta


def named_log(loggerName):

    logdir = os.path.expanduser('~/work/logs')
    try:
        os.makedirs(logdir, exist_ok=True)
    except OSError:
        print(f'Creation of log directory {logdir} failed')
    #else:
    #    print(f'CoronaSurveys log directory {logdir}')

    datefile = 'coronasurveys-{:%Y-%m-%d}.log'.format(datetime.now())

    logging.basicConfig(
        filename=os.path.join(logdir, datefile),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        level=logging.DEBUG,
        datefmt='%Y-%m-%d %H:%M:%S')

    return logging.getLogger(loggerName)


def secondsToStr(elapsed=None):

    if elapsed is None:
        return strftime("%Y-%m-%d %H:%M:%S", localtime())
    else:
        return str(timedelta(seconds=elapsed))

