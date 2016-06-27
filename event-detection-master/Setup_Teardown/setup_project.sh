#!/usr/bin/env bash
working_dir="$(pwd)/"
[ "$(ls ${working_dir} | grep 'Setup_Teardown')" == "" ] && working_dir="${working_dir}../"
libs_dir="${working_dir}../"
semilar_dir="${libs_dir}SEMILAR/"
key_library="postgresql-9.4.1207.jar"

[ "$(python --version 2>&1 | grep 'Python 3')" != "" ] && python_path="$(which python)" || python_path="$(which python3)"

if [ "$(which brew)" != "" ] && [ "$(which brew)" != "brew not found" ]; then
	brew update
	brew tap 'toberumono/tap'
	brew install 'toberumono/tap/utils' 'toberumono/tap/structures' 'toberumono/tap/lexer' 'toberumono/tap/json-library' 'ant' 'wget' 'postgresql'
	if [ "$python_path" == "" ]; then
		read -p "Unable to find a Python 3 installation.  Would you like it to be installed? [y/N]" yn
		yn=$(echo "${yn:0:1}" | tr '[:upper:]' '[:lower:]')
		if [ "$yn" != "y" ]; then
			>&2 echo "Error: Unable to find the executable for python 3."
			echo "Please install Python 3 before running this script."
			exit 1
		else
			echo "Beginning to install Python 3.  This may take a bit."
			brew install 'python3'
		fi
		unset yn
	fi
else
	if [ "$python_path" == "" ]; then
		>&2 echo "Error: Unable to find the executable for python 3."
		exit 1
	fi
	cd "${libs_dir}"
	git clone "https://github.com/Toberumono/JSON-library.git"
	cd 'JSON-library'
	git checkout "$(git describe --tags)"
	./build_brewless.sh
	cd "$working_dir"
fi

pip3 install 'beautifulsoup4' 'grip' 'nltk' 'psycopg2' 'scipy' 'sendgrid' 'sklearn' 'twilio' 'requests'
$python_path -m nltk.downloader 'averaged_perceptron_tagger' 'punkt' 'stopwords' 'tagsets' 'treebank' 'wordnet' 'wordnet_ic'

export PGDATA="$(brew --prefix)/var/postgres"
export PGHOST=localhost
[ "$(pg_ctl status | grep 'PID:' )" == "" ] && setup_sql=true || setup_sql=false
[ -e "${libs_dir}${key_library}" ] && download_libs=false || download_libs=true
[ -e "${libs_dir}repackaged-stanford-corenlp.jar" ] && repackage_corenlp=false || repackage_corenlp=true

while getopts s:d:r: opt; do
  case $opt in
  s)
      [ "$OPTARG" == "true" ] && setup_sql=true || setup_sql=false
      ;;
  d)
      [ "$OPTARG" == "true" ] && download_libs=true || download_libs=false
      ;;
  r)
      [ "$OPTARG" == "true" ] && repackage_corenlp=true || repackage_corenlp=false
      ;;
  esac
done

shift $((OPTIND - 1))

echo '----------------Downloading Downloader Dependencies-------------------'
if ( $download_libs ); then
	wget '-N' '--directory-prefix='"${libs_dir}" 'http://central.maven.org/maven2/com/rometools/rome-utils/1.5.1/rome-utils-1.5.1.jar'
	wget '-N' '--directory-prefix='"${libs_dir}" 'http://central.maven.org/maven2/com/rometools/rome/1.5.1/rome-1.5.1.jar'
	wget '-N' '--directory-prefix='"${libs_dir}" 'http://central.maven.org/maven2/org/jdom/jdom2/2.0.6/jdom2-2.0.6.jar'
	wget '-N' '--directory-prefix='"${libs_dir}" 'http://central.maven.org/maven2/org/slf4j/slf4j-api/1.7.12/slf4j-api-1.7.12.jar'
	wget '-N' '--directory-prefix='"${libs_dir}" 'http://central.maven.org/maven2/org/slf4j/slf4j-simple/1.7.12/slf4j-simple-1.7.12.jar'
	wget '-N' '--directory-prefix='"${libs_dir}" 'http://nlp.stanford.edu/software/stanford-corenlp-full-2015-12-09.zip'
	wget '-N' '--directory-prefix='"${semilar_dir}" 'http://deeptutor2.memphis.edu/Semilar-Web/public/downloads/SEMILAR-API-1.0.zip'
	unzip '-u' "${libs_dir}"'stanford-corenlp-full-2015-12-09' '-d' "${libs_dir}"
	wget '-N' '--directory-prefix='"${libs_dir}" "https://jdbc.postgresql.org/download/${key_library}"
else
	echo "Skipping."
fi

echo '-------------------Setting Up SEMILAR Libraries----------------------'
if ( $download_libs ); then
	unzip '-u' '../SEMILAR/SEMILAR-API-1.0' '-d' '../SEMILAR/'
fi

if ( $repackage_corenlp ); then
	cp "${semilar_dir}SEMILAR-API-1.0/stop-words.txt" "${working_dir}stop-words.txt"
	cp -R "${semilar_dir}SEMILAR-API-1.0/WordNet-JWI" "${working_dir}WordNet-JWI"
	unzip '-u' "${semilar_dir}"'SEMILAR-API-1.0/Semilar-1.0.jar' '-d' "${semilar_dir}"'SEMILAR-API-1.0/Semilar-1.0'
	perl -i -p0e $'s/Class-Path:.* \\.0\\.jar/Class-Path: lib\/joda-time.jar lib\/xom.jar lib\/opennlp-tools-1.5.0.jar \n lib\/edu.mit.jwi_2.1.5.jar lib\/jwnl-1.3.3.jar lib\/maxent-3.0.0.jar/smg' '../SEMILAR/SEMILAR-API-1.0/Semilar-1.0/META-INF/MANIFEST.MF'
	jar cfm "${semilar_dir}"'SEMILAR-API-1.0/Semilar-1.0.jar' "${semilar_dir}"'SEMILAR-API-1.0/Semilar-1.0/META-INF/MANIFEST.MF' -C "${semilar_dir}"'SEMILAR-API-1.0/Semilar-1.0/' '.'
	ant -buildfile "$(pwd)/Setup_Teardown/repackage-corenlp.xml"
fi
if ( $download_libs ); then
	rm "${semilar_dir}"'SEMILAR-API-1.0.zip'
	rm -r "${semilar_dir}"'SEMILAR-API-1.0/Semilar-1.0'
	rm "${libs_dir}"'stanford-corenlp-full-2015-12-09.zip'
fi

echo '------------------Setting Up PostgreSQL Database---------------------'
if ( $setup_sql ); then
	initdb "$(brew --prefix)/var/postgres"
	mkdir -p "$HOME/Library/LaunchAgents"
	ln -sfv "$(brew --prefix)"/opt/postgresql/*.plist "$HOME/Library/LaunchAgents"
	[ "$(pg_ctl status | grep 'PID:' )" == "" ] && ( pg_ctl start > /dev/null ) && createdb event_detection || createdb event_detection
	psql event_detection < "$(pwd)/Setup_Teardown/setup.sql"
	psql event_detection < "$(pwd)/Setup_Teardown/seeds.sql"
else
	echo "Skipping."
fi

echo '------------------Generating Eclipse User Libraries------------------'
. "$(pwd)/Setup_Teardown/generate_userlibs.sh"
