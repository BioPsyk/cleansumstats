#!/usr/bin/env python3

import sys
import re
import os
import logging
import argparse
import json
import yaml
import jsonschema

#-------------------------------------------------------------------------------
# Constants

SCRIPT_NAME = 'metadata-legacy-to-yaml'
PROJECT_DIR = os.path.dirname(
    os.path.dirname(os.path.realpath(__file__))
)
SCHEMA_PATH = os.path.join(
    PROJECT_DIR, "assets", "schemas", "raw-metadata.yaml"
)


STUDY_PANELS = {
    '^HapMap.*': 'HapMap',
    '^HapMap2.*': 'HapMap2',
    '^HapMap3.*': 'HapMap3',
    '^1KGP.*': '1KGP',
    '^TOPMED.*': 'TOPMED',
    '^HRC.*': 'HRC',
    '^meta.*': 'meta'
}

STUDY_SOFTWARES = {
    '^plink.*': 'plink',
    '^impute.*': 'impute',
    '^impute2.*': 'impute2',
    '^impute3.*': 'impute3',
    '^shapeIt.*': 'shapeIt',
    '^shapeIt2.*': 'shapeIt2',
    '^shapeIt3.*': 'shapeIt3',
    '^shapeIt4.*': 'shapeIt4',
    '^shapeIt5.*': 'shapeIt5',
    '^MaCH.*': 'MaCH',
    '^Bealge.*': 'Beagle',
    '^Beagle.*': 'Beagle',
    '^Beagle1\.0.*': 'Beagle1.0',
    '^meta.*': 'meta'
}

CONVERSION_TABLE = {
    'study_ImputePanel': STUDY_PANELS,
    'study_ImputeSoftware': STUDY_SOFTWARES,
    'study_PhasePanel': STUDY_PANELS,
    'study_PhaseSoftware': STUDY_SOFTWARES,
    'study_Use': {
        'public': 'open',
        'private': 'restricted'
    },
    'stats_TraitType': {
        'qt': 'quantitative',
        'cc': 'case-control'
    },
    'stats_Model': {
        'lin': 'linear',
        'log': 'logistic'
    }
}


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


def convert_to_iso_date(metadata, key):
    if key not in metadata:
        return

    value = str(metadata[key])
    regexp = re.compile('^([0-9]{4})_?([0-9]{2})_?([0-9]{2})$')
    match = regexp.match(value)

    if match is None:
        logger.error(
            'Attribute "%s" could not be converted to ISO date: %s',
            key,
            value
        )
        sys.exit(1)

    metadata[key] = '%s-%s-%s' % match.groups()

def convert_to_list(metadata, key):
    if key not in metadata:
        return

    if not isinstance(metadata[key], list):
        metadata[key] = [metadata[key]]

def convert_enum_item(key, value):
    if key not in CONVERSION_TABLE:
        return None

    matrix = CONVERSION_TABLE[key]

    for regexp, replacement in matrix.items():
        match = re.compile(regexp).match(value)

        if match is not None:
            return replacement

    logger.error(
        'Could not translate attribute "%s" with the value "%s" using the matrix: %s',
        key,
        value,
        matrix
    )
    sys.exit(1)

def convert_enums(metadata):
    for key, matrix in CONVERSION_TABLE.items():
        if key not in metadata:
            continue

        values = metadata[key].split(',')
        results = []

        for value in values:
            converted = convert_enum_item(key, value)

            if converted is not None:
                results.append(converted)

        metadata[key] = results[0] if len(results) == 1 else results


def perform_specific_conversions(input_directory, schema, metadata):
    allowed_properties = schema['properties'].keys()

    results = {}

    for key, value in metadata.items():
        if key in allowed_properties and value != "missing":
            results[key] = value

    if 'study_Title' not in results:
        results['study_Title'] = input_directory

    if 'study_PhenoCode' in results:
        results['study_PhenoDesc'] = '%s (old phenocode: %s)' % (
            results['study_PhenoDesc'],
            results['study_PhenoCode']
        )

    results['study_PhenoCode'] = ['EFO:0000000']

    if 'study_Ancestry' in results:
        # Picks the first ancestry when multiple given
        results['study_Ancestry'] = results['study_Ancestry'].split(',')[0]

    convert_to_iso_date(results, 'cleansumstats_metafile_date')
    convert_to_iso_date(results, 'study_AccessDate')
    convert_to_list(results, 'path_supplementary')
    convert_enums(results)

    return results

def main(args):
    regexp = re.compile('^([a-zA-Z0-9_]+)=(.*)$')
    metadata = {}
    schema = None
    input_directory = os.path.basename(
        os.path.dirname(args.input_file)
    )

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

            # Creates a list for attributes that appear multiple times
            if not isinstance(metadata[key], list):
                metadata[key] = [metadata[key]]

            metadata[key].append(value)

    metadata = perform_specific_conversions(input_directory, schema, metadata)

# From merge conflict
#    print(json.dumps(metadata, indent=2))


    try:
        jsonschema.validate(instance=metadata, schema=schema)
    except jsonschema.exceptions.ValidationError as e:
        logger.error('json-schema validation failed with: %s', e.message)

        raise e
        sys.exit(1)

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
