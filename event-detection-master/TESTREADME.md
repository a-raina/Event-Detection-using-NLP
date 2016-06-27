# Testing

#### Getting data
1. Download the file `articles_test.zip` from data on the google drive and unzip in main directory
2. Download the database dump `test_backup.sql` from the google drive, replace "laura" with your username, then create a database `event_detection_test` and run `psql event_detection_test < test_backup.sql`

#### To get test results in database
1. Run `ant -Dprefix='./'`
1. Run `python3 Globals.py test`
1. Make sure the correct algorithms are enabled in your database
1. Run `java -jar validator.jar -c configuration_test.json`

#### Once results are stored in database
1. To test all enabled algorithms: `python3 Testing/Tester.py`
1. To bootstrap all enabled algorithms: `python3 Testing/Tester.py bootstrap`
1. To get best thresholds for all enabled algorithms: `python3 Testing/Tester.py thresholds`
1. To perform hypothesis tests for all enabled algorithms: `python3 Testing/Tester.py hypothesis`
1. There is also the option to use only general, specific, or negated queries. To do this, run the command as usual, but specify `-q specific`, `-q general` or `-q negated` at the end
