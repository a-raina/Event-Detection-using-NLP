#!/usr/bin/env bash
working_dir="$(pwd)/"
[ "$(ls ${working_dir} | grep 'Setup_Teardown')" == "" ] && working_dir="${working_dir}../"
java_path="$(which java)"
line="$java_path -jar ${working_dir}pipeline.jar ${working_dir}configuration.json"
line="0 * * * * $line"
read -p "Preparing to write: $line. Is this okay? [y/N] " yn
yn=$(echo "${yn:0:1}" | tr '[:upper:]' '[:lower:]')
if [ "$yn" != "y" ]; then
	echo "Stopping."
	exit 1
else
	echo "Writing."
fi
unset yn
(crontab -l 2>/dev/null; echo "$line") | crontab -
