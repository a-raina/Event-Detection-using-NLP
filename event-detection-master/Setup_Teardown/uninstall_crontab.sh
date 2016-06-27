#!/usr/bin/env bash
working_dir="$(pwd)/"
[ "$(ls ${working_dir} | grep 'Setup_Teardown')" == "" ] && working_dir="${working_dir}../"
java_path="$(which java)"
line="$java_path -jar ${working_dir}pipeline.jar ${working_dir}configuration.json"
(crontab -l 2>/dev/null | grep -v 'pipeline\.jar') | crontab -
