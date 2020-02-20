#!/usr/bin/env bash

FILE_PATH_1=${1}

awk 'NR == FNR {count[$1]++; next} count[$1] == 1' ${FILE_PATH_1} ${FILE_PATH_1} 

