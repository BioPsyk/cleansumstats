#!/usr/bin/env python3

import sys
import re
import os
import logging
import argparse
import yaml
from jsonschema import validate

#-------------------------------------------------------------------------------
# Constants

SCRIPT_NAME = 'metadata-legacy-to-yaml'
PROJECT_DIR = os.path.dirname(
    os.path.dirname(os.path.realpath(__file__))
)
SCHEMA_PATH = os.path.join(
    PROJECT_DIR, "assets", "schemas", "raw-metadata.yaml"
)

#-------------------------------------------------------------------------------
# Logger setup

logger = logging.getLogger(SCRIPT_NAME)
logger.setLevel(logging.DEBUG)

basic_formatter = logging.Formatter(
    '[%(levelname)s] %(message)s'
)

stream_handler = logging.StreamHandler(sys.stderr)
stream_handler.setLevel(logging.INFO)

stream_handler.setFormatter(basic_formatter)
logger.addHandler(stream_handler)

#-------------------------------------------------------------------------------
# Main tasks

def try_type_cast(value):
    try:
        return int(value)
    except ValueError:
        pass

    try:
        return float(value)
    except ValueError:
        pass

    return value

def perform_specific_conversions(metadata):
    pass
    #if 'study_PhenoCode' not in metadata:
    #    metadata['study_PhenoCode'] = ['EFO:0000000']

def main(args):
    regexp = re.compile('^([a-zA-Z0-9_]+)=(.*)$')
    metadata = {}
    schema = None

    logger.info('Reading schema file %s', SCHEMA_PATH)

    with open(SCHEMA_PATH) as sfile:
        schema = yaml.load(sfile, Loader=yaml.Loader)

    logger.info('Reading input metadata %s', args.input_file)

    with open(args.input_file, 'r') as metadata_file:
        for line in metadata_file:
            match = regexp.match(line)

            if match is None:
                continue

            (key, value) = match.groups()

            value = try_type_cast(value)

            if key not in metadata:
                metadata[key] = value
                continue

            if not isinstance(metadata[key], list):
                metadata[key] = [metadata[key]]

            metadata[key].append(value)

    perform_specific_conversions(metadata)

    validate(instance=metadata, schema=schema)
    logger.info('Metadata file was successfully converted, writing results to stdout')
    print(yaml.dump(metadata))

#-------------------------------------------------------------------------------

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog=SCRIPT_NAME)

    parser.add_argument(
        'input_file',
        type=str,
        help='Path to the file to convert'
    )

    parser.add_argument(
        '--log_level',
        type=str,
        choices=['error', 'info', 'debug'],
        help='Controls the log level, "info" is default'
    )

    args = parser.parse_args()

    if args.log_level == 'debug':
        stream_handler.setLevel(logging.DEBUG)
    elif args.log_level == 'error':
        stream_handler.setLevel(logging.ERROR)

    main(args)
