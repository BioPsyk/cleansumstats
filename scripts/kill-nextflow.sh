#!/usr/bin/env bash

docker kill $(docker ps -q) 2> /dev/null || true
kill -9 $(ps aux | grep "nextflow.cli.Launcher" | head -n 1 | awk '{ print $2 }') 2> /dev/null || true
