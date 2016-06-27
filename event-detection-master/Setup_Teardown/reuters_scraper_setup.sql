INSERT INTO SOURCES (source_name, reliability) VALUES ('REUTERS', 1);
INSERT INTO feeds (feed_name, source, url, scrapers) values ('REUTERS_TOP_NEWS', (SELECT id FROM sources WHERE source_name = 'REUTERS'), 'http://feeds.reuters.com/reuters/topNews', '{"REUTERS"}');
