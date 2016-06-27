#!/usr/bin/env bash
if [[ $* == *test* ]]; then
    java -jar "$(pwd)/validator.jar" -c configuration_test.json
else
    java -jar "$(pwd)/pipeline.jar"
fi