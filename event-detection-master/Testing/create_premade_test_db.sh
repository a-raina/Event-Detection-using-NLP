createdb event_detection_test
sed -i .bak -e 's/username-to-replace/'$(whoami)'/g' test_database.sql && rm test_database.sql.bak
psql event_detection_test < test_database.sql
