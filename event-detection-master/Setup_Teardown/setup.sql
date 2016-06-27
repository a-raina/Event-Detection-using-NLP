CREATE USER root with SUPERUSER CREATEDB CREATEROLE INHERIT;

CREATE TABLE IF NOT EXISTS sources (
	id serial primary key unique not null,
	source_name varchar(255) unique not null,
	reliability real default 1.0,
	check (reliability >= 0.0 and reliability <= 1.0)
);

CREATE TABLE IF NOT EXISTS feeds (
	id serial primary key unique not null,
	feed_name varchar(255) unique not null,
	source integer not null references sources(id) ON DELETE CASCADE,
	url text unique not null,
	scrapers text[] default '{}',
	lastseen text default null
);

CREATE TABLE IF NOT EXISTS articles (
	id serial primary key unique not null,
	title varchar(255) not null,
	source integer not null references sources(id) ON DELETE CASCADE,
	url text unique not null,
	filename text default null,
	keywords text default null
);

CREATE TABLE IF NOT EXISTS users (
	id serial primary key unique not null,
	phone varchar(32) default null,
	email text default null,
	constraint unique_users unique (phone, email)
);

CREATE TABLE IF NOT EXISTS queries (
	id serial primary key unique not null,
	userid integer not null references users(id) ON DELETE CASCADE,
	subject varchar(255) not null default '',
	verb varchar(255) not null default '',
	direct_obj varchar(255) not null default '',
	indirect_obj varchar(255) not null default '',
	loc varchar(255) not null default '',
	processed boolean default false,
	constraint unique_queries unique (userid, subject, verb, direct_obj, indirect_obj, loc)
);

CREATE TABLE IF NOT EXISTS query_words (
	query integer references queries(id) ON DELETE CASCADE,
	word varchar(255) not null,
	pos varchar(255) not null,
	sense varchar(255) default '',
	synonyms varchar(255)[] default '{}',
	primary key (query, word, pos, sense),
	constraint word_pos unique(query, word, pos)
);

CREATE TABLE IF NOT EXISTS query_articles (
	query integer references queries(id) ON DELETE CASCADE,
	article integer references articles(id) ON DELETE CASCADE,
	accuracy real default 0.0,
	processed boolean default false,
	notification_sent boolean default false,
	primary key (query, article)
);

CREATE TYPE validator_type AS ENUM ('OneToOne', 'OneToMany', 'ManyToOne', 'ManyToMany', 'QueryOnly', 'ArticleOnly'); --This corresponds to ValidatorType in the Java code.

CREATE TABLE IF NOT EXISTS validation_algorithms (
	id serial primary key unique not null,
	algorithm varchar(255) unique not null,
	base_class text not null,
	validator_type validator_type not null default 'OneToOne',
	threshold real not null default 0.50,
	parameters jsonb default null,
	enabled boolean not null default true
);

CREATE TABLE IF NOT EXISTS validation_results (
	query integer references queries(id) ON DELETE CASCADE,
	algorithm integer references validation_algorithms(id) ON DELETE CASCADE,
	article integer references articles(id) ON DELETE CASCADE,
	validates real default 0.0 not null CHECK (validates >= 0.0 and validates <= 1.0),
	invalidates real default null CHECK (invalidates is null or (invalidates >= 0.0 and invalidates <= 1.0)),
	primary key (query, algorithm, article)
);

CREATE OR REPLACE FUNCTION generate_invalidates() RETURNS trigger as $generate_invalidates$
	BEGIN
		IF NEW.invalidates is null THEN
			NEW.invalidates := 1 - NEW.validates;
		END IF;
		RETURN NEW;
	END;
$generate_invalidates$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS generate_invalidates on validation_results;
CREATE TRIGGER generate_invalidates BEFORE INSERT OR UPDATE on validation_results
	FOR EACH ROW EXECUTE PROCEDURE generate_invalidates();

CREATE OR REPLACE FUNCTION make_empty_string() RETURNS trigger as $make_empty_string$
	BEGIN
		IF NEW.subject is null THEN
			NEW.subject := '';
		END IF;
		IF NEW.verb is null THEN
			NEW.verb := '';
		END IF;
		IF NEW.direct_obj is null THEN
			NEW.direct_obj := '';
		END IF;
		IF NEW.indirect_obj is null THEN
			NEW.indirect_obj := '';
		END IF;
		IF NEW.loc is null THEN
			NEW.loc := '';
		END IF;
		RETURN NEW;
	END;
$make_empty_string$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS make_empty_string on queries;
CREATE TRIGGER make_empty_string BEFORE INSERT OR UPDATE on queries
	FOR EACH ROW EXECUTE PROCEDURE make_empty_string();
