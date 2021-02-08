#!/usr/bin/env python3

import os
import argparse
import csv
import json
from jsonschema import validate
import yaml

#-------------------------------------------------------------------------------
# Constants

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

#-------------------------------------------------------------------------------
# Utilities

def parse_yaml_file(schema_path):
    with open(schema_path) as sfile:
        return yaml.load(sfile, Loader=yaml.Loader)

def main(args):
    schema = parse_yaml_file(args.schema_file)
    metadata = parse_yaml_file(args.metadata_file)

    validate(instance=metadata, schema=schema)
    print('- [OK] %s was valid' % args.metadata_file)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='validate-cleaned-metadata')

    parser.add_argument(
        'schema_file',
        type=str,
        help='Schema to validate by'
    )

    parser.add_argument(
        'metadata_file',
        type=str,
        help='File to validate'
    )

    args = parser.parse_args()

    main(args)
