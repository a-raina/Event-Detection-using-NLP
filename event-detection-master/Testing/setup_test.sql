ALTER TABLE IF EXISTS query_articles ADD COLUMN validates boolean default false;
INSERT INTO sources (source_name, reliability) VALUES ('TEST_SOURCE', 1);
ALTER TABLE queries ADD COLUMN enabled boolean not null default true;
ALTER TABLE validation_algorithms ADD COLUMN enabled boolean not null default true;
