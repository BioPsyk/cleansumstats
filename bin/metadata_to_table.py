#!/usr/bin/env python3

import os
import logging
import argparse
import re
import csv
import sys
import yaml

#-------------------------------------------------------------------------------
# Constants

SCRIPT_NAME  = 'metadata_to_table'
SCRIPT_PATH  = os.path.abspath(__file__)
BIN_DIR      = os.path.dirname(SCRIPT_PATH)

#-------------------------------------------------------------------------------
# Logger setup

logger = logging.getLogger(SCRIPT_NAME)
logger.setLevel(logging.DEBUG)

basic_formatter = logging.Formatter(
  '[%(levelname)s] %(message)s'
)

stream_handler = logging.StreamHandler()
stream_handler.setLevel(logging.INFO)

stream_handler.setFormatter(basic_formatter)
logger.addHandler(stream_handler)

#-------------------------------------------------------------------------------
# Main tasks

def get_metadata_schema():
  schema_path = os.path.join(
    os.path.dirname(BIN_DIR),
    "assets/schemas/raw-metadata.yaml"
  )

  with open(schema_path, 'r') as f:
    return yaml.load(f, Loader=yaml.Loader)

def main(args):
  schema = get_metadata_schema()
  writer = csv.DictWriter(
    sys.stdout,
    fieldnames=['metadata_dir'] + list(schema['properties'].keys()),
    quoting=csv.QUOTE_MINIMAL,
    extrasaction='ignore',
    lineterminator='\n',
    delimiter=args.delimiter,
    quotechar=args.quotechar
  )
  writer.writeheader()

  for f in args.metadata_files:
    contents = yaml.load(f, Loader=yaml.Loader)

    results  = {
      'metadata_dir': os.path.basename(
        os.path.dirname(os.path.realpath(f.name))
      )
    }

    for key, val in contents.items():
      if isinstance(val, list):
        val = ','.join(val)

      results[key] = val

    writer.writerow(results)

#-------------------------------------------------------------------------------

if __name__ == '__main__':
  parser = argparse.ArgumentParser(prog=SCRIPT_NAME)

  parser.add_argument(
    '--log_level',
    type=str,
    choices=['error', 'info', 'debug'],
    help='Controls the log level, "info" is default'
  )

  parser.add_argument(
    '--delimiter',
    type=str,
    default=',',
    help='Delimiter that separates columns, defaults to ,'
  )

  parser.add_argument(
    '--quotechar',
    type=str,
    default='"',
    help='Character to use when quoting columns, defaults to "'
  )

  parser.add_argument('metadata_files', type=argparse.FileType('r'), nargs='+')

  args = parser.parse_args()

  if args.log_level == 'debug':
    stream_handler.setLevel(logging.DEBUG)
  elif args.log_level == 'error':
    stream_handler.setLevel(logging.ERROR)

  main(args)
