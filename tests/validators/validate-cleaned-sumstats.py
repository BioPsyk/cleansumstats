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

int_columns = ['0', 'CHR', 'POS']

float_columns = [
    'P', 'SE', 'ORL95', 'ORU95', 'N', 'CaseN', 'ControlN',
    'INFO', 'B', 'Z', 'EAF', 'CaseEAF', 'ControlEAF', 'EAF_1KG'
]

def parse_sumstats_file(file_path):
    lines = []

    with open(file_path) as sfile:
        sreader = csv.reader(sfile, delimiter='\t')

        for line in sreader:
            lines.append(line)

    header = lines[0]
    rows = []

    for line in lines[1:]:
        row = {}

        for index, column in enumerate(line):
            column_name = header[index]
            try:
                if column_name in int_columns:
                    column = int(column)
                elif column_name in float_columns:
                    column = float(column)
            except ValueError:
                pass

            row[column_name] = column

        rows.append(row)

    return {
        'header': header,
        'rows': rows
    }

def parse_schema_file(schema_path):
    with open(schema_path) as sfile:
        return yaml.load(sfile, Loader=yaml.Loader)

def main(args):
    schema = parse_schema_file(args.schema_file)
    sumstats = parse_sumstats_file(args.sumstats_file)

    validate(instance=sumstats['rows'], schema=schema)
    print('- [OK] %s was valid' % args.sumstats_file)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='validate-cleaned-sumstats')

    parser.add_argument(
        'schema_file',
        type=str,
        help='Schema to validate by'
    )

    parser.add_argument(
        'sumstats_file',
        type=str,
        help='File to validate'
    )

    args = parser.parse_args()

    main(args)
