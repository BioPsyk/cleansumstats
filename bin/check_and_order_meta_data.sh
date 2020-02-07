#!/usr/bin/env bash

cat <(head -n1 ${1}) <(cat ${2})

