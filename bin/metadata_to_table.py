#!/usr/bin/env python3

import os
import logging
import argparse
import re
import csv
import sys

#-------------------------------------------------------------------------------
# Constants

SCRIPT_NAME  = 'metadata_to_table'
SCRIPT_PATH  = os.path.abspath(__file__)
BIN_DIR      = os.path.dirname(SCRIPT_PATH)
LINE_REGEXP  = re.compile(
  '^(?P<pad>[ ]*)(?P<bullet>- )?((?P<key>\$?[a-zA-Z0-9_-]+):)? *(?P<val>.*)$'
)
VALUE_REGEXP = re.compile('^["\']?(?P<val>[^"\']+)["\']?$')

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
"""Parser/generator for YAML."""

#-------------------------------------------------------------------------------
# Helpers

def get_by_keys(tree, keys):
  """Gets the member deep in the given tree, using the given key path."""

  if len(keys) == 0:
    return None

  if len(keys) == 1:
    try:
      return tree[keys[0]]
    except KeyError:
      return None

  next_key  = keys[0]
  rest_keys = keys[1:]

  return get_by_keys(tree[next_key], rest_keys)

def set_by_keys(tree, keys, val):
  """Sets value of the member deep in the given tree, using the given key path."""

  if not isinstance(tree, dict) and not isinstance(tree, list):
    raise TypeError(f'Given tree was not a dict or list: "{tree}"')

  if len(keys) == 0:
    return False

  if len(keys) == 1:
    tree[keys[0]] = val
    return True

  next_key  = keys[0]
  rest_keys = keys[1:]

  return set_by_keys(tree[next_key], rest_keys, val)

def cacl_curr_yaml_level(pad, pads_per_level):
  """Calculates current level from given pad and the amount of pad glyphs per level."""

  if pads_per_level is None:
    return 0

  return int(len(pad) / pads_per_level)

def extract_yaml_value(literal):
  """Moves quotes from around the given string value."""

  if literal.startswith('[') and literal.endswith(']'):
    items = literal[1:-1].split(',')

    return list(
      map(lambda x: extract_yaml_value(x.strip()), items)
    )

  match = VALUE_REGEXP.match(literal)

  if match is None:
    raise ValueError(f'Could not extract value: "{literal}"')

  groups = match.groupdict()

  value = groups['val'].strip()

  if value == '[]':
    return []

  if value in ['True', 'yes']:
    return True

  if value in ['False', 'no']:
    return False

  if value.isdigit():
    return int(value)

  try:
    return float(value)
  except ValueError:
    return value

def parse_yaml(literal):
  """Parses given YAML literal into a dict."""

  results          = {}
  keys             = []
  pads_per_level   = None
  prev_level       = 0
  inside_multiline = False

  for index, line in enumerate(literal.split('\n')):
    if line == '' or line.startswith('#'):
      continue

    match = LINE_REGEXP.match(line)

    if match is None:
      raise ValueError(f'Invalid YAML line found ({index}): "{line}"')

    groups = match.groupdict()

    pad    = groups['pad']
    bullet = groups['bullet']
    key    = groups['key']
    val    = groups['val']

    if val.startswith("#"):
      continue

    if pad != '' and pads_per_level is None:
      if len(keys) == 0:
        raise ValueError(f'Found indentation before parent (line {index}): "{line}"')

      pads_per_level = len(pad)

    curr_level = cacl_curr_yaml_level(pad, pads_per_level)

    if not inside_multiline and curr_level - prev_level > 1:
      raise ValueError(
        f'Unbalanced levels on line {index} ({prev_level} {curr_level}): {line}'
      )

    if curr_level < prev_level:
      inside_multiline = False

    keys = keys[:curr_level]

    if inside_multiline:
      prev_val = get_by_keys(results, keys)
      next_val = f'{prev_val}\n{val}'

      set_by_keys(results, keys, next_val)
    elif bullet is not None and (key == '' or key is None):
      val    = extract_yaml_value(val)
      parent = get_by_keys(results, keys)

      if isinstance(parent, list):
        set_by_keys(results, keys, parent + [val])
      else:
        set_by_keys(results, keys, [val])
    elif bullet is not None:
      next_val = {}

      if val == '':
        next_val[key] = {}
      else:
        next_val[key] = extract_yaml_value(val)

      parent = get_by_keys(results, keys)

      if isinstance(parent, list):
        set_by_keys(results, keys, parent + [next_val])
        keys.append(len(parent))
      else:
        set_by_keys(results, keys, [next_val])
        keys.append(0)

      curr_level += 1
    elif val.strip() == '|':
      keys.append(key)
      set_by_keys(results, keys, '')

      inside_multiline = True
    elif val == '' or val is None:
      keys.append(key)
      set_by_keys(results, keys, {})
    else:
      set_by_keys(
        results,
        keys + [key],
        extract_yaml_value(val)
      )

    prev_level = curr_level

  return results

#-------------------------------------------------------------------------------
# Main tasks

def get_metadata_schema():
  schema_path = os.path.join(
    os.path.dirname(BIN_DIR),
    "assets/schemas/raw-metadata.yaml"
  )

  with open(schema_path, 'r') as f:
    return parse_yaml(f.read())

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
    contents = parse_yaml(f.read())
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
