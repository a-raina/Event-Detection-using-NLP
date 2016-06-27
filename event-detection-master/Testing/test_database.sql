--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.1
-- Dumped by pg_dump version 9.5.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: validator_type; Type: TYPE; Schema: public; Owner: username-to-replace
--

CREATE TYPE validator_type AS ENUM (
    'OneToOne',
    'OneToMany',
    'ManyToOne',
    'ManyToMany',
    'QueryOnly',
    'ArticleOnly'
);


ALTER TYPE validator_type OWNER TO username-to-replace;

--
-- Name: generate_invalidates(); Type: FUNCTION; Schema: public; Owner: username-to-replace
--

CREATE FUNCTION generate_invalidates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		IF NEW.invalidates is null THEN
			NEW.invalidates := 1 - NEW.validates;
		END IF;
		RETURN NEW;
	END;
$$;


ALTER FUNCTION public.generate_invalidates() OWNER TO username-to-replace;

--
-- Name: make_empty_string(); Type: FUNCTION; Schema: public; Owner: username-to-replace
--

CREATE FUNCTION make_empty_string() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.make_empty_string() OWNER TO username-to-replace;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: articles; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE articles (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    source integer NOT NULL,
    url text NOT NULL,
    filename text,
    keywords text
);


ALTER TABLE articles OWNER TO username-to-replace;

--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: username-to-replace
--

CREATE SEQUENCE articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE articles_id_seq OWNER TO username-to-replace;

--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: username-to-replace
--

ALTER SEQUENCE articles_id_seq OWNED BY articles.id;


--
-- Name: feeds; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE feeds (
    id integer NOT NULL,
    feed_name character varying(255) NOT NULL,
    source integer NOT NULL,
    url text NOT NULL,
    scrapers text[] DEFAULT '{}'::text[],
    lastseen text
);


ALTER TABLE feeds OWNER TO username-to-replace;

--
-- Name: feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: username-to-replace
--

CREATE SEQUENCE feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE feeds_id_seq OWNER TO username-to-replace;

--
-- Name: feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: username-to-replace
--

ALTER SEQUENCE feeds_id_seq OWNED BY feeds.id;


--
-- Name: queries; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE queries (
    id integer NOT NULL,
    userid integer NOT NULL,
    subject character varying(255),
    verb character varying(255),
    direct_obj character varying(255),
    indirect_obj character varying(255),
    loc character varying(255),
    processed boolean DEFAULT false,
    enabled boolean DEFAULT true
);


ALTER TABLE queries OWNER TO username-to-replace;

--
-- Name: queries_id_seq; Type: SEQUENCE; Schema: public; Owner: username-to-replace
--

CREATE SEQUENCE queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE queries_id_seq OWNER TO username-to-replace;

--
-- Name: queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: username-to-replace
--

ALTER SEQUENCE queries_id_seq OWNED BY queries.id;


--
-- Name: query_articles; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE query_articles (
    query integer NOT NULL,
    article integer NOT NULL,
    accuracy real DEFAULT 0.0,
    processed boolean DEFAULT false,
    validates boolean DEFAULT false
);


ALTER TABLE query_articles OWNER TO username-to-replace;

--
-- Name: query_words; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE query_words (
    query integer NOT NULL,
    word character varying(255) NOT NULL,
    pos character varying(255) NOT NULL,
    sense character varying(255) DEFAULT ''::character varying NOT NULL,
    synonyms character varying(255)[] DEFAULT '{}'::character varying[]
);


ALTER TABLE query_words OWNER TO username-to-replace;

--
-- Name: sources; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE sources (
    id integer NOT NULL,
    source_name character varying(255) NOT NULL,
    reliability real DEFAULT 1.0,
    CONSTRAINT sources_reliability_check CHECK ((reliability <= (1.0)::double precision))
);


ALTER TABLE sources OWNER TO username-to-replace;

--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: username-to-replace
--

CREATE SEQUENCE sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sources_id_seq OWNER TO username-to-replace;

--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: username-to-replace
--

ALTER SEQUENCE sources_id_seq OWNED BY sources.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE users (
    id integer NOT NULL,
    phone character varying(32) DEFAULT NULL::character varying,
    email text
);


ALTER TABLE users OWNER TO username-to-replace;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: username-to-replace
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO username-to-replace;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: username-to-replace
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: validation_algorithms; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE validation_algorithms (
    id integer NOT NULL,
    algorithm character varying(255) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    base_class text NOT NULL,
    validator_type validator_type DEFAULT 'OneToOne'::validator_type NOT NULL,
    threshold real DEFAULT 0.50 NOT NULL,
    parameters jsonb
);


ALTER TABLE validation_algorithms OWNER TO username-to-replace;

--
-- Name: validation_algorithms_id_seq; Type: SEQUENCE; Schema: public; Owner: username-to-replace
--

CREATE SEQUENCE validation_algorithms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE validation_algorithms_id_seq OWNER TO username-to-replace;

--
-- Name: validation_algorithms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: username-to-replace
--

ALTER SEQUENCE validation_algorithms_id_seq OWNED BY validation_algorithms.id;


--
-- Name: validation_results; Type: TABLE; Schema: public; Owner: username-to-replace
--

CREATE TABLE validation_results (
    query integer NOT NULL,
    algorithm integer NOT NULL,
    article integer NOT NULL,
    validates real DEFAULT 0.0 NOT NULL,
    invalidates real,
    CONSTRAINT validation_results_invalidates_check CHECK (((invalidates IS NULL) OR ((invalidates >= (0.0)::double precision) AND (invalidates <= (1.0)::double precision)))),
    CONSTRAINT validation_results_validates_check CHECK (((validates >= (0.0)::double precision) AND (validates <= (1.0)::double precision)))
);


ALTER TABLE validation_results OWNER TO username-to-replace;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY articles ALTER COLUMN id SET DEFAULT nextval('articles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY feeds ALTER COLUMN id SET DEFAULT nextval('feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY queries ALTER COLUMN id SET DEFAULT nextval('queries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY sources ALTER COLUMN id SET DEFAULT nextval('sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY validation_algorithms ALTER COLUMN id SET DEFAULT nextval('validation_algorithms_id_seq'::regclass);


--
-- Data for Name: articles; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY articles (id, title, source, url, filename, keywords) FROM stdin;
90	Comet Catalina: Don't miss your only chance to see it	1	http://www.cbc.ca/news/technology/comet-catalina-1.3375283	90_1_Comet_Catalina__Don't_miss_your_only_chance_to_see_it.txt	{"VBZ": [["makes", 1.25]], "NNP": [["jan.", 1.0], ["comet", 1.6153846153846154], ["astronomical", 1.6], ["Comet Catalina", 4.0]], "VB": [["make", 1.25], ["miss", 1.0]], "VBG": [["making", 1.25]], "NN": [["only chance", 4.0], ["solar system", 4.0], ["comet", 1.6153846153846154], ["astronomer", 1.6]], "NNS": [["comets", 1.6153846153846154], ["astronomers", 1.6]]}
86	Obama visits Chicago to tout immigration action, cites Ferguson controversy	1	http://www.chicagotribune.com/news/ct-obama-chicago-visit-1126-20141125-story.html	86_1_Obama_visits_Chicago_to_tout_immigration_action,_cites_Ferguson_controversy.txt	{"NNS": [["protesters", 1.4], ["immigrants", 1.8181818181818181], ["nations", 1.25], ["protests", 1.4]], "NN": [["nation", 1.25], ["cites Ferguson controversy", 9.0], ["president", 1.5714285714285714], ["presidency", 1.5714285714285714], ["tout immigration action", 9.0], ["immigration", 1.8181818181818181]], "JJ": [["immigrant", 1.8181818181818181], ["national", 1.25]], "NNP": [["Obama visits Chicago", 9.0], ["president", 1.5714285714285714], ["emanuel", 1.5], ["obama", 1.8]]}
91	How to catch Comet Catalina in the night sky	1	http://globalnews.ca/news/2440063/how-to-catch-comet-catalina-in-the-night-sky/	91_1_How_to_catch_Comet_Catalina_in_the_night_sky.txt	{"VBZ": [["rises higher", 3.666666666666667]], "NNP": [["jan.", 1.0], ["catch Comet Catalina", 9.0], ["comet", 2.0], ["earth", 1.0], ["catalina", 2.0]], "VB": [["handle", 1.0], ["wait", 1.0], ["catch Comet Catalina", 9.0]], "RB": [["however", 1.0]], "NN": [["night sky", 8.4], ["comet", 2.0], ["week", 1.0], ["star", 1.75]], "NNS": [["weeks", 1.0]], "JJ": [["east", 1.0]], "VBP": [["handle", 1.0]]}
92	Rihanna's new album ANTI is available now	1	http://www.theverge.com/2016/1/27/9075439/rihanna-anti-new-album-tidal-available-now	92_1_Rihanna's_new_album_ANTI_is_available_now.txt	{"VB": [["make", 1.0], ["release", 1.6]], "NNS": [["releases", 1.6]], "NN": [["album ANTI", 4.0], ["release", 1.6], ["album", 1.1]], "VBN": [["released", 1.6]], "VBG": [["making", 1.0]], "VBD": [["released", 1.6]]}
93	Review: Rihanna’s Anti Rewrites the Rules of Her Career	1	http://time.com/4198509/rihanna-anti-review/	93_1_Review__Rihanna’s_Anti_Rewrites_the_Rules_of_Her_Career.txt	{"VBZ": [["sings", 1.0]], "NNP": [["career", 1.0], ["anti", 1.7777777777777777], ["rihanna", 1.7083333333333333]], "VBG": [["working", 1.2], ["singing", 1.0]], "NN": [["point", 1.25], ["career", 1.0], ["work", 1.2], ["album", 1.4375], ["review", 1.0], ["year", 1.1428571428571428], ["song", 1.8333333333333333]], "NNS": [["years", 1.1428571428571428], ["careers", 1.0], ["songs", 1.8333333333333333], ["albums", 1.4375], ["rules", 1.0]], "JJ": [["anti", 1.7777777777777777]]}
98	What to Know About the E. Coli Outbreak That’s Linked to Chipotle	1	http://time.com/4096624/chipotle-e-coli-outbreak/	98_1_What_to_Know_About_the_E._Coli_Outbreak_That’s_Linked_to_Chipotle.txt	{"NNP": [["chipotle", 2.7777777777777777], ["Coli Outbreak", 4.0], ["state", 1.8]], "NNS": [["states", 1.8], ["restaurants", 1.625], ["bacteria", 1.4], ["animals", 1.25], ["foods", 1.7777777777777777], ["people", 1.1]], "VBN": [["linked", 1.0], ["spread", 1.0], ["contaminated water", 4.45]], "FW": [["coli", 1.3]], "JJ": [["sick", 1.25], ["animal", 1.25]], "VB": [["make", 1.0], ["spread", 1.0]], "NN": [["restaurant", 1.625], ["coli", 1.3], ["spread", 1.0], ["food", 1.7777777777777777], ["contaminated water", 4.45], ["state", 1.8]]}
87	Obama to visit Chicago area Tuesday to discuss immigration	1	http://www.chicagotribune.com/news/local/breaking/chi-obama-to-visit-chicago-tuesday-to-discuss-immigration-20141121-story.html	87_1_Obama_to_visit_Chicago_area_Tuesday_to_discuss_immigration.txt	{"NNP": [["illinois", 1.0], ["friday", 1.0], ["washington", 1.0], ["tuesday", 1.0], ["obama", 3.0], ["President Barack Obama", 7.0]], "VB": [["discuss immigration", 4.0], ["meet", 1.0], ["discuss", 1.0], ["visit", 1.0], ["return", 1.0]], "RB": [["afterward", 1.0]], "VBN": [["made available", 4.0]], "NN": [["travel", 1.0], ["broken immigration system", 8.0], ["condition", 1.0], ["discuss immigration", 4.0], ["immigration", 2.0], ["Chicago area", 4.0], ["official", 1.6666666666666667], ["White House official", 7.666666666666667], ["community", 1.0], ["anonymity", 1.0]], "NNS": [["members", 1.0], ["executive actions", 4.0], ["details", 1.0]], "VBG": [["speaking", 1.0], ["according", 1.0]]}
88	Obama’s Chicago visit: Where he’ll be and when so you can avoid traffic	1	http://wgntv.com/2015/10/27/obamas-chicago-visit-where-hell-be-and-when-so-you-can-avoid-traffic/	88_1_Obama’s_Chicago_visit__Where_he’ll_be_and_when_so_you_can_avoid_traffic.txt	{"NNP": [["Public Hotel", 4.0], ["President Obama", 4.333333333333334], ["Lake Shore Drive", 8.0], ["United Center", 4.0], ["police", 1.0], ["State St", 4.0], ["McCormick Place", 4.0], ["drive", 2.0], ["president", 2.0], ["Chicago Tuesday", 4.5]], "VB": [["make", 1.0], ["deliver remarks", 4.0], ["participate", 1.0], ["expect motorcades", 4.0], ["avoid", 1.0], ["avoid traffic", 4.0], ["depart", 1.0]], "NNPS": [["chiefs", 1.0]], "XXX": [["Obama arrived", 4.333333333333334], ["street closures during", 9.0]], "VBG": [["spotting", 1.0], ["predicting", 1.0], ["driving", 2.0]], "NN": [["schedule", 1.0], ["Chicago visit", 4.0], ["DNC event", 4.0], ["Bulls game", 4.0], ["traffic mess", 4.0], ["Power Reviews Headquarters", 9.0], ["secret service", 4.0], ["roundtable", 1.0], ["visit", 1.0], ["avoid traffic", 4.0], ["city", 1.0], ["Tuesday morning", 4.0]], "NNS": [["several events", 4.0], ["expect motorcades", 4.0], ["deliver remarks", 4.0]], "JJ": [["lakefront", 1.0]], "VBN": [["scheduled", 1.0]], "VBD": [["was transported", 4.0]]}
89	Skywatchers to get special treat -- five planets and a comet	1	http://www.cnn.com/2016/01/19/us/planet-comet-show/	89_1_Skywatchers_to_get_special_treat_--_five_planets_and_a_comet.txt	{"VBP": [["find", 1.1666666666666667]], "NNP": [["jupiter", 1.0], ["comet", 1.5], ["venus", 1.375], ["telescope", 1.75]], "VB": [["make", 1.0], ["find", 1.1666666666666667]], "VBG": [["finding", 1.1666666666666667], ["making", 1.0]], "NN": [["special treat", 4.0], ["comet", 2.5], ["telescope", 1.75], ["planet", 1.6666666666666667]], "NNS": [["skywatchers", 1.0], ["planets", 2.666666666666667], ["binoculars", 1.5]], "JJR": [["easier", 1.0]]}
94	Rihanna: Anti review – brave, bold … and confused	1	http://www.theguardian.com/music/2016/jan/28/rihanna-anti-album-review-brave-bold-and-confused	94_1_Rihanna__Anti_review_–_brave,_bold_…_and_confused.txt	{"VBZ": [["works", 1.5]], "NNP": [["anti", 1.2], ["rihanna", 1.0]], "VB": [["work", 1.5]], "NN": [["work", 1.5], ["kind", 1.4]], "VBN": [["worked", 1.5], ["confused", 1.0]], "JJ": [["bold", 1.0], ["anti", 1.2]]}
95	It's a boy! Catherine gives birth to royal baby	1	http://www.cnn.com/2013/07/22/world/europe/uk-royal-baby/	95_1_It's_a_boy!_Catherine_gives_birth_to_royal_baby.txt	{"NNP": [["duchess", 1.0], ["william", 1.8571428571428572], ["cambridge", 1.0], ["hospital", 1.2]], "NNS": [["lines", 1.0], ["people", 1.25]], "VBN": [["announced", 1.25]], "VB": [["announce", 1.25]], "NN": [["throne", 1.0], ["hospital", 1.2], ["line", 1.0], ["duchess", 1.0], ["royal baby", 4.0], ["statement", 1.0], ["birth", 1.1428571428571428]]}
96	It’s a Girl! Princess Kate Gives Birth to a Princess	1	http://time.com/3835850/royal-baby-girl-princess-kate/	96_1_It’s_a_Girl!_Princess_Kate_Gives_Birth_to_a_Princess.txt	{"NNP": [["Prince Harry", 4.458333333333334], ["cambridge", 1.6666666666666667], ["princess", 1.0], ["hospital", 1.0], ["queen", 1.0], ["Kensington Palace", 4.0], ["Surgeon Gynaecologist", 4.0], ["catherine", 1.0], ["Prince Charles", 4.125], ["birth", 1.75]], "NNPS": [["cambridges", 1.6666666666666667]], "NNS": [["babies", 1.5]], "NN": [["hospital", 1.0], ["throne", 1.0], ["succession", 1.0], ["line", 1.0], ["baby", 1.5], ["birth", 1.75]]}
97	Royal baby girl: Kate Middleton gives birth to the Princess the nation had longed for	1	http://www.telegraph.co.uk/news/uknews/royal-baby/11579691/Royal-baby-girl-Kate-Middleton-gives-birth-to-the-Princess-the-nation-had-longed-for.html	97_1_Royal_baby_girl__Kate_Middleton_gives_birth_to_the_Princess_the_nation_had_longed_for.txt	{"NNP": [["cambridge", 1.3636363636363635], ["girl", 1.3333333333333333], ["prince", 1.8461538461538463], ["Prince George", 3.937062937062937], ["Kensington Palace", 3.875], ["queen", 1.3333333333333333], ["duke", 1.375], ["duchess", 1.1304347826086956], ["princess", 2.666666666666667], ["family", 1.75], ["wales", 1.0]], "NNS": [["families", 1.75], ["members", 1.4], ["congratulations", 1.0], ["weeks", 1.0], ["babies", 1.5384615384615385]], "VBN": [["born", 1.6], ["carried", 1.4], ["longed", 1.0]], "JJ": [["delighted", 1.4], ["public", 1.4]], "VB": [["pick", 1.25], ["wave", 1.3333333333333333], ["congratulate", 1.0]], "VBD": [["arrived", 1.0], ["carried", 1.4], ["picked", 1.25], ["waved", 1.3333333333333333]], "VBG": [["carrying", 1.4], ["arriving", 1.0]], "NN": [["news", 1.25], ["week", 1.0], ["princess", 1.6666666666666667], ["Lindo Wing", 4.0], ["girl", 1.3333333333333333], ["hospital", 1.2222222222222223], ["nation", 1.0], ["queen", 1.3333333333333333], ["Royal baby girl", 9.0], ["arrival", 1.0], ["public", 1.4], ["daughter", 1.2], ["Royal family", 3.8333333333333335], ["wave", 1.3333333333333333], ["birth", 1.2727272727272727], ["couple", 1.3333333333333333], ["duchess", 1.1304347826086956], ["family", 1.75], ["baby", 1.5384615384615385], ["member", 1.4]]}
99	Chipotle E. coli case in Illinois: Officials mum on details	1	http://www.chicagotribune.com/business/ct-chipotle-ecoli-stock-1208-biz-20151207-26-story.html	99_1_Chipotle_E._coli_case_in_Illinois__Officials_mum_on_details.txt	{"NNP": [["illinois", 1.0], ["shah", 1.25], ["chipotle", 1.0]], "NNS": [["years", 1.0], ["outbreaks", 1.8181818181818181], ["states", 1.6], ["cases", 1.5], ["details", 1.0]], "NN": [["outbreak", 1.8181818181818181], ["coli case", 4.0], ["Officials mum", 4.0], ["year", 1.0], ["case", 1.5], ["state", 1.6]]}
100	Crisis of the Week: Costco Deals With a Side Order of E.coli	1	http://blogs.wsj.com/riskandcompliance/2015/12/07/crisis-of-the-week-costco-deals-with-a-side-order-of-e-coli/	100_1_Crisis_of_the_Week__Costco_Deals_With_a_Side_Order_of_E.coli.txt	{"VBZ": [["addresses", 1.0], ["happens", 1.0]], "NNP": [["Side Order", 4.0], ["chipotle", 1.2857142857142858], ["control", 1.25], ["costco", 1.3529411764705883], ["e.coli", 1.0]], "NNS": [["outbreaks", 1.8571428571428572], ["reporters", 1.0], ["restaurants", 1.25], ["situations", 1.2], ["addresses", 1.0], ["reports", 1.0], ["companies", 1.8571428571428572]], "VBD": [["addressed", 1.0]], "VB": [["happen", 1.0], ["control", 1.25], ["work", 1.4]], "VBG": [["addressing", 1.0], ["working", 1.4]], "NN": [["week", 1.0], ["outbreak", 1.8571428571428572], ["problem", 1.4], ["crisis", 1.0], ["company", 1.8571428571428572], ["control", 1.25], ["situation", 1.2]]}
101	Police: 20 children among 26 victims of Connecticut school shooting	1	http://www.cnn.com/2012/12/14/us/connecticut-school-shooting/	101_1_Police__20_children_among_26_victims_of_Connecticut_school_shooting.txt	{"NNP": [["newtown", 1.4], ["police", 2.142857142857143], ["school", 1.75]], "NNS": [["victims", 1.0], ["killings", 1.4], ["teachers", 1.5714285714285714], ["children", 2.0], ["weapons", 1.25], ["reports", 1.5], ["law enforcement officials", 8.2], ["police", 3.142857142857143], ["investigators", 1.4]], "VBN": [["reported", 1.5], ["killed", 1.4]], "VBG": [["killing", 1.4]], "NN": [["police", 2.142857142857143], ["shooting", 1.5714285714285714], ["investigation", 1.4], ["weapon", 1.25], ["Connecticut school shooting", 9.0], ["school", 1.75], ["report", 1.5], ["shooter", 1.0], ["teacher", 1.5714285714285714]]}
104	Ted Cruz Wins Republican Caucuses in Iowa	1	http://www.nytimes.com/2016/02/02/us/ted-cruz-wins-republican-caucus.html?_r=0	104_1_Ted_Cruz_Wins_Republican_Caucuses_in_Iowa.txt	{"NNS": [["supporters", 1.125], ["votes", 1.3333333333333333], ["times", 1.0], ["voters", 1.5], ["caucuses", 1.5555555555555556]], "NNPS": [["iowans", 1.6]], "VBD": [["made", 1.0]], "VB": [["support", 1.125]], "NNP": [["iowa", 2.466666666666667]], "NN": [["victory", 1.5714285714285714], ["vote", 1.3333333333333333], ["caucus", 1.5555555555555556], ["time", 1.0], ["percent", 2.0], ["voting", 1.3333333333333333], ["support", 1.125]], "VBZ": [["votes", 1.3333333333333333]]}
102	Oregon shooting: Gunman was student in class where he killed 9	1	http://www.cnn.com/2015/10/02/us/oregon-umpqua-community-college-shooting/	102_1_Oregon_shooting__Gunman_was_student_in_class_where_he_killed_9.txt	{"VBG": [["writing", 1.6]], "VBP": [["kill", 1.75]], "VBN": [["killed", 1.75], ["found", 1.0]], "NN": [["killing", 1.75], ["school", 1.25], ["rifle", 1.0], ["student", 1.8571428571428572], ["Gunman was student", 9.0], ["shooting", 1.8333333333333333], ["shooter", 1.4444444444444444], ["college", 1.6666666666666667], ["gunman", 1.6428571428571428], ["harper-mercer", 1.0], ["investigation", 1.875], ["Oregon shooting", 4.0], ["family", 1.5], ["police", 1.3333333333333333], ["class", 1.0]], "VBD": [["found", 1.0], ["killed", 2.75]], "NNS": [["writings", 1.6], ["rifles", 1.0], ["christians", 1.0], ["shootings", 1.8333333333333333], ["Law enforcement officials", 8.333333333333334], ["students", 1.8571428571428572], ["people", 1.5454545454545454], ["investigators", 1.875], ["police", 1.3333333333333333]], "NNP": [["college", 1.6666666666666667], ["harper-mercer", 1.0], ["Stacy Boylan", 4.0], ["police", 1.3333333333333333], ["california", 1.0], ["christian", 1.0]], "VB": [["kill", 1.75], ["glorify", 1.0]]}
107	Uber just completely changed its logo and branding	1	http://www.theverge.com/2016/2/2/10898456/uber-just-completely-changed-its-logo-and-branding	107_1_Uber_just_completely_changed_its_logo_and_branding.txt	{"NNP": [["uber", 2.7777777777777777], ["kalanick", 1.6666666666666667]], "NN": [["branding", 1.0], ["logo", 2.0], ["center", 1.0]]}
116	Groundhog Day: Punxsutawney Phil Did Not See His Shadow	1	http://www.npr.org/sections/thetwo-way/2016/02/02/465253970/groundhog-day-punxsutawney-phil-did-not-see-his-shadow	116_1_Groundhog_Day__Punxsutawney_Phil_Did_Not_See_His_Shadow.txt	{"NNP": [["groundhog", 1.4], ["Punxsutawney Phil", 4.0], ["Groundhog Day", 4.0], ["shadow", 1.0], ["phil", 1.4]], "NNS": [["animals", 1.3333333333333333], ["groundhogs", 1.4]], "NN": [["groundhog", 1.4], ["animal", 1.3333333333333333], ["morning", 1.0], ["shadow", 1.0]]}
113	Las Vegas betting big on Carolina Panthers	1	http://www.cnbc.com/2016/02/02/las-vegas-betting-big-on-carolina-panthers.html	113_1_Las_Vegas_betting_big_on_Carolina_Panthers.txt	{"NNPS": [["panthers", 1.3333333333333333], ["Carolina Panthers", 4.0]], "NNP": [["denver", 1.0], ["holt", 1.25], ["panthers", 1.3333333333333333], ["Super Bowl", 4.333333333333333]], "NN": [["year", 1.0]]}
118	Groundhog Day 2016: Punxsutawney Phil sees early spring	1	http://www.cnn.com/2016/02/02/living/groundhog-day-punxsutawney-phil/index.html	118_1_Groundhog_Day_2016__Punxsutawney_Phil_sees_early_spring.txt	{"NNP": [["Punxsutawney Phil", 4.0], ["Groundhog Day", 4.0], ["prognosticator", 1.0], ["phil", 2.0]], "NNS": [["prognosticators", 1.0]], "NN": [["president", 1.0], ["early spring", 4.0], ["shadow", 1.0]]}
103	Sandy Hook Elementary shooting leaves 28 dead, law enforcement sources say	1	https://www.washingtonpost.com/politics/sandy-hook-elementary-school-shooting-leaves-students-staff-dead/2012/12/14/24334570-461e-11e2-8e70-e1993528222d_story.html	103_1_Sandy_Hook_Elementary_shooting_leaves_28_dead,_law_enforcement_sources_say.txt	{"NNP": [["newtown", 1.0], ["police", 1.5]], "VB": [["call", 1.0]], "VBG": [["according", 1.0]], "NNS": [["shots", 1.6], ["schools", 1.1724137931034482], ["law enforcement sources", 17.433333333333334], ["children", 1.2857142857142858], ["calls", 1.0], ["authorities", 1.0], ["police", 1.5]], "NN": [["school", 1.1724137931034482], ["home", 1.0], ["child", 1.2857142857142858], ["shot", 1.6], ["principal", 1.4285714285714286], ["shooter", 1.25], ["police", 1.5]], "VBN": [["called", 1.0], ["locked", 1.0], ["shot", 1.6]], "VBD": [["heard", 1.5]]}
105	Ted Cruz Wins Iowa, Trump Loses—for Now	1	http://www.newyorker.com/news/amy-davidson/ted-cruz-wins-trump-loses-for-now	105_1_Ted_Cruz_Wins_Iowa,_Trump_Loses—for_Now.txt	{"NNS": [["votes", 1.4], ["candidates", 1.25]], "VBZ": [["works", 1.2]], "VBG": [["working", 1.2]], "NNP": [["party", 1.6], ["times", 1.25], ["trump", 1.5833333333333333], ["cruz", 1.5238095238095237], ["rubio", 1.6666666666666667], ["hampshire", 1.0]], "NN": [["cent", 1.4], ["party", 1.6], ["candidate", 1.25], ["vote", 1.4], ["time", 1.25]], "VBN": [["worked", 1.2]], "VBD": [["worked", 1.2]]}
106	Iowa caucuses: Ted Cruz wins; Clinton declares victory	1	http://www.cnn.com/2016/02/01/politics/iowa-caucuses-2016-highlights/	106_1_Iowa_caucuses__Ted_Cruz_wins;_Clinton_declares_victory.txt	{"NNS": [["results", 1.4], ["Iowa caucuses", 4.0]], "VB": [["happen", 1.0]], "VBD": [["resulted", 1.4], ["told", 1.8]], "NNP": [["Iowa Caucus", 3.666666666666667], ["bernie", 1.25], ["trump", 1.6], ["South Carolina", 4.0], ["iowa", 1.6666666666666667], ["hampshire", 1.2857142857142858]], "NN": [["read", 1.0]], "VBZ": [["happens", 1.0]]}
108	Celebrating Cities: A New Look and Feel for Uber	1	https://newsroom.uber.com/celebrating-cities-a-new-look-and-feel-for-uber/	108_1_Celebrating_Cities__A_New_Look_and_Feel_for_Uber.txt	{"NNS": [["people", 1.0], ["cities", 1.4285714285714286], ["Celebrating Cities", 4.0], ["countries", 1.0], ["atoms", 1.0], ["patterns", 1.6]], "NNP": [["uber", 2.666666666666667]], "NN": [["today", 1.0], ["technology", 1.25], ["atom", 1.0], ["city", 1.4285714285714286], ["feel", 1.0]], "VBZ": [["feels", 1.0]], "VBP": [["feel", 1.0]]}
109	Uber has a new logo, and the Internet is not pleased	1	http://money.cnn.com/2016/02/02/news/companies/uber-logo-rebrand/	109_1_Uber_has_a_new_logo,_and_the_Internet_is_not_pleased.txt	{"NNS": [["logos", 1.4285714285714286], ["drivers", 1.5]], "NNP": [["uber", 1.8]], "NN": [["company", 1.4], ["logo", 2.428571428571429], ["rebranding", 1.0], ["internet", 1.0]], "VBN": [["related", 1.0]], "XXX": [["user wrote", 4.333333333333334], ["Uber has", 8.05]]}
110	Former Maryland Gov. Martin O'Malley drops out of Democratic race for president	1	http://www.tampabay.com/news/politics/national/breaking-former-maryland-gov-martin-omalley-drops-out-of-democratic-race/2263664	110_1_Former_Maryland_Gov._Martin_O'Malley_drops_out_of_Democratic_race_for_president.txt	{"NN": [["decision", 1.25], ["Democratic race", 4.0], ["race", 1.0], ["president", 1.0]]}
111	Martin O'Malley suspends presidential campaign after Iowa caucuses	1	http://www.baltimoresun.com/news/maryland/politics/blog/bal-martin-omalley-to-announce-hes-suspending-presidential-campaign-20160201-story.html	111_1_Martin_O'Malley_suspends_presidential_campaign_after_Iowa_caucuses.txt	{"NNP": [["clinton", 1.0], ["iowa", 1.6666666666666667], ["martin", 1.0]], "NN": [["campaign", 1.4285714285714286], ["time", 1.0], ["race", 1.4], ["timing", 1.0]], "VBD": [["campaigned", 1.4285714285714286]]}
112	Martin O'Malley to drop out of Democratic race	1	http://www.desmoinesregister.com/story/news/elections/presidential/caucus/2016/02/01/omalley-drop-out-race/79625880/	112_1_Martin_O'Malley_to_drop_out_of_Democratic_race.txt	{"NNS": [["people", 1.0]], "NN": [["land", 1.0], ["Democratic race", 4.0], ["conclusion", 1.0], ["visit", 1.0]], "VBD": [["visited", 1.0]]}
121	Twitter CEO Jack Dorsey Confirms Layoffs With Tweet	1	http://www.wired.com/2015/10/twitter-layoffs/	121_1_Twitter_CEO_Jack_Dorsey_Confirms_Layoffs_With_Tweet.txt	{"NNP": [["engineering", 1.0], ["twitter", 1.25], ["tweet", 1.0]], "NN": [["move", 1.3333333333333333], ["plan", 1.3333333333333333], ["time", 1.0], ["work", 1.3333333333333333]], "NNS": [["people", 1.0]], "VB": [["move", 1.3333333333333333]], "VBP": [["plan", 1.3333333333333333], ["work", 1.3333333333333333]]}
122	Singer Amy Winehouse found dead	1	http://www.cnn.com/2011/SHOWBIZ/celebrity.news.gossip/07/23/amy.winehouse.dies/	122_1_Singer_Amy_Winehouse_found_dead.txt	{"NNP": [["rehab", 1.4285714285714286], ["london", 1.4], ["winehouse", 1.4]], "NN": [["rehab", 1.4285714285714286], ["death", 1.3333333333333333], ["family", 1.0], ["stage", 1.25], ["song", 1.25], ["soul", 1.0]], "NNS": [["songs", 1.25]], "VB": [["rehab", 1.4285714285714286]], "JJ": [["soulful", 1.0]]}
124	Amy Winehouse, British Soul Singer With a Troubled Life, Dies at 27	1	http://www.nytimes.com/2011/07/24/arts/music/amy-winehouse-british-soul-singer-dies-at-27.html?_r=0	124_1_Amy_Winehouse,_British_Soul_Singer_With_a_Troubled_Life,_Dies_at_27.txt	{"NNP": [["Troubled Life", 4.0], ["British Soul Singer", 9.0], ["Amy Winehouse", 4.0], ["black", 1.0], ["london", 1.0]], "NN": [["album", 1.5], ["love", 1.25], ["performance", 1.3333333333333333]], "NNS": [["albums", 1.5], ["songs", 1.0]], "VBG": [["performing", 1.3333333333333333]], "VB": [["perform", 1.3333333333333333]], "RB": [["back", 1.0]], "VBD": [["performed", 1.3333333333333333], ["loved", 1.25]]}
114	Panthers bring comforts of Carolina to Super Bowl 50	1	http://www.charlotteobserver.com/sports/nfl/carolina-panthers/panther-tracks/article58052353.html	114_1_Panthers_bring_comforts_of_Carolina_to_Super_Bowl_50.txt	{"NN": [["stadium", 1.5], ["game day", 3.5], ["game", 1.5], ["home", 1.875], ["team", 1.1666666666666667]], "NNS": [["miles", 1.0], ["games", 1.5], ["Panthers bring comforts", 9.0], ["teams", 1.1666666666666667]], "VB": [["make", 1.0]], "VBG": [["making", 1.0]], "NNPS": [["panthers", 1.5]], "NNP": [["stadium", 1.5], ["panthers", 1.5], ["sunday", 1.25], ["Super Bowl", 4.0], ["Sweet Caroline", 4.0], ["carolina", 1.0], ["charlotte", 1.4]], "VBP": [["make", 1.0]]}
115	If Panthers win Super Bowl 50, are they greatest team of all time?	1	http://sports.yahoo.com/news/if-panthers-win-super-bowl-50--are-they-greatest-team-of-all-time--031151240.html	115_1_If_Panthers_win_Super_Bowl_50,_are_they_greatest_team_of_all_time?.txt	{"NNPS": [["bears", 1.4285714285714286], ["panthers", 1.7272727272727273]], "NN": [["time", 2.0], ["greatest team", 4.0], ["point", 1.6666666666666667], ["season", 1.6666666666666667], ["team", 1.5833333333333333]], "NNP": [["team", 1.5833333333333333]], "NNS": [["bears", 1.4285714285714286], ["seasons", 1.6666666666666667], ["points", 1.6666666666666667], ["teams", 1.5833333333333333]]}
117	Groundhog Day 2016: Punxsutawney Phil sees no shadow, predicts early spring	1	https://www.washingtonpost.com/news/capital-weather-gang/wp/2016/02/02/groundhog-day-2016-punxsutawney-phil-sees-no-shadow-predicts-early-spring/	117_1_Groundhog_Day_2016__Punxsutawney_Phil_sees_no_shadow,_predicts_early_spring.txt	{"NN": [["prediction", 1.25], ["predicts early spring", 9.0], ["time", 1.25], ["shadow", 1.0]], "NNS": [["predictions", 1.25], ["times", 1.25]], "JJ": [["predictive", 1.25]]}
119	Twitter employees are tweeting about the Twitter layoffs	1	http://www.businessinsider.com/twitter-layoff-reactions-2015-10	119_1_Twitter_employees_are_tweeting_about_the_Twitter_layoffs.txt	{"CD": [["million", 1.0]], "NNP": [["nest", 1.0], ["cost Twitter", 4.0], ["venturebeat", 1.0], ["restructure Twitter", 4.0], ["chris", 1.0], ["plan Monday", 4.0]], "VBD": [["followed", 1.5], ["followed suit", 3.5], ["was presumably laid", 7.5], ["swooped", 1.0], ["shared", 1.0], ["laid", 2.0]], "NNS": [["employees", 1.6666666666666667], ["employers", 1.0], ["hashtag #TwitterLayoffs", 4.0], ["Twitter layoffs", 4.0], ["severance packages", 4.0], ["questions", 1.0], ["Twitter employees", 7.666666666666667], ["layoff stories", 4.0], ["any ideas", 4.0]], "VB": [["waste", 1.0], ["restructure Twitter", 4.0], ["cost Twitter", 4.0], ["please reach", 4.0]], "NN": [["sarcastic anecdote", 4.0], ["followed suit", 3.5], ["anguish", 1.0], ["news", 1.0], ["morning", 1.0], ["European correspondent", 4.0], ["company", 1.3333333333333333], ["Twitter engineer", 4.0], ["designer", 1.0], ["startup route", 4.0]], "VBG": [["following", 1.5], ["according", 1.0], ["tweeting", 1.0]], "XXX": [["company was", 3.833333333333333], ["Dorsey delivered", 4.0], ["emails addressed", 4.0], ["email concluded", 4.0]], "RB": [["meanwhile", 1.0], ["directly", 1.0], ["always", 1.0]], "VBN": [["laid", 2.0]]}
120	Twitter Layoffs: Social Network Slashing 8 Percent of Workforce	1	http://www.nbcnews.com/tech/tech-news/twitter-layoffs-social-network-slashing-8-percent-workforce-n443481	120_1_Twitter_Layoffs__Social_Network_Slashing_8_Percent_of_Workforce.txt	{"VB": [["move", 1.0], ["lose", 1.0]], "NNS": [["employees", 1.3333333333333333], ["layoffs", 1.5], ["Twitter shares", 3.333333333333333], ["years", 1.0], ["investors", 1.0], ["deepest job cuts", 9.0], ["engineering teams", 3.5]], "NN": [["percent", 1.3333333333333333], ["nimbler team", 4.0], ["permanent CEO", 4.0], ["period", 1.0], ["result", 1.0], ["rest", 1.0], ["filing", 1.5], ["parallel", 1.0], ["layoff news", 3.5], ["week", 1.0], ["organization", 1.0], ["company", 1.3333333333333333], ["Tech blog", 4.0], ["engineering", 1.5], ["letter", 1.0], ["nest", 1.0], ["SEC filing", 3.5], ["global workforce", 4.0], ["product", 1.0], ["link", 1.0], ["workforce", 1.0], ["layoff", 1.5]], "VBG": [["planning", 1.0], ["Twitter becoming", 3.333333333333333]], "NNP": [["engineering", 1.5], ["Twitter Layoffs", 4.0], ["early trade Tuesday", 9.0], ["twitter", 1.3333333333333333], ["Jack Dorsey", 4.0]], "VBD": [["was included", 4.0], ["doubled", 1.0], ["tweeted", 1.0]], "JJ": [["bloated", 1.0], ["streamlined", 1.0], ["past", 1.0]], "JJR": [["smaller", 1.5]], "VBP": [["feel strongly", 4.0]], "NNPS": [["securities", 1.0]], "XXX": [["Dorsey wrote", 4.0], ["percent during", 3.333333333333333], ["employees globally", 3.333333333333333], ["bit smaller", 3.5]], "RBR": [["faster", 1.0]]}
123	Amy Winehouse, 27, found dead at her London flat after suspected 'drug overdose	1	http://www.dailymail.co.uk/tvshowbiz/article-2018020/Amy-Winehouse-dead-London-flat-drug-overdose.html	123_1_Amy_Winehouse,_27,_found_dead_at_her_London_flat_after_suspected_'drug_overdose.txt	{"XXX": [["death was due", 9.0], ["London flat", 4.0], ["Winehouse was apparently", 8.5], ["ambulance crews arrived", 8.5], ["paramedics arrived", 4.0], ["Winehouse was booed", 8.5]], "NNS": [["minutes", 1.0], ["paramedics", 1.5], ["Sky sources", 4.5], ["sources", 2.0], ["hours", 1.0], ["emergency services", 4.0]], "VB": [["revive", 1.0]], "NN": [["spokeswoman", 1.0], ["home", 1.0], ["scene", 1.0], ["paramedic", 1.5], ["drink", 1.0], ["suspected drug overdose", 8.0], ["place", 1.0], ["property", 1.0], ["patient", 1.0], ["stage", 1.0], ["Troubled singer", 4.0], ["long battle", 4.0], ["bicycle", 1.0], ["drug overdose", 5.0]], "VBG": [["according", 1.0]], "NNP": [["back", 1.0], ["Amy Winehouse", 4.0], ["london", 1.0], ["Sky sources Autopsy", 7.5]], "VBD": [["attended", 1.0]], "JJ": [["unable", 1.0]], "VBN": [["suspected drug overdose", 8.0], ["found dead", 8.0]]}
126	"Serial" Announces Crucial Development in Adnan Syed's Case	1	http://www.details.com/story/serial-announces-crucial-development-in-adnan-syeds-case	126_1_"Serial"_Announces_Crucial_Development_in_Adnan_Syed's_Case.txt	{"VBP": [["update", 1.25]], "NN": [["testimony", 1.0], ["case", 1.0]], "NNP": [["waranowitz", 1.0], ["update", 1.25]]}
128	New Orleans braces for monster hurricane	1	http://www.cnn.com/2005/WEATHER/08/28/hurricane.katrina/	128_1_New_Orleans_braces_for_monster_hurricane.txt	{"NNS": [["orleans", 1.1], ["hours", 1.0]], "NN": [["monster hurricane", 4.0], ["Watch video", 3.6], ["city", 1.5555555555555556], ["tropical storm warning", 7.5054945054945055]], "VB": [["Watch video", 3.6], ["expect", 1.0]], "NNP": [["louisiana", 1.1111111111111112], ["mississippi", 1.4], ["city", 1.5555555555555556], ["orleans", 1.1], ["florida", 1.2857142857142858]], "VBN": [["expected", 1.0]]}
129	Expert: Katrina could unleash disaster	1	http://www.cnn.com/2005/WEATHER/08/28/katrina.doomsday/	129_1_Expert__Katrina_could_unleash_disaster.txt	{"NNS": [["waves", 1.4], ["miles", 1.0], ["chemical plants", 4.0], ["feet", 1.0], ["years", 1.0], ["floodwaters", 1.0]], "NN": [["unleash disaster", 4.0], ["expert", 1.0], ["floodwater", 1.0], ["wave", 1.4]], "NNP": [["van Heerden", 5.0], ["orleans", 1.2], ["katrina", 1.0]]}
125	Adnan Syed Of 'Serial' Fame Appears In Court To Seek New Trial	1	http://www.npr.org/sections/thetwo-way/2016/02/03/465406957/adnan-syed-of-serial-fame-appears-in-court-to-seek-new-trial	125_1_Adnan_Syed_Of_'Serial'_Fame_Appears_In_Court_To_Seek_New_Trial.txt	{"VBD": [["thought", 1.25]], "NNP": [["court", 1.0], ["trial", 1.0], ["Adnan Syed", 4.0], ["seabrook", 1.75]], "JJ": [["serial", 1.6666666666666667]], "XXX": [["Seabrook reports", 3.75]], "VB": [["hear", 1.8333333333333333], ["seek", 1.0]], "NNS": [["years", 1.25], ["thoughts", 1.25], ["courts", 1.25]], "NN": [["court", 1.25], ["trial", 1.0], ["hearing", 1.8333333333333333], ["murder", 1.2], ["year", 1.25], ["judge", 1.5], ["case", 1.1666666666666667], ["time", 1.0]], "VBG": [["murdering", 1.2]]}
127	Adnan Syed of 'Serial' Finally in Court for Retrial Bid	1	http://abcnews.go.com/US/adnan-syed-serial-back-court-wednesday-bid-retrial/story?id=36668690	127_1_Adnan_Syed_of_'Serial'_Finally_in_Court_for_Retrial_Bid.txt	{"VB": [["issue", 1.6666666666666667], ["hand", 1.0]], "NNP": [["Adnan Syed", 4.0], ["Retrial Bid", 4.0], ["court", 2.571428571428571], ["gutierrez", 1.8571428571428572], ["mcclain", 1.4]], "VBN": [["worked", 1.0], ["called", 1.6]], "VBD": [["worked", 1.0], ["issued", 1.6666666666666667], ["called", 1.6]], "NNS": [["issues", 1.6666666666666667], ["times", 1.6], ["cases", 1.4], ["hands", 1.0]], "NN": [["court", 1.5714285714285714], ["trial", 1.375], ["state", 1.2], ["case", 1.4], ["time", 1.6], ["handful", 1.0]]}
153	Mark Zuckerberg shoves Bezos aside for 4th-richest ranking	1	http://money.cnn.com/2016/02/03/technology/zuckerberg-bezos-bloomberg/index.html?iid=ob_homepage_tech_pool&iid=obnetwork	153_1_Mark_Zuckerberg_shoves_Bezos_aside_for_4th-richest_ranking.txt	{"CD": [["billion", 1.6666666666666667]], "NNS": [["billions", 1.6666666666666667]], "NN": [["tech30", 1.0]]}
130	Hurricane Katrina Slams Into Gulf Coast; Dozens Are Dead	1	http://www.nytimes.com/2005/08/30/us/hurricane-katrina-slams-into-gulf-coast-dozens-are-dead.html	130_1_Hurricane_Katrina_Slams_Into_Gulf_Coast;_Dozens_Are_Dead.txt	{"VBD": [["evacuated", 1.0]], "NNP": [["mobile", 1.4444444444444444], ["mississippi", 1.4444444444444444], ["orleans", 1.2], ["hurricane", 2.0], ["category", 1.0], ["alabama", 1.0], ["biloxi", 1.0], ["louisiana", 1.1428571428571428], ["miss.", 1.0]], "CD": [["billion", 1.2]], "NN": [["casino", 1.6666666666666667], ["flooding", 1.6666666666666667], ["week", 1.0], ["storm", 1.631578947368421], ["hurricane", 2.0], ["home", 1.625], ["category", 1.0], ["power", 1.3333333333333333], ["city", 1.0], ["roof", 1.0], ["damage", 1.8], ["water", 1.4166666666666667], ["shelter", 1.25], ["area", 1.625], ["house", 1.0]], "VB": [["remain", 1.25], ["evacuate", 1.0]], "NNS": [["areas", 1.625], ["parts", 1.25], ["casinos", 1.6666666666666667], ["remains", 1.25], ["hurricanes", 2.0], ["officials", 1.5833333333333333], ["orleans", 1.2], ["weeks", 1.0], ["evacuees", 1.0], ["billions", 1.2], ["people", 1.5555555555555556], ["feet", 1.0], ["roofs", 1.0], ["shelters", 1.25], ["waters", 1.4166666666666667], ["storms", 1.631578947368421], ["homes", 1.625]], "VBN": [["damaged", 1.8], ["remained", 1.25], ["decided", 1.0], ["spared", 1.0], ["evacuated", 1.0], ["flooded", 1.6666666666666667]], "VBG": [["flooding", 1.6666666666666667], ["evacuating", 1.0], ["deciding", 1.0], ["sparing", 1.0]]}
133	Monaco Princess Charlene gives birth to twins	1	http://www.bbc.com/news/world-europe-30422160	133_1_Monaco_Princess_Charlene_gives_birth_to_twins.txt	{"VBN": [["born", 2.0], ["born outside", 4.0], ["excluded", 1.0], ["delivered", 1.0], ["fired", 1.0]], "VB": [["become next-in-line", 4.0], ["mark", 1.0]], "IN": [["since", 2.0]], "NNS": [["twins", 2.4], ["minutes", 1.0], ["children", 1.0], ["babies", 1.6666666666666667], ["time twins", 3.4], ["succession favouring males", 9.0], ["twin babies", 3.0666666666666664]], "NNP": [["ahead", 1.0], ["jacques", 1.5], ["charlene", 2.0], ["Prince Jacques", 3.75], ["Grace Kelly", 4.0], ["Prince Albert II", 7.75], ["gabriella", 2.0], ["Prince Albert", 4.75]], "JJ": [["zimbabwean-born", 1.0], ["twin", 1.4]], "VBD": [["was founded", 4.5]], "VBG": [["Jacques arriving", 3.5]], "XXX": [["prince has", 4.916666666666666], ["couple married", 4.0], ["Princess Charlene has", 7.666666666666666], ["throne because", 4.0], ["palace has announced", 8.666666666666666], ["Gabriella was born", 6.5], ["royal family since", 8.0]], "NN": [["Olympic swimmer", 4.0], ["line", 1.0], ["pregnancy", 1.0], ["secret", 1.0], ["child", 1.0], ["statement", 1.0], ["marriage", 1.0], ["rich principality", 4.0], ["role", 1.0], ["southern French coast", 9.0], ["birth", 1.0], ["gender", 1.0], ["late Hollywood actress", 9.0], ["Monaco throne", 3.25], ["become next-in-line", 4.0], ["mixed sex", 4.0], ["infant", 1.0], ["father", 1.0]]}
134	Iowa poll: Donald Trump builds on lead over Ted Cruz	1	http://www.cnn.com/2016/01/27/politics/donald-trump-leads-ted-cruz-iowa-poll/index.html	134_1_Iowa_poll__Donald_Trump_builds_on_lead_over_Ted_Cruz.txt	{"NNP": [["Ted Cruz", 4.0], ["Cruz leads Trump", 7.435714285714286], ["iowa", 2.0]], "RB": [["only", 1.3333333333333333]], "NN": [["poll", 2.0], ["lead", 1.0], ["Iowa poll", 4.0], ["polling", 2.0], ["choice", 1.0]], "NNS": [["caucus-goers", 1.6666666666666667], ["voters", 1.875]]}
136	Filing in 'Serial' appeal postponed	1	http://www.baltimoresun.com/news/maryland/crime/bs-md-serial-appeal-20150316-story.html	136_1_Filing_in_'Serial'_appeal_postponed.txt	{"VBN": [["pushed", 1.0]], "VB": [["file", 1.6666666666666667], ["listen", 1.0], ["appeal", 1.75]], "NNS": [["arguments", 2.0], ["listeners", 1.0]], "NNP": [["court", 1.75], ["april", 1.0]], "NNPS": [["appeals", 1.75]], "VBD": [["pushed", 1.0]], "NN": [["appeal", 1.75], ["court", 1.75], ["week", 1.0], ["filing", 2.666666666666667], ["argument", 2.0], ["deadline", 1.5], ["case", 1.0]]}
131	Get Ready For Comet Pan-STARRS To (Briefly) Grace Our Sky	1	http://www.slate.com/blogs/bad_astronomy/2013/03/07/comet_pan_starrs_bright_comet_will_be_visible_starting_around_march_8.html	131_1_Get_Ready_For_Comet_Pan-STARRS_To_(Briefly)_Grace_Our_Sky.txt	{"VB": [["find", 1.0], ["spot", 1.0]], "JJ": [["bright", 1.2857142857142858]], "NNS": [["comets", 1.5], ["years", 1.0], ["binoculars", 1.0]], "NNP": [["pan-starrs", 1.4], ["grace", 1.0], ["mar.", 1.5], ["ready", 1.0], ["comet", 1.5], ["Comet Pan-STARRS", 4.0], ["earth", 1.0], ["telescope", 1.6]], "VBD": [["spotted", 1.0]], "VBG": [["spotting", 1.0]], "NN": [["comet", 1.5], ["orbit", 1.4], ["pan-starrs", 1.4], ["telescope", 1.6], ["year", 1.0]]}
132	Kanye West Says He’s Executive Producing Rihanna’s New Album	1	http://time.com/3700262/grammys-2015-rihanna-kanye-west-producing-new-album/	132_1_Kanye_West_Says_He’s_Executive_Producing_Rihanna’s_New_Album.txt	{"VB": [["perform", 1.0]], "NNS": [["anticipated albums", 4.5], ["details", 1.0]], "NNP": [["rihanna", 1.0], ["mccartney", 1.0], ["Kanye West", 4.0], ["album", 1.0], ["was West", 4.0]], "NNPS": [["fourfiveseconds", 1.5]], "VBD": [["shared", 1.0], ["was West", 4.0]], "VBG": [["following", 1.0], ["executive producing", 4.0]], "XXX": [["West announced", 4.0], ["Yeezus treatment Finally", 9.0], ["awards show", 4.0]], "NN": [["stage", 1.0], ["store", 1.0], ["time", 1.0], ["news", 1.0], ["hashtag", 1.0], ["upcoming record", 4.0], ["premiere", 1.0], ["month", 1.0], ["eighth studio album", 8.5], ["year", 1.0]]}
135	Groundhog Day 2015: Punxsutawney Phil sees shadow, predicts six more weeks of winter	1	https://www.washingtonpost.com/news/capital-weather-gang/wp/2015/02/02/groundhog-day-2015-punxsutawney-phil-sees-shadow-predicts-six-more-weeks-of-winter/	135_1_Groundhog_Day_2015__Punxsutawney_Phil_sees_shadow,_predicts_six_more_weeks_of_winter.txt	{"NN": [["shadow", 2.25], ["winter", 2.7142857142857144], ["forecast", 1.5], ["year", 1.3333333333333333]], "NNS": [["forecasts", 1.5], ["weeks", 1.0], ["years", 1.3333333333333333], ["winters", 1.7142857142857142]]}
137	Chipotle’s food-safety issues might make it the safest place to eat	1	http://www.marketwatch.com/story/chipotles-food-safety-issues-might-make-it-the-safest-place-to-eat-2015-12-18	137_1_Chipotle’s_food-safety_issues_might_make_it_the_safest_place_to_eat.txt	{"NNP": [["chipotle", 1.3333333333333333], ["kingra", 1.0]], "IN": [["because", 1.25]], "NN": [["safest place", 4.0], ["attention", 1.0], ["company", 1.0], ["food", 2.0]]}
141	Tina Fey Signs First-Look Production Deal with Universal	1	http://www.comingsoon.net/movies/news/653501-tina-fey-signs-first-look-production-deal-with-universal	141_1_Tina_Fey_Signs_First-Look_Production_Deal_with_Universal.txt	{"NN": [["Little Stranger", 4.0]]}
142	Will Britain leave the European Union?	1	http://www.latimes.com/world/europe/la-fg-britain-european-union-20160203-story.html	142_1_Will_Britain_leave_the_European_Union?.txt	{"NN": [["deal", 1.7142857142857142], ["leader", 1.25], ["union", 1.8181818181818181], ["referendum", 1.1428571428571428], ["member", 1.4285714285714286]], "NNP": [["britain", 1.4545454545454546], ["cameron", 1.1666666666666667], ["union", 1.8181818181818181], ["European Union", 8.068181818181818]], "NNS": [["members", 1.4285714285714286], ["leaders", 1.25]]}
143	U.S., 11 nations formally sign largest regional trade deal in history	1	https://www.washingtonpost.com/politics/us-11-nations-formally-sign-largest-regional-trade-deal-in-history/2016/02/03/2db4ab26-caa4-11e5-88ff-e2d1b4289c2f_story.html	143_1_U.S.,_11_nations_formally_sign_largest_regional_trade_deal_in_history.txt	{"NNS": [["years", 1.0]], "NN": [["vote", 1.5], ["year", 1.0], ["history", 1.0], ["signing", 1.6666666666666667], ["agreement", 1.0]], "VBN": [["signed", 1.6666666666666667]], "VBD": [["signed", 1.6666666666666667]], "VB": [["vote", 1.5], ["sign", 1.6666666666666667]], "NNP": [["congress", 1.3333333333333333]]}
145	Contraception Fell, Medicaid Births Went Up When Texas Defunded Planned Parenthood	1	http://www.nbcnews.com/health/health-care/contraception-fell-medicaid-births-went-when-texas-defunded-planned-parenthood-n510736	145_1_Contraception_Fell,_Medicaid_Births_Went_Up_When_Texas_Defunded_Planned_Parenthood.txt	{"JJ": [["long-acting", 1.5]], "VBN": [["claimed", 1.25]], "NN": [["claim", 1.25], ["rate", 1.0], ["Contraception Fell", 4.0], ["percent", 1.5], ["number", 1.0], ["team", 1.25]], "NNP": [["Planned Parenthood", 5.454545454545454], ["texas", 1.4444444444444444], ["women", 1.5], ["Medicaid Births", 4.0]], "NNS": [["Planned Parenthood clinics", 8.454545454545453], ["counties", 1.0], ["claims", 1.25], ["rates", 1.0], ["women", 1.5]]}
146	US Stocks Stage a Late Turnaround, Led by the Energy Sector	1	http://www.nytimes.com/aponline/2016/02/03/world/asia/ap-financial-markets.html?_r=0	146_1_US_Stocks_Stage_a_Late_Turnaround,_Led_by_the_Energy_Sector.txt	{"JJ": [["close", 1.0]], "VB": [["close", 1.0]], "NNP": [["benchmark", 1.0], ["wednesday", 1.0], ["Stocks Stage", 4.0], ["Late Turnaround", 4.0], ["Energy Sector", 4.0]], "NN": [["year", 1.0], ["percent", 2.142857142857143], ["dollar", 1.4], ["benchmark", 1.0], ["barrel", 1.0]], "NNS": [["rate hikes", 3.8], ["currencies", 1.0], ["years", 1.0]]}
156	U.S. military generals want women to register for draft	1	http://www.cnn.com/2016/02/02/politics/women-military-draft-generals/index.html	156_1_U.S._military_generals_want_women_to_register_for_draft.txt	{"VB": [["register", 2.0], ["change", 1.3333333333333333]], "VBP": [["register", 1.0]], "NNS": [["combat jobs", 3.75], ["women", 2.625], ["exempt women", 3.625], ["military generals", 4.0], ["restrictions", 1.0]], "VBG": [["registering", 1.0]], "NN": [["national debate", 4.0], ["basis", 1.0], ["draft", 2.0], ["issue", 1.0]], "VBN": [["restricted", 1.0], ["changed", 1.3333333333333333], ["drafted", 1.0]]}
158	Woman assaulted by PC who lost his job found dead in Holloway cell	1	http://www.theguardian.com/society/2016/feb/03/sarah-reed-assaulted-by-pc-dead-holloway-prison	158_1_Woman_assaulted_by_PC_who_lost_his_job_found_dead_in_Holloway_cell.txt	{"NN": [["family", 1.0], ["Holloway cell", 4.0], ["assault", 1.0]]}
138	Zika has been sexually transmitted in Texas, CDC confirms	1	http://www.cnn.com/2016/02/02/health/zika-virus-sexual-contact-texas/index.html	138_1_Zika_has_been_sexually_transmitted_in_Texas,_CDC_confirms.txt	{"VBN": [["spread", 1.25]], "VBG": [["spreading", 1.25]], "NN": [["spread", 1.25], ["case", 1.375], ["area", 1.5], ["virus", 1.6428571428571428], ["French Polynesia", 4.0]], "NNS": [["cases", 1.375], ["areas", 1.5]]}
139	Obama rebuts anti-Muslim rhetoric in first U.S. mosque visit	1	http://www.cnn.com/2016/02/03/politics/obama-mosque-visit-muslim-rhetoric/	139_1_Obama_rebuts_anti-Muslim_rhetoric_in_first_U.S._mosque_visit.txt	{"VBN": [["worried", 1.0], ["visited", 1.25]], "NNP": [["mosque", 1.25], ["islam", 1.5714285714285714], ["obama", 1.8181818181818181], ["american", 1.25], ["wednesday", 1.4], ["america", 1.3333333333333333]], "NNS": [["mosques", 1.25], ["children", 1.0], ["worries", 1.0], ["countries", 1.1428571428571428], ["faiths", 1.0]], "JJ": [["muslim", 1.7], ["american", 1.25], ["islamic", 1.5714285714285714]], "VB": [["stop", 1.0], ["visit", 1.25]], "VBP": [["worry", 1.0]], "NNPS": [["americans", 1.25], ["muslims", 1.7], ["United States", 3.833333333333333]], "NN": [["mosque", 1.25], ["mosque visit", 4.0], ["speech", 1.0], ["stop", 1.0], ["visit", 1.25], ["country", 1.1428571428571428], ["faith", 1.0]]}
140	IRS says experiencing computer failure	1	http://www.reuters.com/article/us-usa-irs-computers-idUSKCN0VC2X2	140_1_IRS_says_experiencing_computer_failure.txt	{"VBZ": [["anticipates", 1.0]], "VBG": [["currently operating", 4.0], ["including", 1.0]], "NN": [["modernized e-file system", 7.8], ["site", 1.0], ["taxpayer", 1.0], ["agency", 1.0], ["number", 1.0], ["statement", 1.0], ["refund", 1.0], ["experiencing computer failure", 18.0], ["system", 1.8], ["process", 1.0]], "VB": [["expect", 1.0], ["remain unavailable", 4.5], ["anticipate", 1.0], ["receive", 1.0]], "JJ": [["unavailable", 1.5], ["several", 1.5]], "RB": [["temporarily", 1.0]], "NNS": [["several systems", 3.3], ["related systems", 3.8], ["tax practitioner tools", 9.0], ["refunds", 1.0], ["systems", 1.8], ["taxpayers", 1.0], ["services", 2.0], ["making repairs", 4.0]], "VBP": [["continue", 1.0]], "NNP": [["thursday", 1.0], ["wednesday", 1.0], ["service", 2.0], ["Internal Revenue Service", 8.0]]}
144	Kanye West: Waves is 'ONE of the greatest albums not the greatest'	1	http://www.ew.com/article/2016/02/03/kanye-west-waves-one-greatest-albums	144_1_Kanye_West__Waves_is_'ONE_of_the_greatest_albums_not_the_greatest'.txt	{"VB": [["premiere", 1.0], ["denounce", 1.0]], "VBD": [["was once called", 8.5]], "VBN": [["scheduled", 1.0]], "NNP": [["feb.", 1.0], ["trumka", 1.0], ["Capitol Hill", 4.0], ["washington", 1.0], ["Madison Square Garden", 9.0], ["Kanye West", 4.0]], "VBZ": [["has spent", 4.0], ["waves", 1.0]], "XXX": [["fans polled", 4.0], ["Kim Kardashian preferred", 9.0], ["protesters gathered", 4.0], ["environmentalists distributed", 4.0], ["pact purportedly signed", 9.0], ["West called", 4.5]], "RB": [["worldwide", 1.0]], "VBG": [["tinkering", 1.0]], "NNS": [["American people", 4.0], ["lawmakers", 1.0], ["waves", 2.0], ["labor union officials", 9.0], ["million people", 4.0], ["theaters", 1.0], ["greatest albums", 3.5], ["hundreds", 1.0]], "JJ": [["toxic", 1.0], ["good", 1.0]], "IN": [["outside", 1.0]], "NNPS": [["House Democrats", 4.0], ["United States", 4.0]], "NN": [["event broadcast", 4.0], ["record", 1.0], ["week", 1.0], ["world", 1.0], ["deal", 1.0], ["meeting", 1.0], ["collection", 1.0], ["swish", 1.0], ["simple message", 4.0], ["time", 1.0], ["agreement", 1.0], ["album", 1.0], ["group", 1.0], ["ballot", 1.0], ["online petition", 4.0], ["news conference", 4.0]]}
151	Random Chance’s Role in Cancer	1	http://www.nytimes.com/2015/01/20/science/though-we-long-for-control-chance-plays-a-powerful-role-in-the-biology-of-cancer-and-the-evolution-of-life.html	151_1_Random_Chance’s_Role_in_Cancer.txt	{"NNS": [["cancers", 1.8846153846153846]], "NN": [["body", 1.0], ["world", 1.25], ["lung cancer", 3.6346153846153846], ["percent", 1.0], ["cancer", 2.8846153846153846], ["role", 1.0], ["chance", 1.25]], "NNP": [["world", 1.25], ["cancer", 1.8846153846153846]]}
152	5-year-old boy holds wedding for his pony	1	http://www.cnn.com/2016/02/02/living/pony-horse-wedding-louisiana-feat/index.html	152_1_5-year-old_boy_holds_wedding_for_his_pony.txt	{"VB": [["call", 1.0]], "NN": [["pony", 1.0], ["grandfather", 1.0], ["tutu", 1.0], ["ceremony", 1.0]], "VBZ": [["calls", 1.0]], "NNP": [["daddy", 1.0], ["gabe", 1.25], ["butterball", 1.1666666666666667], ["coushatta", 1.0], ["logan", 1.25]]}
154	Computer scores big win against humans in ancient game of Go	1	http://money.cnn.com/2016/01/28/technology/google-computer-program-beats-human-at-go/index.html?iid=ob_homepage_tech_pool&iid=obnetwork	154_1_Computer_scores_big_win_against_humans_in_ancient_game_of_Go.txt	{"NNS": [["experts", 1.0], ["pieces", 1.0], ["researchers", 1.6666666666666667], ["games", 2.0], ["humans", 1.0]], "NN": [["researcher", 1.6666666666666667], ["game", 2.0], ["ancient game", 4.0], ["board", 1.75], ["number", 1.0]], "VBN": [["believed", 1.0]]}
155	Graham Gano: if I win the Super Bowl I'll go home to Arbroath	1	http://www.theguardian.com/sport/2016/feb/03/graham-gano-if-i-win-the-super-bowl-ill-go-home-to-arbroath	155_1_Graham_Gano__if_I_win_the_Super_Bowl_I'll_go_home_to_Arbroath.txt	{"VB": [["make", 1.25]], "VBZ": [["makes", 1.25]], "NNS": [["weeks", 1.0], ["yards", 1.0]], "VBG": [["making", 1.25]], "NN": [["home", 1.0], ["week", 1.0], ["kicker", 1.0], ["year", 1.3333333333333333]], "NNP": [["arbroath", 2.0], ["Graham Gano", 4.0], ["gano", 1.7857142857142858], ["Super Bowl", 8.0]]}
157	Resting bitch face' is real, scientists say	1	http://www.cnn.com/2016/02/03/health/resting-bitch-face-research-irpt/index.html	157_1_Resting_bitch_face'_is_real,_scientists_say.txt	{"VB": [["show", 1.4], ["smile", 1.2]], "VBP": [["show", 1.4]], "NNS": [["celebrities", 1.0], ["scientists", 1.0], ["faces", 1.588235294117647], ["emotions", 1.4444444444444444], ["people", 1.375]], "VBG": [["according", 1.0], ["smiling", 1.2], ["showing", 1.4]], "NN": [["face", 1.588235294117647], ["software", 1.4], ["Resting bitch face", 9.0], ["emotionality", 1.4444444444444444], ["emotion", 1.4444444444444444]], "JJ": [["real", 1.0], ["neutral", 1.2]], "NNP": [["youn", 1.0], ["face", 1.588235294117647], ["macbeth", 1.3333333333333333]]}
147	Google Expands Its Self-Driving Car Pilot To Kirkland, Wash.	1	http://techcrunch.com/2016/02/03/google-expands-its-self-driving-car-pilot-to-kirkland/	147_1_Google_Expands_Its_Self-Driving_Car_Pilot_To_Kirkland,_Wash..txt	{"VB": [["expand", 1.0], ["test", 1.25]], "NNS": [["tests", 1.25], ["areas", 1.0], ["engineers", 1.0]], "VBG": [["welcoming", 1.0], ["expanding", 1.0], ["testing", 1.25]], "NN": [["area", 1.0], ["testing", 1.25]], "JJ": [["welcome", 1.0]], "NNP": [["kirkland", 2.8], ["wash.", 1.0], ["google", 1.2857142857142858]]}
148	Someone nominated Donald Trump for the Nobel Peace Prize	1	http://www.cnn.com/2016/02/03/politics/donald-trump-nobel-peace-prize/	148_1_Someone_nominated_Donald_Trump_for_the_Nobel_Peace_Prize.txt	{"VB": [["receive", 1.0], ["reveal", 1.0], ["nominate", 1.5]], "NN": [["nominator", 1.5], ["award", 1.0]], "NNP": [["Nobel Peace Prize", 17.5]], "VBN": [["nominated", 1.5]]}
149	Kerry warns about Syria's continued airstrikes	1	http://www.cbsnews.com/news/john-kerry-warns-about-syrias-continued-airstrikes/	149_1_Kerry_warns_about_Syria's_continued_airstrikes.txt	{"VB": [["negotiate", 1.6666666666666667], ["lift", 1.0]], "NNS": [["Russian airstrikes", 4.0], ["supporters", 1.4], ["talks", 1.375], ["civilians", 1.3333333333333333], ["villages", 1.2], ["negotiations", 1.6666666666666667], ["continued airstrikes", 4.0]], "VBG": [["negotiating", 1.6666666666666667], ["talking", 1.375]], "NN": [["support", 1.4], ["statement", 1.0], ["bombardment", 1.0], ["failure", 1.0], ["government", 1.5], ["lifting", 1.0], ["regime", 1.25], ["opposition", 1.4545454545454546]], "JJ": [["civilian", 1.3333333333333333]], "NNP": [["geneva", 1.2], ["aleppo", 1.4285714285714286], ["de Mistura", 4.333333333333333]], "VBN": [["supported", 1.4]]}
150	Barclays Center in Brooklyn Becomes a Classroom	1	http://www.nytimes.com/2016/02/02/nyregion/ninth-graders-learn-the-lessons-of-brooklyn-sports-history.html	150_1_Barclays_Center_in_Brooklyn_Becomes_a_Classroom.txt	{"NNS": [["teams", 1.25], ["ninth graders", 4.0], ["homes", 1.0], ["students", 1.3333333333333333], ["buildings", 1.25]], "VB": [["build", 1.25]], "NN": [["arena", 1.4], ["student", 1.3333333333333333], ["home", 1.0], ["team", 1.25], ["part", 1.25]], "NNP": [["Barclays Center", 8.307692307692307], ["brooklyn", 1.5384615384615385], ["building", 1.25], ["classroom", 1.0]]}
159	Headteacher mocked on Twitter for claiming evolution is not a fact	1	http://www.theguardian.com/world/2016/feb/03/headteacher-mocked-twitter-claim-evolution-not-fact	159_1_Headteacher_mocked_on_Twitter_for_claiming_evolution_is_not_a_fact.txt	{"VB": [["teach", 1.1428571428571428]], "VBP": [["teach", 1.1428571428571428]], "NNS": [["schools", 1.5714285714285714], ["teachers", 1.25], ["facts", 1.6]], "VBG": [["teaching", 1.1428571428571428]], "NN": [["headteacher", 1.0], ["science", 1.4285714285714286], ["teaching", 1.1428571428571428], ["evidence", 1.25], ["claiming evolution", 4.0], ["evolution", 1.5], ["fact", 2.6], ["education", 1.5], ["school", 1.5714285714285714]], "NNP": [["twitter", 1.0], ["bible", 1.0]]}
165	A boy's life in Afghanistan: Anti-Taliban fighter at 9, dead at 12	1	http://www.latimes.com/world/asia/la-fg-afghanistan-boy-fighter-20160203-story.html	165_1_A_boy's_life_in_Afghanistan__Anti-Taliban_fighter_at_9,_dead_at_12.txt	{"NN": [["life", 1.0], ["government", 1.875], ["uncle", 1.0]], "NNP": [["samad", 1.1666666666666667], ["taliban", 1.6363636363636365], ["afghanistan", 1.0]]}
166	ChemChina, Syngenta to move quickly on U.S. national security review	1	http://www.reuters.com/article/us-syngenta-m-a-cfius-idUSKCN0VD03C	166_1_ChemChina,_Syngenta_to_move_quickly_on_U.S._national_security_review.txt	{"NN": [["deal", 1.5], ["national security review", 9.0]], "NNS": [["deals", 1.5], ["facilities", 1.25], ["cfius", 1.4]], "NNP": [["chemchina", 1.0], ["syngenta", 1.0], ["cfius", 1.4]]}
160	For transgender 9-year-old, a very Girl Scout lesson	1	http://www.csmonitor.com/USA/Society/2016/0203/For-transgender-9-year-old-a-very-Girl-Scout-lesson	160_1_For_transgender_9-year-old,_a_very_Girl_Scout_lesson.txt	{"NN": [["troop", 1.6666666666666667], ["time", 1.2], ["girl", 2.2777777777777777], ["founding", 1.0]], "NNS": [["girls", 2.2777777777777777], ["troops", 1.6666666666666667], ["Boy Scouts", 4.3589743589743595], ["Girl Scouts", 4.47008547008547], ["times", 1.2], ["changes", 1.0]], "VBN": [["changed", 1.0], ["founded", 1.0]], "VBD": [["found", 1.0]], "NNP": [["stormi", 1.0], ["girl", 2.2777777777777777]], "VBG": [["changing", 1.0]]}
161	Flint Residents Bring Brown Water And Clumps Of Hair To Washington	1	http://www.huffingtonpost.com/entry/flint-water-congress_us_56b22bb8e4b01d80b244af92	161_1_Flint_Residents_Bring_Brown_Water_And_Clumps_Of_Hair_To_Washington.txt	{"VB": [["make", 1.0], ["drink", 1.3333333333333333]], "NN": [["family", 1.625], ["water", 1.6363636363636365], ["crisis", 1.5], ["home", 1.6]], "NNS": [["families", 1.625], ["people", 1.25], ["homes", 1.6]], "VBP": [["drink", 1.3333333333333333]], "NNP": [["clumps", 1.0], ["washington", 1.0], ["flint", 1.5714285714285714], ["hair", 1.0]], "VBG": [["drinking", 1.3333333333333333], ["making", 1.0]]}
162	Hundreds Of Immigration Court Interpreters Say They Haven’t Been Paid Since Last Year	1	http://www.buzzfeed.com/adolfoflores/hundreds-of-immigration-court-interpreters-say-the#.sm702Vazr	162_1_Hundreds_Of_Immigration_Court_Interpreters_Say_They_Haven’t_Been_Paid_Since_Last_Year.txt	{"VB": [["work", 1.5]], "NN": [["sosi", 1.2307692307692308], ["interpreter", 1.84], ["email", 1.2], ["working", 1.5], ["contract", 1.3333333333333333], ["work", 1.5], ["issue", 1.4], ["maga\\u00f1a", 4.666666666666667], ["year", 2.571428571428571], ["interpretation", 1.84]], "NNS": [["sosi", 1.2307692307692308], ["issues", 1.4], ["emails", 1.2], ["interpreters", 1.84], ["cases", 1.6], ["years", 1.5714285714285714], ["hundreds", 1.0], ["contracts", 1.3333333333333333]], "FW": [["sosi", 1.2307692307692308]], "VBZ": [["works", 1.5]], "VBN": [["contracted", 1.3333333333333333], ["paid", 1.4285714285714286], ["Paid Since", 4.0]], "VBD": [["worked", 1.5]], "NNP": [["maga\\u00f1a", 4.666666666666667], ["sosi", 1.2307692307692308], ["year", 1.5714285714285714]], "VBG": [["working", 1.5], ["interpreting", 1.84]]}
163	A Clinton Aide Once Called Hillary 'Quite Culturally Conservative'	1	http://www.huffingtonpost.com/entry/bernie-sanders-hillary-clinton-progressive_us_56b26c0fe4b08069c7a5e95b	163_1_A_Clinton_Aide_Once_Called_Hillary_'Quite_Culturally_Conservative'.txt	{"VB": [["make", 1.0]], "NN": [["progress", 1.75], ["time", 1.0]], "NNS": [["things", 1.0], ["progressives", 1.75]], "JJ": [["progressive", 1.75]], "VBZ": [["makes", 1.0]], "RB": [["always", 1.0]], "NNP": [["reed", 1.4], ["clinton", 1.4705882352941178]], "VBG": [["making", 1.0]]}
164	Seeding Peace in Syria	1	http://www.huffingtonpost.com/irina-bokova/seeding-peace-in-syria_b_9147658.html	164_1_Seeding_Peace_in_Syria.txt	{"NN": [["peace", 1.5833333333333333], ["education", 1.6875], ["violence", 1.0], ["crisis", 1.6], ["future", 1.25], ["Seeding Peace", 4.0], ["higher education", 3.6875], ["youth", 1.8], ["violent extremism", 4.5]], "NNS": [["young women", 4.166666666666666], ["crises", 1.6]], "JJ": [["educational", 1.6875], ["future", 1.25], ["secondary", 1.0]], "NNP": [["peace", 1.5833333333333333], ["syria", 2.7272727272727275], ["youth", 1.8], ["education", 1.6875]]}
\.


--
-- Name: articles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: username-to-replace
--

SELECT pg_catalog.setval('articles_id_seq', 167, true);


--
-- Data for Name: feeds; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY feeds (id, feed_name, source, url, scrapers, lastseen) FROM stdin;
1	CNN_US	2	http://rss.cnn.com/rss/cnn_us.rss	{CNN}	\N
\.


--
-- Name: feeds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: username-to-replace
--

SELECT pg_catalog.setval('feeds_id_seq', 3, true);


--
-- Data for Name: queries; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY queries (id, userid, subject, verb, direct_obj, indirect_obj, loc, processed, enabled) FROM stdin;
1	1	obama	speaks	in chicago			t	t
2	1	obama	visits	chicago			t	t
4	1	ted cruz	wins	2016 iowa caucus			t	t
5	1	ted cruz	wins	caucus			t	t
7	1	rihanna	releases	anti album			t	t
8	1	rihanna	releases	album			t	t
16	1	chipotle	has	e. coli outbreak			t	t
17	1	chipotle	has	outbreak			t	t
22	1	uber	changes	logo			t	t
23	1	tech company	changes	logo			t	t
44	1	hurricane	hits			us	t	t
45	1	natural disaster	occurs			in us	t	t
10	1	kate middleton	gives birth				t	t
11	1	princess	gives birth				t	t
13	1	comet catalina	becomes visible				t	t
14	1	comet	becomes visible				t	t
19	1	school shooting	occurs				t	t
20	1	mass shooting	occurs				t	t
25	1	candidate	drops out		of presidential race		t	t
26	1	martin o'malley	drops out		of presidential race		t	t
28	1	carolina panthers	are		in super bowl 50		t	t
31	1	punxsutawney phil	does not see	shadow			t	t
32	1	groundhog	does not see	shadow			t	t
34	1	twitter	lays off	employees			t	t
35	1	tech company	lays off	employees			t	t
37	1	amy winehouse	dies				t	t
38	1	someone famous	dies				t	t
29	1	carolina panthers	are		in super bowl		t	t
40	1	adnan syed	goes to court		for retrial		t	t
43	1	adnan syed	goes to court				t	t
3	1	obama	does not visit	chicago			t	f
6	1	ted cruz	does not win	caucus			t	f
9	1	rihanna	does not release	album			t	f
18	1	chipotle	does not have	outbreak			t	f
24	1	uber	does not change	logo			t	f
46	1	hurricane	does not hit			us	t	f
12	1	kate middleton	does not give birth				t	f
15	1	comet	does not become visible				t	f
21	1	school shooting	does not occur				t	f
27	1	martin o'malley	does not drop out		of presidential race		t	f
33	1	groundhog	sees	shadow			t	f
36	1	twitter	does not lay off	employees			t	f
30	1	carolina panthers	are not		in super bowl 50		t	f
39	1	amy winehouse	does not die				t	f
42	1	adnan syed	does not go to court				t	f
\.


--
-- Name: queries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: username-to-replace
--

SELECT pg_catalog.setval('queries_id_seq', 46, true);


--
-- Data for Name: query_articles; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY query_articles (query, article, accuracy, processed, validates) FROM stdin;
1	91	0	t	f
1	92	0	t	f
1	93	0	t	f
1	98	0	t	f
1	89	0	t	f
1	94	0	t	f
1	95	0	t	f
1	97	0	t	f
1	99	0	t	f
1	100	0	t	f
1	101	0	t	f
1	104	0	t	f
1	102	0	t	f
1	107	0	t	f
1	116	0	t	f
1	113	0	t	f
1	118	0	t	f
1	105	0	t	f
1	106	0	t	f
1	108	0	t	f
1	109	0	t	f
1	110	0	t	f
1	111	0	t	f
1	112	0	t	f
1	121	0	t	f
1	122	0	t	f
1	124	0	t	f
1	115	0	t	f
1	117	0	t	f
1	119	0	t	f
1	120	0	t	f
1	123	0	t	f
1	126	0	t	f
1	128	0	t	f
1	129	0	t	f
1	125	0	t	f
1	127	0	t	f
1	133	0	t	f
1	134	0	t	f
1	136	0	t	f
1	131	0	t	f
1	132	0	t	f
1	135	0	t	f
1	137	0	t	f
1	141	0	t	f
1	142	0	t	f
1	143	0	t	f
1	146	0	t	f
1	156	0	t	f
1	158	0	t	f
1	138	0	t	f
1	139	0	t	f
1	140	0	t	f
1	144	0	t	f
1	151	0	t	f
1	152	0	t	f
1	153	0	t	f
1	155	0	t	f
1	157	0	t	f
1	147	0	t	f
1	148	0	t	f
1	149	0	t	f
1	150	0	t	f
1	159	0	t	f
1	165	0	t	f
1	166	0	t	f
1	160	0	t	f
1	162	0	t	f
1	163	0	t	f
1	164	0	t	f
2	90	0	t	f
2	91	0	t	f
2	92	0	t	f
2	93	0	t	f
2	98	0	t	f
2	89	0	t	f
2	94	0	t	f
2	96	0	t	f
2	97	0	t	f
2	99	0	t	f
2	100	0	t	f
2	101	0	t	f
2	104	0	t	f
2	102	0	t	f
2	107	0	t	f
2	116	0	t	f
2	113	0	t	f
2	103	0	t	f
2	105	0	t	f
2	106	0	t	f
2	108	0	t	f
2	109	0	t	f
2	110	0	t	f
2	111	0	t	f
2	112	0	t	f
2	121	0	t	f
2	122	0	t	f
2	114	0	t	f
2	115	0	t	f
2	117	0	t	f
2	119	0	t	f
2	120	0	t	f
2	123	0	t	f
2	126	0	t	f
2	128	0	t	f
2	129	0	t	f
3	121	0	t	f
3	122	0	t	f
3	124	0	t	f
3	114	0	t	f
3	115	0	t	f
3	117	0	t	f
3	119	0	t	f
3	123	0	t	f
3	126	0	t	f
3	128	0	t	f
3	129	0	t	f
3	125	0	t	f
3	127	0	t	f
3	130	0	t	f
3	133	0	t	f
3	134	0	t	f
3	136	0	t	f
3	132	0	t	f
3	135	0	t	f
3	137	0	t	f
3	141	0	t	f
3	142	0	t	f
3	143	0	t	f
3	145	0	t	f
3	146	0	t	f
3	156	0	t	f
3	158	0	t	f
3	139	0	t	f
3	140	0	t	f
3	144	0	t	f
3	151	0	t	f
3	152	0.100000001	t	f
3	153	0	t	f
3	154	0	t	f
3	155	0	t	f
3	157	0	t	f
3	147	0	t	f
3	149	0	t	f
3	150	0	t	f
3	159	0	t	f
3	165	0	t	f
3	166	0	t	f
3	160	0	t	f
3	161	0	t	f
3	162	0	t	f
3	163	0	t	f
3	164	0	t	f
4	86	0	t	f
4	91	0	t	f
4	92	0	t	f
4	93	0	t	f
4	98	0	t	f
4	87	0	t	f
4	88	0	t	f
4	89	0	t	f
4	94	0	t	f
4	95	0	t	f
4	97	0	t	f
4	99	0	t	f
4	100	0	t	f
4	101	0	t	f
4	102	0	t	f
4	107	0	t	f
4	116	0	t	f
4	113	0	t	f
4	118	0	t	f
4	103	0	t	f
4	109	0	t	f
4	110	0	t	f
4	111	0	t	f
4	112	0	t	f
4	121	0	t	f
4	122	0	t	f
4	124	0	t	f
4	114	0	t	f
4	115	0	t	f
4	117	0	t	f
4	120	0	t	f
4	123	0	t	f
4	126	0	t	f
4	128	0	t	f
4	129	0	t	f
4	125	0	t	f
4	127	0	t	f
4	130	0	t	f
4	133	0	t	f
4	134	0	t	f
4	131	0	t	f
4	132	0	t	f
4	135	0	t	f
4	137	0	t	f
4	141	0	t	f
4	142	0	t	f
4	143	0	t	f
4	145	0	t	f
4	146	0	t	f
4	156	0	t	f
4	138	0	t	f
4	139	0	t	f
4	140	0	t	f
4	144	0	t	f
4	151	0	t	f
4	152	0	t	f
4	153	0	t	f
4	154	0	t	f
4	155	0	t	f
5	138	0	t	f
5	139	0	t	f
5	140	0	t	f
5	144	0	t	f
5	151	0	t	f
5	152	0	t	f
5	153	0	t	f
5	155	0	t	f
5	157	0	t	f
5	147	0	t	f
5	148	0	t	f
5	149	0	t	f
5	150	0	t	f
5	159	0	t	f
5	165	0	t	f
5	166	0	t	f
5	160	0	t	f
5	162	0	t	f
5	163	0	t	f
5	164	0	t	f
6	90	0	t	f
6	86	0	t	f
6	91	0	t	f
6	92	0	t	f
6	93	0	t	f
6	98	0	t	f
6	87	0	t	f
6	89	0	t	f
6	94	0	t	f
6	95	0	t	f
6	96	0	t	f
6	97	0	t	f
6	99	0	t	f
6	100	0	t	f
6	101	0	t	f
6	104	0	t	f
6	102	0	t	f
6	116	0	t	f
6	113	0	t	f
6	118	0	t	f
6	103	0	t	f
6	105	0	t	f
6	106	0	t	f
6	108	0	t	f
6	109	0	t	f
6	110	0	t	f
6	111	0	t	f
6	121	0	t	f
6	122	0	t	f
6	124	0	t	f
6	114	0	t	f
6	115	0	t	f
6	117	0	t	f
6	119	0	t	f
6	120	0	t	f
6	123	0	t	f
6	126	0	t	f
6	129	0	t	f
6	125	0	t	f
6	127	0	t	f
6	130	0	t	f
6	133	0	t	f
6	134	0	t	f
6	136	0	t	f
6	131	0	t	f
6	132	0	t	f
6	135	0	t	f
6	141	0	t	f
6	142	0	t	f
6	143	0	t	f
6	145	0	t	f
6	146	0	t	f
6	156	0	t	f
6	158	0	t	f
6	138	0	t	f
6	139	0	t	f
6	140	0	t	f
6	151	0	t	f
6	152	0	t	f
6	153	0	t	f
6	154	0	t	f
6	155	0	t	f
6	157	0	t	f
6	147	0	t	f
6	148	0	t	f
6	149	0	t	f
6	150	0	t	f
6	165	0	t	f
6	166	0	t	f
6	160	0	t	f
6	161	0	t	f
6	162	0	t	f
6	163	0	t	f
6	164	0	t	f
7	90	0	t	f
7	86	0	t	f
7	91	0	t	f
7	87	0	t	f
7	88	0	t	f
7	89	0	t	f
7	95	0	t	f
7	96	0	t	f
7	97	0	t	f
7	99	0	t	f
7	100	0	t	f
7	101	0	t	f
8	114	0	f	f
8	115	0	f	f
8	117	0	f	f
8	119	0	f	f
8	120	0	f	f
8	123	0	f	f
8	126	0	f	f
8	128	0	f	f
8	129	0	f	f
8	125	0	f	f
8	127	0	f	f
8	130	0	f	f
8	133	0	f	f
8	134	0	f	f
8	136	0	f	f
8	131	0	f	f
8	132	0	f	f
8	135	0	f	f
8	137	0	f	f
8	141	0	f	f
8	142	0	f	f
8	143	0	f	f
8	145	0	f	f
8	146	0	f	f
8	156	0	f	f
8	158	0	f	f
8	138	0	f	f
8	139	0	f	f
8	140	0	f	f
8	144	0	f	f
8	151	0	f	f
8	152	0	f	f
8	153	0	f	f
8	154	0	f	f
8	155	0	f	f
8	157	0	f	f
8	147	0	f	f
8	148	0	f	f
8	149	0	f	f
8	150	0	f	f
8	159	0	f	f
8	165	0	f	f
8	166	0	f	f
8	160	0	f	f
8	161	0	f	f
8	162	0	f	f
8	163	0	f	f
8	164	0	f	f
9	90	0	f	f
9	86	0	f	f
9	91	0	f	f
9	92	0	f	f
9	93	0	f	f
9	98	0	f	f
9	87	0	f	f
9	88	0	f	f
9	89	0	f	f
9	94	0	f	f
9	95	0	f	f
9	96	0	f	f
9	97	0	f	f
9	99	0	f	f
9	100	0	f	f
9	101	0	f	f
9	104	0	f	f
9	102	0	f	f
9	107	0	f	f
9	116	0	f	f
9	113	0	f	f
9	118	0	f	f
9	103	0	f	f
9	105	0	f	f
9	106	0	f	f
9	108	0	f	f
9	109	0	f	f
9	110	0	f	f
9	111	0	f	f
9	112	0	f	f
9	121	0	f	f
9	122	0	f	f
9	124	0	f	f
9	114	0	f	f
9	115	0	f	f
9	117	0	f	f
9	119	0	f	f
9	120	0	f	f
9	123	0	f	f
9	126	0	f	f
9	128	0	f	f
9	129	0	f	f
9	125	0	f	f
9	127	0	f	f
9	130	0	f	f
9	133	0	f	f
9	134	0	f	f
9	136	0	f	f
9	131	0	f	f
9	132	0	f	f
9	135	0	f	f
9	137	0	f	f
9	141	0	f	f
9	142	0	f	f
9	143	0	f	f
9	145	0	f	f
9	146	0	f	f
9	156	0	f	f
9	158	0	f	f
9	138	0	f	f
9	139	0	f	f
9	140	0	f	f
9	144	0	f	f
9	151	0	f	f
9	152	0	f	f
9	153	0	f	f
9	154	0	f	f
9	155	0	f	f
9	157	0	f	f
9	147	0	f	f
9	148	0	f	f
9	149	0	f	f
9	150	0	f	f
9	159	0	f	f
9	165	0	f	f
9	166	0	f	f
9	160	0	f	f
9	161	0	f	f
9	162	0	f	f
9	163	0	f	f
9	164	0	f	f
16	90	0	f	f
16	86	0	f	f
16	91	0	f	f
16	92	0	f	f
16	93	0	f	f
16	87	0	f	f
16	88	0	f	f
16	89	0	f	f
16	94	0	f	f
16	95	0	f	f
16	98	0	f	t
16	96	0	f	f
16	97	0	f	f
16	101	0	f	f
16	104	0	f	f
16	102	0	f	f
16	107	0	f	f
16	116	0	f	f
16	113	0	f	f
16	118	0	f	f
16	103	0	f	f
16	105	0	f	f
16	106	0	f	f
16	108	0	f	f
16	109	0	f	f
16	110	0	f	f
16	111	0	f	f
16	112	0	f	f
16	121	0	f	f
8	87	0	t	f
8	88	0	t	f
8	89	0	t	f
8	95	0	t	f
8	96	0	t	f
8	97	0	t	f
8	99	0	t	f
8	101	0	t	f
8	104	0	t	f
8	102	0	t	f
8	107	0	t	f
8	116	0	t	f
8	113	0	t	f
8	118	0	t	f
8	103	0	t	f
8	105	0	t	f
8	106	0	t	f
8	109	0	t	f
8	110	0	t	f
8	111	0	t	f
8	112	0	t	f
8	121	0	t	f
8	122	0	t	f
8	124	0.333333343	t	f
16	122	0	f	f
16	124	0	f	f
16	114	0	f	f
16	115	0	f	f
16	117	0	f	f
16	119	0	f	f
16	120	0	f	f
16	123	0	f	f
16	126	0	f	f
16	128	0	f	f
16	129	0	f	f
16	125	0	f	f
16	127	0	f	f
16	130	0	f	f
16	133	0	f	f
16	134	0	f	f
16	136	0	f	f
16	131	0	f	f
16	132	0	f	f
16	135	0	f	f
16	137	0	f	f
16	141	0	f	f
16	142	0	f	f
16	143	0	f	f
16	145	0	f	f
16	146	0	f	f
16	156	0	f	f
16	158	0	f	f
16	138	0	f	f
16	139	0	f	f
16	140	0	f	f
16	144	0	f	f
16	151	0	f	f
16	152	0	f	f
16	153	0	f	f
16	154	0	f	f
16	155	0	f	f
16	157	0	f	f
16	147	0	f	f
16	148	0	f	f
16	149	0	f	f
16	150	0	f	f
16	159	0	f	f
16	165	0	f	f
16	166	0	f	f
16	160	0	f	f
16	161	0	f	f
16	162	0	f	f
16	163	0	f	f
16	164	0	f	f
17	90	0	f	f
17	86	0	f	f
17	91	0	f	f
17	92	0	f	f
17	93	0	f	f
17	87	0	f	f
17	88	0	f	f
17	89	0	f	f
17	94	0	f	f
17	95	0	f	f
17	96	0	f	f
17	97	0	f	f
17	101	0	f	f
17	104	0	f	f
17	102	0	f	f
17	107	0	f	f
17	116	0	f	f
17	113	0	f	f
17	118	0	f	f
17	103	0	f	f
17	105	0	f	f
17	106	0	f	f
17	108	0	f	f
17	109	0	f	f
17	110	0	f	f
17	111	0	f	f
17	112	0	f	f
17	121	0	f	f
17	122	0	f	f
17	124	0	f	f
17	114	0	f	f
17	115	0	f	f
17	117	0	f	f
17	119	0	f	f
17	120	0	f	f
17	123	0	f	f
17	126	0	f	f
17	128	0	f	f
17	129	0	f	f
17	125	0	f	f
17	127	0	f	f
17	130	0	f	f
17	133	0	f	f
17	134	0	f	f
17	136	0	f	f
17	131	0	f	f
17	132	0	f	f
17	135	0	f	f
17	137	0	f	f
17	141	0	f	f
17	142	0	f	f
17	143	0	f	f
17	145	0	f	f
17	146	0	f	f
17	156	0	f	f
17	158	0	f	f
17	138	0	f	f
17	139	0	f	f
17	140	0	f	f
17	144	0	f	f
17	151	0	f	f
17	152	0	f	f
17	153	0	f	f
17	154	0	f	f
17	155	0	f	f
17	157	0	f	f
17	147	0	f	f
17	148	0	f	f
17	149	0	f	f
17	150	0	f	f
17	159	0	f	f
17	165	0	f	f
17	166	0	f	f
17	160	0	f	f
17	161	0	f	f
17	162	0	f	f
17	163	0	f	f
17	164	0	f	f
18	90	0	f	f
18	86	0	f	f
18	91	0	f	f
18	92	0	f	f
18	93	0	f	f
18	98	0	f	f
18	87	0	f	f
18	88	0	f	f
18	89	0	f	f
18	94	0	f	f
18	95	0	f	f
18	96	0	f	f
18	97	0	f	f
18	99	0	f	f
18	100	0	f	f
18	101	0	f	f
18	104	0	f	f
18	102	0	f	f
18	107	0	f	f
18	116	0	f	f
18	113	0	f	f
18	118	0	f	f
18	103	0	f	f
18	105	0	f	f
18	106	0	f	f
18	108	0	f	f
18	109	0	f	f
18	110	0	f	f
18	111	0	f	f
18	112	0	f	f
18	121	0	f	f
18	122	0	f	f
18	124	0	f	f
18	114	0	f	f
18	115	0	f	f
18	117	0	f	f
18	119	0	f	f
18	120	0	f	f
18	123	0	f	f
18	126	0	f	f
18	128	0	f	f
18	129	0	f	f
18	125	0	f	f
18	127	0	f	f
18	130	0	f	f
18	133	0	f	f
18	134	0	f	f
18	136	0	f	f
18	131	0	f	f
18	132	0	f	f
18	135	0	f	f
18	137	0	f	f
18	141	0	f	f
18	142	0	f	f
18	143	0	f	f
18	145	0	f	f
18	146	0	f	f
18	156	0	f	f
18	158	0	f	f
18	138	0	f	f
18	139	0	f	f
18	140	0	f	f
18	144	0	f	f
18	151	0	f	f
18	152	0	f	f
18	153	0	f	f
18	154	0	f	f
18	155	0	f	f
18	157	0	f	f
18	147	0	f	f
18	148	0	f	f
18	149	0	f	f
18	150	0	f	f
18	159	0	f	f
18	165	0	f	f
18	166	0	f	f
18	160	0	f	f
18	161	0	f	f
18	162	0	f	f
18	163	0	f	f
18	164	0	f	f
22	90	0	f	f
22	86	0	f	f
22	91	0	f	f
22	92	0	f	f
22	93	0	f	f
22	98	0	f	f
22	87	0	f	f
22	88	0	f	f
22	89	0	f	f
22	94	0	f	f
22	95	0	f	f
22	96	0	f	f
22	97	0	f	f
22	99	0	f	f
22	100	0	f	f
22	101	0	f	f
22	104	0	f	f
22	102	0	f	f
22	116	0	f	f
22	113	0	f	f
22	118	0	f	f
22	103	0	f	f
22	105	0	f	f
22	106	0	f	f
22	110	0	f	f
22	111	0	f	f
22	112	0	f	f
22	121	0	f	f
22	122	0	f	f
22	124	0	f	f
22	114	0	f	f
22	115	0	f	f
22	117	0	f	f
22	119	0	f	f
22	120	0	f	f
22	123	0	f	f
22	126	0	f	f
22	128	0	f	f
22	129	0	f	f
22	125	0	f	f
22	127	0	f	f
22	130	0	f	f
22	133	0	f	f
22	134	0	f	f
22	136	0	f	f
22	131	0	f	f
22	132	0	f	f
22	135	0	f	f
22	137	0	f	f
22	141	0	f	f
22	142	0	f	f
22	143	0	f	f
22	145	0	f	f
22	146	0	f	f
22	156	0	f	f
22	158	0	f	f
22	138	0	f	f
22	139	0	f	f
22	140	0	f	f
22	144	0	f	f
22	151	0	f	f
22	152	0	f	f
22	153	0	f	f
22	154	0	f	f
22	155	0	f	f
22	157	0	f	f
22	147	0	f	f
22	148	0	f	f
22	149	0	f	f
22	150	0	f	f
22	159	0	f	f
22	165	0	f	f
22	166	0	f	f
22	160	0	f	f
22	161	0	f	f
22	162	0	f	f
22	163	0	f	f
22	164	0	f	f
23	90	0	f	f
23	86	0	f	f
23	91	0	f	f
23	92	0	f	f
23	93	0	f	f
23	98	0	f	f
23	87	0	f	f
23	88	0	f	f
23	89	0	f	f
23	94	0	f	f
23	95	0	f	f
23	96	0	f	f
23	97	0	f	f
23	99	0	f	f
23	100	0	f	f
23	101	0	f	f
23	104	0	f	f
23	102	0	f	f
23	116	0	f	f
23	113	0	f	f
23	118	0	f	f
23	103	0	f	f
23	105	0	f	f
23	106	0	f	f
23	110	0	f	f
23	111	0	f	f
23	112	0	f	f
23	121	0	f	f
23	122	0	f	f
23	124	0	f	f
23	114	0	f	f
23	115	0	f	f
23	117	0	f	f
23	119	0	f	f
23	120	0	f	f
23	123	0	f	f
23	126	0	f	f
23	128	0	f	f
23	129	0	f	f
23	125	0	f	f
23	127	0	f	f
23	130	0	f	f
23	133	0	f	f
23	134	0	f	f
23	136	0	f	f
23	131	0	f	f
23	132	0	f	f
23	135	0	f	f
23	137	0	f	f
23	141	0	f	f
23	142	0	f	f
23	143	0	f	f
23	145	0	f	f
23	146	0	f	f
23	156	0	f	f
23	158	0	f	f
23	138	0	f	f
23	139	0	f	f
23	140	0	f	f
23	144	0	f	f
23	151	0	f	f
23	152	0	f	f
23	153	0	f	f
23	154	0	f	f
23	155	0	f	f
23	157	0	f	f
23	147	0	f	f
23	148	0	f	f
23	149	0	f	f
23	150	0	f	f
23	159	0	f	f
23	165	0	f	f
23	166	0	f	f
23	160	0	f	f
23	161	0	f	f
23	162	0	f	f
23	163	0	f	f
23	164	0	f	f
24	90	0	f	f
24	86	0	f	f
24	91	0	f	f
24	92	0	f	f
24	93	0	f	f
24	98	0	f	f
24	87	0	f	f
24	88	0	f	f
24	89	0	f	f
24	94	0	f	f
24	95	0	f	f
24	96	0	f	f
24	97	0	f	f
24	99	0	f	f
24	100	0	f	f
24	101	0	f	f
24	104	0	f	f
24	102	0	f	f
24	107	0	f	f
24	116	0	f	f
24	113	0	f	f
24	118	0	f	f
24	103	0	f	f
24	105	0	f	f
24	106	0	f	f
24	108	0	f	f
24	109	0	f	f
24	110	0	f	f
24	111	0	f	f
24	112	0	f	f
24	121	0	f	f
24	122	0	f	f
24	124	0	f	f
24	114	0	f	f
24	115	0	f	f
24	117	0	f	f
24	119	0	f	f
24	120	0	f	f
24	123	0	f	f
24	126	0	f	f
24	128	0	f	f
24	129	0	f	f
24	125	0	f	f
24	127	0	f	f
24	130	0	f	f
24	133	0	f	f
24	134	0	f	f
24	136	0	f	f
24	131	0	f	f
24	132	0	f	f
24	135	0	f	f
24	137	0	f	f
24	141	0	f	f
24	142	0	f	f
24	143	0	f	f
24	145	0	f	f
24	146	0	f	f
24	156	0	f	f
24	158	0	f	f
24	138	0	f	f
24	139	0	f	f
24	140	0	f	f
24	144	0	f	f
24	151	0	f	f
24	152	0	f	f
24	153	0	f	f
24	154	0	f	f
24	155	0	f	f
24	157	0	f	f
24	147	0	f	f
24	148	0	f	f
24	149	0	f	f
24	150	0	f	f
24	159	0	f	f
24	165	0	f	f
24	166	0	f	f
24	160	0	f	f
24	161	0	f	f
24	162	0	f	f
24	163	0	f	f
24	164	0	f	f
44	90	0	f	f
44	86	0	f	f
44	91	0	f	f
44	92	0	f	f
44	93	0	f	f
44	98	0	f	f
44	87	0	f	f
44	88	0	f	f
44	89	0	f	f
44	94	0	f	f
44	95	0	f	f
44	96	0	f	f
44	97	0	f	f
44	99	0	f	f
44	100	0	f	f
44	101	0	f	f
44	104	0	f	f
44	102	0	f	f
44	107	0	f	f
44	116	0	f	f
44	113	0	f	f
44	118	0	f	f
44	103	0	f	f
44	105	0	f	f
44	106	0	f	f
44	108	0	f	f
44	109	0	f	f
44	110	0	f	f
44	111	0	f	f
44	112	0	f	f
44	121	0	f	f
44	122	0	f	f
44	124	0	f	f
44	114	0	f	f
44	115	0	f	f
44	117	0	f	f
44	119	0	f	f
44	120	0	f	f
44	123	0	f	f
44	126	0	f	f
44	125	0	f	f
44	127	0	f	f
44	133	0	f	f
44	134	0	f	f
44	136	0	f	f
44	131	0	f	f
44	132	0	f	f
44	135	0	f	f
44	137	0	f	f
44	141	0	f	f
44	142	0	f	f
44	143	0	f	f
44	145	0	f	f
44	146	0	f	f
44	156	0	f	f
44	158	0	f	f
44	138	0	f	f
44	139	0	f	f
44	140	0	f	f
44	144	0	f	f
44	151	0	f	f
44	152	0	f	f
44	153	0	f	f
44	154	0	f	f
44	155	0	f	f
44	157	0	f	f
44	147	0	f	f
44	148	0	f	f
44	149	0	f	f
44	150	0	f	f
44	159	0	f	f
44	165	0	f	f
44	166	0	f	f
44	160	0	f	f
44	161	0	f	f
44	162	0	f	f
44	163	0	f	f
44	164	0	f	f
45	90	0	f	f
45	86	0	f	f
45	91	0	f	f
45	92	0	f	f
45	93	0	f	f
45	98	0	f	f
45	87	0	f	f
45	88	0	f	f
45	89	0	f	f
45	94	0	f	f
45	95	0	f	f
45	96	0	f	f
45	97	0	f	f
45	99	0	f	f
45	100	0	f	f
45	101	0	f	f
45	104	0	f	f
45	102	0	f	f
45	107	0	f	f
45	116	0	f	f
45	113	0	f	f
45	118	0	f	f
45	103	0	f	f
45	105	0	f	f
45	106	0	f	f
45	108	0	f	f
45	109	0	f	f
45	110	0	f	f
45	111	0	f	f
45	112	0	f	f
45	121	0	f	f
45	122	0	f	f
45	124	0	f	f
45	114	0	f	f
45	115	0	f	f
45	117	0	f	f
45	119	0	f	f
45	120	0	f	f
45	123	0	f	f
45	126	0	f	f
45	125	0	f	f
45	127	0	f	f
45	133	0	f	f
45	134	0	f	f
45	136	0	f	f
45	131	0	f	f
45	132	0	f	f
45	135	0	f	f
45	137	0	f	f
45	141	0	f	f
45	142	0	f	f
45	143	0	f	f
45	145	0	f	f
45	146	0	f	f
45	156	0	f	f
45	158	0	f	f
45	138	0	f	f
45	139	0	f	f
45	140	0	f	f
45	144	0	f	f
45	151	0	f	f
45	152	0	f	f
45	153	0	f	f
45	154	0	f	f
45	155	0	f	f
45	157	0	f	f
45	147	0	f	f
45	148	0	f	f
45	149	0	f	f
45	150	0	f	f
45	159	0	f	f
45	165	0	f	f
45	166	0	f	f
45	160	0	f	f
45	161	0	f	f
45	162	0	f	f
45	163	0	f	f
45	164	0	f	f
46	90	0	f	f
46	86	0	f	f
46	91	0	f	f
46	92	0	f	f
46	93	0	f	f
46	98	0	f	f
46	87	0	f	f
46	88	0	f	f
46	89	0	f	f
46	94	0	f	f
46	95	0	f	f
46	96	0	f	f
46	97	0	f	f
46	99	0	f	f
46	100	0	f	f
46	101	0	f	f
46	104	0	f	f
46	102	0	f	f
46	107	0	f	f
46	116	0	f	f
46	113	0	f	f
46	118	0	f	f
46	103	0	f	f
46	105	0	f	f
46	106	0	f	f
46	108	0	f	f
46	109	0	f	f
46	110	0	f	f
46	111	0	f	f
46	112	0	f	f
46	121	0	f	f
46	122	0	f	f
46	124	0	f	f
46	114	0	f	f
46	115	0	f	f
46	117	0	f	f
46	119	0	f	f
46	120	0	f	f
46	123	0	f	f
46	126	0	f	f
46	128	0	f	f
46	129	0	f	f
46	125	0	f	f
46	127	0	f	f
46	130	0	f	f
46	133	0	f	f
46	134	0	f	f
46	136	0	f	f
46	131	0	f	f
46	132	0	f	f
46	135	0	f	f
46	137	0	f	f
46	141	0	f	f
46	142	0	f	f
46	143	0	f	f
46	145	0	f	f
46	146	0	f	f
46	156	0	f	f
46	158	0	f	f
46	138	0	f	f
46	139	0	f	f
46	140	0	f	f
46	144	0	f	f
46	151	0	f	f
46	152	0	f	f
46	153	0	f	f
46	154	0	f	f
46	155	0	f	f
46	157	0	f	f
46	147	0	f	f
46	148	0	f	f
46	149	0	f	f
46	150	0	f	f
46	159	0	f	f
46	165	0	f	f
46	166	0	f	f
46	160	0	f	f
46	161	0	f	f
46	162	0	f	f
46	163	0	f	f
46	164	0	f	f
10	90	0	f	f
10	86	0	f	f
10	91	0	f	f
10	92	0	f	f
10	93	0	f	f
10	98	0	f	f
10	87	0	f	f
10	88	0	f	f
10	89	0	f	f
10	94	0	f	f
10	99	0	f	f
10	100	0	f	f
10	101	0	f	f
10	104	0	f	f
10	102	0	f	f
10	107	0	f	f
10	116	0	f	f
10	113	0	f	f
10	118	0	f	f
45	128	0	f	t
45	129	0	f	t
45	130	0	f	t
10	103	0	f	f
10	105	0	f	f
10	106	0	f	f
10	108	0	f	f
10	109	0	f	f
10	110	0	f	f
10	111	0	f	f
10	112	0	f	f
10	121	0	f	f
10	122	0	f	f
10	124	0	f	f
10	114	0	f	f
10	115	0	f	f
10	117	0	f	f
10	119	0	f	f
10	120	0	f	f
10	123	0	f	f
10	126	0	f	f
10	128	0	f	f
10	129	0	f	f
10	125	0	f	f
10	127	0	f	f
10	130	0	f	f
10	133	0	f	f
10	134	0	f	f
10	136	0	f	f
10	131	0	f	f
10	132	0	f	f
10	135	0	f	f
10	137	0	f	f
10	141	0	f	f
10	142	0	f	f
10	143	0	f	f
10	145	0	f	f
10	146	0	f	f
10	156	0	f	f
10	158	0	f	f
10	138	0	f	f
10	139	0	f	f
10	140	0	f	f
10	144	0	f	f
10	151	0	f	f
10	152	0	f	f
10	153	0	f	f
10	154	0	f	f
10	155	0	f	f
10	157	0	f	f
10	147	0	f	f
10	148	0	f	f
10	149	0	f	f
10	150	0	f	f
10	159	0	f	f
10	165	0	f	f
10	166	0	f	f
10	160	0	f	f
10	161	0	f	f
10	162	0	f	f
10	163	0	f	f
10	164	0	f	f
11	90	0	f	f
11	86	0	f	f
11	91	0	f	f
11	92	0	f	f
11	93	0	f	f
11	98	0	f	f
11	87	0	f	f
11	88	0	f	f
11	89	0	f	f
11	94	0	f	f
11	99	0	f	f
11	100	0	f	f
11	101	0	f	f
11	104	0	f	f
11	102	0	f	f
11	107	0	f	f
11	116	0	f	f
11	113	0	f	f
11	118	0	f	f
11	103	0	f	f
11	105	0	f	f
11	106	0	f	f
11	108	0	f	f
11	109	0	f	f
11	110	0	f	f
11	111	0	f	f
11	112	0	f	f
11	121	0	f	f
11	122	0	f	f
11	124	0	f	f
11	114	0	f	f
11	115	0	f	f
11	117	0	f	f
11	119	0	f	f
11	120	0	f	f
11	123	0	f	f
11	126	0	f	f
11	128	0	f	f
11	129	0	f	f
11	125	0	f	f
11	127	0	f	f
11	130	0	f	f
11	133	0	f	f
11	134	0	f	f
11	136	0	f	f
11	131	0	f	f
11	132	0	f	f
11	135	0	f	f
11	137	0	f	f
11	141	0	f	f
11	142	0	f	f
11	143	0	f	f
11	145	0	f	f
11	146	0	f	f
11	156	0	f	f
11	158	0	f	f
11	138	0	f	f
11	139	0	f	f
11	140	0	f	f
11	144	0	f	f
11	151	0	f	f
11	152	0	f	f
11	153	0	f	f
11	154	0	f	f
11	155	0	f	f
11	157	0	f	f
11	147	0	f	f
11	148	0	f	f
11	149	0	f	f
11	150	0	f	f
11	159	0	f	f
11	165	0	f	f
11	166	0	f	f
11	160	0	f	f
11	161	0	f	f
11	162	0	f	f
11	163	0	f	f
11	164	0	f	f
12	90	0	f	f
12	86	0	f	f
12	91	0	f	f
12	92	0	f	f
12	93	0	f	f
12	98	0	f	f
12	87	0	f	f
12	88	0	f	f
12	89	0	f	f
12	94	0	f	f
12	95	0	f	f
12	96	0	f	f
12	97	0	f	f
12	99	0	f	f
12	100	0	f	f
12	101	0	f	f
12	104	0	f	f
12	102	0	f	f
12	107	0	f	f
12	116	0	f	f
12	113	0	f	f
12	118	0	f	f
12	103	0	f	f
12	105	0	f	f
12	106	0	f	f
12	108	0	f	f
12	109	0	f	f
12	110	0	f	f
12	111	0	f	f
12	112	0	f	f
12	121	0	f	f
12	122	0	f	f
12	124	0	f	f
12	114	0	f	f
12	115	0	f	f
12	117	0	f	f
12	119	0	f	f
12	120	0	f	f
12	123	0	f	f
12	126	0	f	f
12	128	0	f	f
12	129	0	f	f
12	125	0	f	f
12	127	0	f	f
12	130	0	f	f
12	133	0	f	f
12	134	0	f	f
12	136	0	f	f
12	131	0	f	f
12	132	0	f	f
12	135	0	f	f
12	137	0	f	f
12	141	0	f	f
12	142	0	f	f
12	143	0	f	f
12	145	0	f	f
12	146	0	f	f
12	156	0	f	f
12	158	0	f	f
12	138	0	f	f
12	139	0	f	f
12	140	0	f	f
12	144	0	f	f
12	151	0	f	f
12	152	0	f	f
12	153	0	f	f
12	154	0	f	f
12	155	0	f	f
12	157	0	f	f
12	147	0	f	f
12	148	0	f	f
12	149	0	f	f
12	150	0	f	f
12	159	0	f	f
12	165	0	f	f
12	166	0	f	f
12	160	0	f	f
12	161	0	f	f
12	162	0	f	f
12	163	0	f	f
12	164	0	f	f
13	86	0	f	f
13	92	0	f	f
13	93	0	f	f
13	98	0	f	f
13	87	0	f	f
13	88	0	f	f
13	94	0	f	f
13	95	0	f	f
13	96	0	f	f
13	97	0	f	f
13	99	0	f	f
13	100	0	f	f
13	101	0	f	f
13	104	0	f	f
13	102	0	f	f
13	107	0	f	f
13	116	0	f	f
13	113	0	f	f
13	118	0	f	f
13	103	0	f	f
13	105	0	f	f
13	106	0	f	f
13	108	0	f	f
13	109	0	f	f
13	110	0	f	f
13	111	0	f	f
13	112	0	f	f
13	121	0	f	f
13	122	0	f	f
13	124	0	f	f
13	114	0	f	f
13	115	0	f	f
13	117	0	f	f
13	119	0	f	f
13	120	0	f	f
13	123	0	f	f
13	126	0	f	f
13	128	0	f	f
13	129	0	f	f
13	125	0	f	f
13	127	0	f	f
13	130	0	f	f
13	133	0	f	f
13	134	0	f	f
13	136	0	f	f
13	131	0	f	f
13	132	0	f	f
13	135	0	f	f
13	137	0	f	f
13	141	0	f	f
13	142	0	f	f
13	143	0	f	f
13	145	0	f	f
13	146	0	f	f
13	156	0	f	f
13	158	0	f	f
13	138	0	f	f
13	139	0	f	f
13	140	0	f	f
13	144	0	f	f
13	151	0	f	f
13	152	0	f	f
13	153	0	f	f
13	154	0	f	f
13	155	0	f	f
13	157	0	f	f
13	147	0	f	f
13	148	0	f	f
13	149	0	f	f
13	150	0	f	f
13	159	0	f	f
13	165	0	f	f
13	166	0	f	f
13	160	0	f	f
13	161	0	f	f
13	162	0	f	f
13	163	0	f	f
13	164	0	f	f
14	86	0	f	f
14	92	0	f	f
14	93	0	f	f
14	98	0	f	f
14	87	0	f	f
14	88	0	f	f
14	94	0	f	f
14	95	0	f	f
14	96	0	f	f
14	97	0	f	f
14	99	0	f	f
14	100	0	f	f
14	101	0	f	f
14	104	0	f	f
14	102	0	f	f
14	107	0	f	f
14	116	0	f	f
14	113	0	f	f
14	118	0	f	f
14	103	0	f	f
14	105	0	f	f
14	106	0	f	f
14	108	0	f	f
14	109	0	f	f
14	110	0	f	f
14	111	0	f	f
14	112	0	f	f
14	121	0	f	f
14	122	0	f	f
14	124	0	f	f
14	114	0	f	f
14	115	0	f	f
14	117	0	f	f
14	119	0	f	f
14	120	0	f	f
14	123	0	f	f
14	126	0	f	f
14	128	0	f	f
14	129	0	f	f
14	125	0	f	f
14	127	0	f	f
14	130	0	f	f
14	133	0	f	f
14	134	0	f	f
14	136	0	f	f
14	131	0	t	f
14	132	0	f	f
14	135	0	f	f
14	137	0	f	f
14	141	0	f	f
14	142	0	f	f
14	143	0	f	f
14	145	0	f	f
14	146	0	f	f
14	156	0	f	f
14	158	0	f	f
14	138	0	f	f
14	139	0	f	f
14	140	0	f	f
14	144	0	f	f
14	151	0	f	f
14	152	0	f	f
14	153	0	f	f
14	154	0	f	f
14	155	0	f	f
14	157	0	f	f
14	147	0	f	f
14	148	0	f	f
14	149	0	f	f
14	150	0	f	f
14	159	0	f	f
14	165	0	f	f
14	166	0	f	f
14	160	0	f	f
14	161	0	f	f
14	162	0	f	f
14	163	0	f	f
14	164	0	f	f
15	90	0	f	f
15	86	0	f	f
15	91	0	f	f
15	92	0	f	f
15	93	0	f	f
15	98	0	f	f
15	87	0	f	f
15	88	0	f	f
15	89	0	f	f
15	94	0	f	f
15	95	0	f	f
15	96	0	f	f
15	97	0	f	f
15	99	0	f	f
15	100	0	f	f
15	101	0	f	f
15	104	0	f	f
15	102	0	f	f
15	107	0	f	f
15	116	0	f	f
15	113	0	f	f
15	118	0	f	f
15	103	0	f	f
15	105	0	f	f
15	106	0	f	f
15	108	0	f	f
15	109	0	f	f
15	110	0	f	f
15	111	0	f	f
15	112	0	f	f
15	121	0	f	f
15	122	0	f	f
15	124	0	f	f
15	114	0	f	f
15	115	0	f	f
15	117	0	f	f
15	119	0	f	f
15	120	0	f	f
15	123	0	f	f
15	126	0	f	f
15	128	0	f	f
15	129	0	f	f
15	125	0	f	f
15	127	0	f	f
15	130	0	f	f
15	133	0	f	f
15	134	0	f	f
15	136	0	f	f
15	131	0	f	f
15	132	0	f	f
15	135	0	f	f
15	137	0	f	f
15	141	0	f	f
15	142	0	f	f
15	143	0	f	f
15	145	0	f	f
15	146	0	f	f
15	156	0	f	f
15	158	0	f	f
15	138	0	f	f
15	139	0	f	f
15	140	0	f	f
15	144	0	f	f
15	151	0	f	f
15	152	0	f	f
15	153	0	f	f
15	154	0	f	f
15	155	0	f	f
15	157	0	f	f
15	147	0	f	f
15	148	0	f	f
15	149	0	f	f
15	150	0	f	f
15	159	0	f	f
15	165	0	f	f
15	166	0	f	f
15	160	0	f	f
15	161	0	f	f
15	162	0	f	f
15	163	0	f	f
15	164	0	f	f
19	90	0	f	f
19	86	0	f	f
19	91	0	f	f
19	92	0	f	f
19	93	0	f	f
19	98	0	f	f
19	87	0	f	f
19	88	0	f	f
19	89	0	f	f
19	94	0	f	f
19	95	0	f	f
19	96	0	f	f
19	97	0	f	f
19	99	0	f	f
19	100	0	f	f
19	104	0	f	f
19	107	0	f	f
19	116	0	f	f
19	113	0	f	f
19	118	0	f	f
19	105	0	f	f
19	106	0	f	f
19	108	0	f	f
19	109	0	f	f
19	110	0	f	f
19	111	0	f	f
19	112	0	f	f
19	121	0	f	f
19	122	0	f	f
19	124	0	f	f
19	114	0	f	f
19	115	0	f	f
19	117	0	f	f
19	119	0	f	f
19	120	0	f	f
19	123	0	f	f
19	126	0	f	f
19	128	0	f	f
19	129	0	f	f
19	125	0	f	f
19	127	0	f	f
19	130	0	f	f
19	133	0	f	f
19	134	0	f	f
19	136	0	f	f
19	131	0	f	f
19	132	0	f	f
19	135	0	f	f
19	137	0	f	f
19	141	0	f	f
19	142	0	f	f
19	143	0	f	f
19	145	0	f	f
19	146	0	f	f
19	156	0	f	f
19	158	0	f	f
19	138	0	f	f
19	139	0	f	f
19	140	0	f	f
19	144	0	f	f
19	151	0	f	f
19	152	0	f	f
19	153	0	f	f
19	154	0	f	f
19	155	0	f	f
19	157	0	f	f
19	147	0	f	f
19	148	0	f	f
19	149	0	f	f
19	150	0	f	f
19	159	0	f	f
19	165	0	f	f
19	166	0	f	f
19	160	0	f	f
19	161	0	f	f
19	162	0	f	f
19	163	0	f	f
19	164	0	f	f
20	90	0	f	f
20	86	0	f	f
20	91	0	f	f
20	92	0	f	f
20	93	0	f	f
20	98	0	f	f
20	87	0	f	f
20	88	0	f	f
20	89	0	f	f
20	94	0	f	f
20	95	0	f	f
20	96	0	f	f
20	97	0	f	f
20	99	0	f	f
20	100	0	f	f
20	104	0	f	f
20	107	0	f	f
20	116	0	f	f
20	113	0	f	f
20	118	0	f	f
20	105	0	f	f
20	106	0	f	f
20	108	0	f	f
20	109	0	f	f
20	110	0	f	f
20	111	0	f	f
20	112	0	f	f
20	121	0	f	f
20	122	0	f	f
20	124	0	f	f
20	114	0	f	f
20	115	0	f	f
20	117	0	f	f
20	119	0	f	f
20	120	0	f	f
20	123	0	f	f
20	126	0	f	f
20	128	0	f	f
20	129	0	f	f
20	125	0	f	f
20	127	0	f	f
20	130	0	f	f
20	133	0	f	f
20	134	0	f	f
20	136	0	f	f
20	131	0	f	f
20	132	0	f	f
20	135	0	f	f
20	137	0	f	f
20	141	0	f	f
20	142	0	f	f
20	143	0	f	f
20	145	0	f	f
20	146	0	f	f
20	156	0	f	f
20	158	0	f	f
20	138	0	f	f
20	139	0	f	f
20	140	0	f	f
20	144	0	f	f
20	151	0	f	f
20	152	0	f	f
20	153	0	f	f
20	154	0	f	f
20	155	0	f	f
20	157	0	f	f
20	147	0	f	f
20	148	0	f	f
20	149	0	f	f
20	150	0	f	f
20	159	0	f	f
20	165	0	f	f
20	166	0	f	f
20	160	0	f	f
20	161	0	f	f
20	162	0	f	f
20	163	0	f	f
20	164	0	f	f
21	90	0	f	f
21	86	0	f	f
21	91	0	f	f
21	92	0	f	f
21	93	0	f	f
21	98	0	f	f
21	87	0	f	f
21	88	0	f	f
21	89	0	f	f
21	94	0	f	f
21	95	0	f	f
21	96	0	f	f
21	97	0	f	f
21	99	0	f	f
21	100	0	f	f
21	101	0	f	f
21	104	0	f	f
21	102	0	f	f
21	107	0	f	f
21	116	0	f	f
21	113	0	f	f
21	118	0	f	f
21	103	0	f	f
21	105	0	f	f
21	106	0	f	f
21	108	0	f	f
21	109	0	f	f
21	110	0	f	f
21	111	0	f	f
21	112	0	f	f
21	121	0	f	f
21	122	0	f	f
21	124	0	f	f
21	114	0	f	f
21	115	0	f	f
21	117	0	f	f
21	119	0	f	f
21	120	0	f	f
21	123	0	f	f
21	126	0	f	f
21	128	0	f	f
21	129	0	f	f
21	125	0	f	f
21	127	0	f	f
21	130	0	f	f
21	133	0	f	f
21	134	0	f	f
21	136	0	f	f
21	131	0	f	f
21	132	0	f	f
21	135	0	f	f
21	137	0	f	f
21	141	0	f	f
21	142	0	f	f
21	143	0	f	f
21	145	0	f	f
21	146	0	f	f
21	156	0	f	f
21	158	0	f	f
21	138	0	f	f
21	139	0	f	f
21	140	0	f	f
21	144	0	f	f
21	151	0	f	f
21	152	0	f	f
21	153	0	f	f
21	154	0	f	f
21	155	0	f	f
21	157	0	f	f
21	147	0	f	f
21	148	0	f	f
21	149	0	f	f
21	150	0	f	f
21	159	0	f	f
21	165	0	f	f
21	166	0	f	f
21	160	0	f	f
21	161	0	f	f
21	162	0	f	f
21	163	0	f	f
21	164	0	f	f
25	90	0	f	f
25	86	0	f	f
25	91	0	f	f
25	92	0	f	f
25	93	0	f	f
25	98	0	f	f
25	87	0	f	f
25	88	0	f	f
25	89	0	f	f
25	94	0	f	f
25	95	0	f	f
25	96	0	f	f
25	97	0	f	f
25	99	0	f	f
25	100	0	f	f
25	101	0	f	f
25	104	0	f	f
25	102	0	f	f
25	107	0	f	f
25	116	0	f	f
25	113	0	f	f
25	118	0	f	f
25	103	0	f	f
25	105	0	f	f
25	106	0	f	f
25	108	0	f	f
25	109	0	f	f
25	121	0	f	f
25	122	0	f	f
25	124	0	f	f
25	110	0	f	t
25	111	0	f	t
25	112	0	f	t
25	114	0	f	f
25	115	0	f	f
25	117	0	f	f
25	119	0	f	f
25	120	0	f	f
25	123	0	f	f
25	126	0	f	f
25	128	0	f	f
25	129	0	f	f
25	125	0	f	f
25	127	0	f	f
25	130	0	f	f
25	133	0	f	f
25	134	0	f	f
25	136	0	f	f
25	131	0	f	f
25	132	0	f	f
25	135	0	f	f
25	137	0	f	f
25	141	0	f	f
25	142	0	f	f
25	143	0	f	f
25	145	0	f	f
25	146	0	f	f
25	156	0	f	f
25	158	0	f	f
25	138	0	f	f
25	139	0	f	f
25	140	0	f	f
25	144	0	f	f
25	151	0	f	f
25	152	0	f	f
25	153	0	f	f
25	154	0	f	f
25	155	0	f	f
25	157	0	f	f
25	147	0	f	f
25	148	0	f	f
25	149	0	f	f
25	150	0	f	f
25	159	0	f	f
25	165	0	f	f
25	166	0	f	f
25	160	0	f	f
25	161	0	f	f
25	162	0	f	f
25	163	0	f	f
25	164	0	f	f
26	90	0	f	f
26	86	0	f	f
26	91	0	f	f
26	92	0	f	f
26	93	0	f	f
26	98	0	f	f
26	87	0	f	f
26	88	0	f	f
26	89	0	f	f
26	94	0	f	f
26	95	0	f	f
26	96	0	f	f
26	97	0	f	f
26	99	0	f	f
26	100	0	f	f
26	101	0	f	f
26	104	0	f	f
26	102	0	f	f
26	107	0	f	f
26	116	0	f	f
26	113	0	f	f
26	118	0	f	f
26	103	0	f	f
26	105	0	f	f
26	106	0	f	f
26	108	0	f	f
26	109	0	f	f
26	121	0	f	f
26	122	0	f	f
26	124	0	f	f
26	114	0	f	f
26	115	0	f	f
26	117	0	f	f
26	119	0	f	f
26	120	0	f	f
26	123	0	f	f
26	126	0	f	f
26	128	0	f	f
26	129	0	f	f
26	125	0	f	f
26	127	0	f	f
26	130	0	f	f
26	133	0	f	f
26	134	0	f	f
26	136	0	f	f
26	131	0	f	f
26	132	0	f	f
26	135	0	f	f
26	137	0	f	f
26	141	0	f	f
26	142	0	f	f
26	143	0	f	f
26	145	0	f	f
26	146	0	f	f
26	156	0	f	f
26	158	0	f	f
26	138	0	f	f
26	139	0	f	f
26	140	0	f	f
26	144	0	f	f
26	151	0	f	f
26	152	0	f	f
26	153	0	f	f
26	154	0	f	f
26	155	0	f	f
26	157	0	f	f
26	147	0	f	f
26	148	0	f	f
26	149	0	f	f
26	150	0	f	f
26	159	0	f	f
26	165	0	f	f
26	166	0	f	f
26	160	0	f	f
26	161	0	f	f
26	162	0	f	f
26	163	0	f	f
26	164	0	f	f
27	90	0	f	f
27	86	0	f	f
27	91	0	f	f
27	92	0	f	f
27	93	0	f	f
27	98	0	f	f
27	87	0	f	f
27	88	0	f	f
27	89	0	f	f
27	94	0	f	f
27	95	0	f	f
27	96	0	f	f
27	97	0	f	f
27	99	0	f	f
27	100	0	f	f
27	101	0	f	f
27	104	0	f	f
27	102	0	f	f
27	107	0	f	f
27	116	0	f	f
27	113	0	f	f
27	118	0	f	f
27	103	0	f	f
27	105	0	f	f
27	106	0	f	f
27	108	0	f	f
27	109	0	f	f
27	110	0	f	f
27	111	0	f	f
27	112	0	f	f
27	121	0	f	f
27	122	0	f	f
27	124	0	f	f
27	114	0	f	f
27	115	0	f	f
27	117	0	f	f
27	119	0	f	f
27	120	0	f	f
27	123	0	f	f
27	126	0	f	f
27	128	0	f	f
27	129	0	f	f
27	125	0	f	f
27	127	0	f	f
27	130	0	f	f
27	133	0	f	f
27	134	0	f	f
27	136	0	f	f
27	131	0	f	f
27	132	0	f	f
27	135	0	f	f
27	137	0	f	f
27	141	0	f	f
27	142	0	f	f
27	143	0	f	f
27	145	0	f	f
27	146	0	f	f
27	156	0	f	f
27	158	0	f	f
27	138	0	f	f
27	139	0	f	f
27	140	0	f	f
27	144	0	f	f
27	151	0	f	f
27	152	0	f	f
27	153	0	f	f
27	154	0	f	f
27	155	0	f	f
27	157	0	f	f
27	147	0	f	f
27	148	0	f	f
27	149	0	f	f
27	150	0	f	f
27	159	0	f	f
27	165	0	f	f
27	166	0	f	f
27	160	0	f	f
27	161	0	f	f
27	162	0	f	f
27	163	0	f	f
27	164	0	f	f
28	90	0	f	f
28	86	0	f	f
28	91	0	f	f
28	92	0	f	f
28	93	0	f	f
28	98	0	f	f
28	87	0	f	f
28	88	0	f	f
28	89	0	f	f
28	94	0	f	f
28	95	0	f	f
28	96	0	f	f
28	97	0	f	f
28	99	0	f	f
28	100	0	f	f
28	101	0	f	f
28	104	0	f	f
28	102	0	f	f
28	107	0	f	f
28	116	0	f	f
28	118	0	f	f
28	103	0	f	f
28	105	0	f	f
28	106	0	f	f
28	108	0	f	f
28	109	0	f	f
28	110	0	f	f
28	111	0	f	f
28	112	0	f	f
28	121	0	f	f
28	122	0	f	f
28	124	0	f	f
28	117	0	f	f
28	119	0	f	f
28	120	0	f	f
28	123	0	f	f
28	126	0	f	f
28	128	0	f	f
28	129	0	f	f
28	125	0	f	f
28	127	0	f	f
28	130	0	f	f
28	133	0	f	f
28	134	0	f	f
28	136	0	f	f
28	131	0	f	f
28	132	0	f	f
28	135	0	f	f
28	137	0	f	f
28	141	0	f	f
28	142	0	f	f
28	143	0	f	f
28	145	0	f	f
28	146	0	f	f
28	156	0	f	f
28	158	0	f	f
28	138	0	f	f
28	139	0	f	f
28	140	0	f	f
28	144	0	f	f
28	151	0	f	f
28	152	0	f	f
28	153	0	f	f
28	154	0	f	f
28	155	0	f	f
28	157	0	f	f
28	147	0	f	f
28	148	0	f	f
28	149	0	f	f
28	150	0	f	f
28	159	0	f	f
28	165	0	f	f
28	166	0	f	f
28	160	0	f	f
28	161	0	f	f
28	162	0	f	f
28	163	0	f	f
28	164	0	f	f
31	90	0	f	f
31	86	0	f	f
31	91	0	f	f
31	92	0	f	f
31	93	0	f	f
31	98	0	f	f
31	87	0	f	f
31	88	0	f	f
31	89	0	f	f
31	94	0	f	f
31	95	0	f	f
31	96	0	f	f
31	97	0	f	f
31	99	0	f	f
31	100	0	f	f
31	101	0	f	f
31	104	0	f	f
31	102	0	f	f
31	107	0	f	f
31	113	0	f	f
31	103	0	f	f
31	105	0	f	f
31	106	0	f	f
31	108	0	f	f
31	109	0	f	f
31	110	0	f	f
31	111	0	f	f
31	112	0	f	f
31	121	0	f	f
31	122	0	f	f
31	124	0	f	f
31	114	0	f	f
31	115	0	f	f
31	119	0	f	f
31	120	0	f	f
31	123	0	f	f
31	126	0	f	f
31	128	0	f	f
31	129	0	f	f
31	125	0	f	f
31	127	0	f	f
31	130	0	f	f
31	133	0	f	f
31	134	0	f	f
31	136	0	f	f
31	131	0	f	f
31	132	0	f	f
31	135	0	f	f
31	137	0	f	f
31	141	0	f	f
31	142	0	f	f
31	143	0	f	f
31	145	0	f	f
31	146	0	f	f
31	156	0	f	f
31	158	0	f	f
31	138	0	f	f
31	139	0	f	f
31	140	0	f	f
31	144	0	f	f
31	151	0	f	f
31	152	0	f	f
31	153	0	f	f
31	154	0	f	f
31	155	0	f	f
31	157	0	f	f
31	147	0	f	f
31	148	0	f	f
31	149	0	f	f
31	150	0	f	f
31	159	0	f	f
31	165	0	f	f
31	166	0	f	f
31	160	0	f	f
31	161	0	f	f
31	162	0	f	f
31	116	0	f	t
31	118	0	f	t
31	117	0	f	t
31	163	0	f	f
31	164	0	f	f
32	90	0	f	f
32	86	0	f	f
32	91	0	f	f
32	92	0	f	f
32	93	0	f	f
32	98	0	f	f
32	87	0	f	f
32	88	0	f	f
32	89	0	f	f
32	94	0	f	f
32	95	0	f	f
32	96	0	f	f
32	97	0	f	f
32	99	0	f	f
32	100	0	f	f
32	101	0	f	f
32	104	0	f	f
32	102	0	f	f
32	107	0	f	f
32	113	0	f	f
32	103	0	f	f
32	105	0	f	f
32	106	0	f	f
32	108	0	f	f
32	109	0	f	f
32	110	0	f	f
32	111	0	f	f
32	112	0	f	f
32	121	0	f	f
32	122	0	f	f
32	124	0	f	f
32	114	0	f	f
32	115	0	f	f
32	119	0	f	f
32	120	0	f	f
32	123	0	f	f
32	126	0	f	f
32	128	0	f	f
32	129	0	f	f
32	125	0	f	f
32	127	0	f	f
32	130	0	f	f
32	133	0	f	f
32	134	0	f	f
32	136	0	f	f
32	131	0	f	f
32	132	0	f	f
32	135	0	f	f
32	137	0	f	f
32	141	0	f	f
32	142	0	f	f
32	143	0	f	f
32	145	0	f	f
32	146	0	f	f
32	156	0	f	f
32	158	0	f	f
32	138	0	f	f
32	139	0	f	f
32	140	0	f	f
32	144	0	f	f
32	151	0	f	f
32	152	0	f	f
32	153	0	f	f
32	154	0	f	f
32	155	0	f	f
32	157	0	f	f
32	147	0	f	f
32	148	0	f	f
32	149	0	f	f
32	150	0	f	f
32	159	0	f	f
32	165	0	f	f
32	166	0	f	f
32	160	0	f	f
32	161	0	f	f
32	162	0	f	f
32	163	0	f	f
32	164	0	f	f
33	90	0	f	f
33	86	0	f	f
33	91	0	f	f
33	92	0	f	f
33	93	0	f	f
33	98	0	f	f
33	87	0	f	f
33	88	0	f	f
33	89	0	f	f
33	94	0	f	f
33	95	0	f	f
33	96	0	f	f
33	97	0	f	f
33	99	0	f	f
33	100	0	f	f
33	101	0	f	f
33	104	0	f	f
33	102	0	f	f
33	107	0	f	f
33	116	0	f	f
33	113	0	f	f
33	118	0	f	f
33	103	0	f	f
33	105	0	f	f
33	106	0	f	f
33	108	0	f	f
33	109	0	f	f
33	110	0	f	f
33	111	0	f	f
33	112	0	f	f
33	121	0	f	f
33	122	0	f	f
33	124	0	f	f
33	114	0	f	f
33	115	0	f	f
33	117	0	f	f
33	119	0	f	f
33	120	0	f	f
33	123	0	f	f
33	126	0	f	f
33	128	0	f	f
33	129	0	f	f
33	125	0	f	f
33	127	0	f	f
33	130	0	f	f
33	133	0	f	f
33	134	0	f	f
33	136	0	f	f
33	131	0	f	f
33	132	0	f	f
33	137	0	f	f
33	141	0	f	f
33	142	0	f	f
33	143	0	f	f
33	145	0	f	f
33	146	0	f	f
33	156	0	f	f
33	158	0	f	f
33	138	0	f	f
33	139	0	f	f
33	140	0	f	f
33	144	0	f	f
33	151	0	f	f
33	152	0	f	f
33	153	0	f	f
33	154	0	f	f
33	155	0	f	f
33	157	0	f	f
33	147	0	f	f
33	148	0	f	f
33	149	0	f	f
33	150	0	f	f
33	159	0	f	f
33	165	0	f	f
33	166	0	f	f
33	160	0	f	f
33	161	0	f	f
33	162	0	f	f
33	163	0	f	f
33	164	0	f	f
34	90	0	f	f
34	86	0	f	f
34	91	0	f	f
34	92	0	f	f
34	93	0	f	f
34	98	0	f	f
34	87	0	f	f
34	88	0	f	f
34	89	0	f	f
34	94	0	f	f
34	95	0	f	f
34	96	0	f	f
34	97	0	f	f
34	99	0	f	f
34	100	0	f	f
34	101	0	f	f
34	104	0	f	f
34	102	0	f	f
34	107	0	f	f
34	116	0	f	f
34	113	0	f	f
33	135	0	f	t
34	118	0	f	f
34	103	0	f	f
34	105	0	f	f
34	106	0	f	f
34	108	0	f	f
34	109	0	f	f
34	110	0	f	f
34	111	0	f	f
34	112	0	f	f
34	122	0	f	f
34	124	0	f	f
34	114	0	f	f
34	115	0	f	f
34	117	0	f	f
34	123	0	f	f
34	126	0	f	f
34	128	0	f	f
34	129	0	f	f
34	125	0	f	f
34	127	0	f	f
34	130	0	f	f
34	133	0	f	f
34	134	0	f	f
34	136	0	f	f
34	131	0	f	f
34	132	0	f	f
34	135	0	f	f
34	137	0	f	f
34	141	0	f	f
34	142	0	f	f
34	143	0	f	f
34	145	0	f	f
34	146	0	f	f
34	156	0	f	f
34	158	0	f	f
34	138	0	f	f
34	139	0	f	f
34	140	0	f	f
34	144	0	f	f
34	151	0	f	f
34	152	0	f	f
34	153	0	f	f
34	154	0	f	f
34	155	0	f	f
34	157	0	f	f
34	147	0	f	f
34	148	0	f	f
34	149	0	f	f
34	150	0	f	f
34	159	0	f	f
34	165	0	f	f
34	166	0	f	f
34	160	0	f	f
34	161	0	f	f
34	162	0	f	f
34	163	0	f	f
34	164	0	f	f
35	90	0	f	f
35	86	0	f	f
35	91	0	f	f
35	92	0	f	f
35	93	0	f	f
35	98	0	f	f
35	87	0	f	f
35	88	0	f	f
35	89	0	f	f
35	94	0	f	f
35	95	0	f	f
35	96	0	f	f
35	97	0	f	f
35	99	0	f	f
35	100	0	f	f
35	101	0	f	f
35	104	0	f	f
35	102	0	f	f
35	107	0	f	f
35	116	0	f	f
35	113	0	f	f
35	118	0	f	f
35	103	0	f	f
35	105	0	f	f
35	106	0	f	f
35	108	0	f	f
35	109	0	f	f
35	110	0	f	f
35	111	0	f	f
35	112	0	f	f
35	122	0	f	f
35	124	0	f	f
35	114	0	f	f
35	115	0	f	f
35	117	0	f	f
35	123	0	f	f
35	126	0	f	f
35	128	0	f	f
35	129	0	f	f
35	125	0	f	f
35	127	0	f	f
35	130	0	f	f
35	133	0	f	f
35	134	0	f	f
35	136	0	f	f
35	131	0	f	f
35	132	0	f	f
35	135	0	f	f
35	137	0	f	f
35	141	0	f	f
35	142	0	f	f
35	143	0	f	f
35	145	0	f	f
35	146	0	f	f
35	156	0	f	f
35	158	0	f	f
35	138	0	f	f
35	139	0	f	f
35	140	0	f	f
35	144	0	f	f
35	151	0	f	f
35	152	0	f	f
35	153	0	f	f
35	154	0	f	f
35	155	0	f	f
35	157	0	f	f
35	147	0	f	f
35	148	0	f	f
35	149	0	f	f
35	150	0	f	f
35	159	0	f	f
35	165	0	f	f
35	166	0	f	f
35	160	0	f	f
35	161	0	f	f
35	162	0	f	f
35	163	0	f	f
35	164	0	f	f
36	90	0	f	f
36	86	0	f	f
36	91	0	f	f
36	92	0	f	f
36	93	0	f	f
36	98	0	f	f
36	87	0	f	f
36	88	0	f	f
36	89	0	f	f
36	94	0	f	f
36	95	0	f	f
36	96	0	f	f
36	97	0	f	f
36	99	0	f	f
36	100	0	f	f
36	101	0	f	f
36	104	0	f	f
36	102	0	f	f
36	107	0	f	f
36	116	0	f	f
36	113	0	f	f
36	118	0	f	f
36	103	0	f	f
36	105	0	f	f
36	106	0	f	f
36	108	0	f	f
36	109	0	f	f
36	110	0	f	f
36	111	0	f	f
36	112	0	f	f
36	121	0	f	f
36	122	0	f	f
36	124	0	f	f
36	114	0	f	f
36	115	0	f	f
36	117	0	f	f
36	119	0	f	f
36	120	0	f	f
36	123	0	f	f
36	126	0	f	f
36	128	0	f	f
36	129	0	f	f
36	125	0	f	f
36	127	0	f	f
36	130	0	f	f
36	133	0	f	f
36	134	0	f	f
36	136	0	f	f
36	131	0	f	f
36	132	0	f	f
36	135	0	f	f
36	137	0	f	f
36	141	0	f	f
36	142	0	f	f
36	143	0	f	f
36	145	0	f	f
36	146	0	f	f
36	156	0	f	f
36	158	0	f	f
36	138	0	f	f
36	139	0	f	f
36	140	0	f	f
36	144	0	f	f
36	151	0	f	f
36	152	0	f	f
36	153	0	f	f
36	154	0	f	f
36	155	0	f	f
36	157	0	f	f
36	147	0	f	f
36	148	0	f	f
36	149	0	f	f
36	150	0	f	f
36	159	0	f	f
36	165	0	f	f
36	166	0	f	f
36	160	0	f	f
36	161	0	f	f
36	162	0	f	f
36	163	0	f	f
36	164	0	f	f
37	90	0	f	f
37	86	0	f	f
37	91	0	f	f
37	92	0	f	f
37	93	0	f	f
37	98	0	f	f
37	87	0	f	f
37	88	0	f	f
37	89	0	f	f
37	94	0	f	f
37	95	0	f	f
37	96	0	f	f
37	97	0	f	f
37	99	0	f	f
37	100	0	f	f
37	101	0	f	f
37	104	0	f	f
37	102	0	f	f
37	107	0	f	f
37	116	0	f	f
37	113	0	f	f
37	118	0	f	f
37	103	0	f	f
37	105	0	f	f
37	106	0	f	f
37	108	0	f	f
37	109	0	f	f
37	110	0	f	f
37	111	0	f	f
37	112	0	f	f
37	121	0	f	f
37	114	0	f	f
37	115	0	f	f
37	117	0	f	f
37	119	0	f	f
37	120	0	f	f
37	126	0	f	f
37	128	0	f	f
37	129	0	f	f
37	125	0	f	f
37	127	0	f	f
37	130	0	f	f
37	133	0	f	f
37	134	0	f	f
37	136	0	f	f
37	131	0	f	f
37	132	0	f	f
37	135	0	f	f
37	137	0	f	f
37	141	0	f	f
37	142	0	f	f
37	143	0	f	f
37	145	0	f	f
37	146	0	f	f
37	156	0	f	f
37	158	0	f	f
37	138	0	f	f
37	139	0	f	f
37	140	0	f	f
37	144	0	f	f
37	151	0	f	f
37	152	0	f	f
37	153	0	f	f
37	154	0	f	f
37	155	0	f	f
37	157	0	f	f
37	147	0	f	f
37	148	0	f	f
37	149	0	f	f
37	150	0	f	f
37	159	0	f	f
37	165	0	f	f
37	166	0	f	f
37	160	0	f	f
37	161	0	f	f
37	162	0	f	f
37	163	0	f	f
37	164	0	f	f
38	90	0	f	f
38	86	0	f	f
38	91	0	f	f
38	92	0	f	f
38	93	0	f	f
38	98	0	f	f
38	87	0	f	f
38	88	0	f	f
38	89	0	f	f
38	94	0	f	f
38	95	0	f	f
38	96	0	f	f
38	97	0	f	f
38	99	0	f	f
38	100	0	f	f
38	101	0	f	f
38	104	0	f	f
38	102	0	f	f
38	107	0	f	f
38	116	0	f	f
38	113	0	f	f
38	118	0	f	f
38	103	0	f	f
38	105	0	f	f
38	106	0	f	f
38	108	0	f	f
38	109	0	f	f
38	110	0	f	f
38	111	0	f	f
38	112	0	f	f
38	121	0	f	f
38	114	0	f	f
38	115	0	f	f
38	117	0	f	f
38	119	0	f	f
38	120	0	f	f
38	126	0	f	f
38	128	0	f	f
38	129	0	f	f
38	125	0	f	f
38	127	0	f	f
38	130	0	f	f
38	133	0	f	f
38	134	0	f	f
38	136	0	f	f
38	131	0	f	f
38	132	0	f	f
38	135	0	f	f
38	137	0	f	f
38	141	0	f	f
38	142	0	f	f
38	143	0	f	f
38	145	0	f	f
38	146	0	f	f
38	156	0	f	f
38	158	0	f	f
38	138	0	f	f
38	139	0	f	f
38	140	0	f	f
38	144	0	f	f
38	151	0	f	f
38	152	0	f	f
38	153	0	f	f
38	154	0	f	f
38	155	0	f	f
38	157	0	f	f
38	147	0	f	f
38	148	0	f	f
38	149	0	f	f
38	150	0	f	f
38	159	0	f	f
38	165	0	f	f
38	166	0	f	f
38	160	0	f	f
38	161	0	f	f
38	162	0	f	f
38	163	0	f	f
38	164	0	f	f
29	90	0	f	f
29	86	0	f	f
29	91	0	f	f
29	92	0	f	f
29	93	0	f	f
29	98	0	f	f
29	87	0	f	f
29	88	0	f	f
29	89	0	f	f
29	94	0	f	f
29	95	0	f	f
29	96	0	f	f
29	97	0	f	f
29	99	0	f	f
29	100	0	f	f
29	101	0	f	f
29	104	0	f	f
29	102	0	f	f
29	107	0	f	f
29	116	0	f	f
29	118	0	f	f
29	103	0	f	f
29	105	0	f	f
29	106	0	f	f
29	108	0	f	f
29	109	0	f	f
29	110	0	f	f
29	111	0	f	f
29	112	0	f	f
29	121	0	f	f
29	122	0	f	f
29	124	0	f	f
29	117	0	f	f
29	119	0	f	f
29	120	0	f	f
29	123	0	f	f
29	126	0	f	f
29	128	0	f	f
29	129	0	f	f
29	125	0	f	f
29	127	0	f	f
29	130	0	f	f
29	133	0	f	f
29	134	0	f	f
29	136	0	f	f
29	131	0	f	f
29	132	0	f	f
29	135	0	f	f
29	137	0	f	f
29	141	0	f	f
29	142	0	f	f
29	143	0	f	f
29	145	0	f	f
29	146	0	f	f
29	156	0	f	f
29	158	0	f	f
29	138	0	f	f
29	139	0	f	f
29	140	0	f	f
29	144	0	f	f
29	151	0	f	f
29	152	0	f	f
29	153	0	f	f
29	154	0	f	f
29	155	0	f	f
29	157	0	f	f
29	147	0	f	f
29	148	0	f	f
29	149	0	f	f
29	150	0	f	f
29	159	0	f	f
29	165	0	f	f
29	166	0	f	f
29	160	0	f	f
29	161	0	f	f
29	162	0	f	f
29	163	0	f	f
29	164	0	f	f
30	90	0	f	f
30	86	0	f	f
30	91	0	f	f
30	92	0	f	f
30	93	0	f	f
30	98	0	f	f
30	87	0	f	f
30	88	0	f	f
30	89	0	f	f
30	94	0	f	f
30	95	0	f	f
30	96	0	f	f
30	97	0	f	f
30	99	0	f	f
30	100	0	f	f
30	101	0	f	f
30	104	0	f	f
30	102	0	f	f
30	107	0	f	f
30	116	0	f	f
30	113	0	f	f
30	118	0	f	f
30	103	0	f	f
30	105	0	f	f
30	106	0	f	f
30	108	0	f	f
30	109	0	f	f
30	110	0	f	f
30	111	0	f	f
30	112	0	f	f
30	121	0	f	f
30	122	0	f	f
30	124	0	f	f
30	114	0	f	f
30	115	0	f	f
30	117	0	f	f
30	119	0	f	f
30	120	0	f	f
30	123	0	f	f
30	126	0	f	f
30	128	0	f	f
30	129	0	f	f
30	125	0	f	f
30	127	0	f	f
30	130	0	f	f
30	133	0	f	f
30	134	0	f	f
30	136	0	f	f
30	131	0	f	f
30	132	0	f	f
30	135	0	f	f
30	137	0	f	f
30	141	0	f	f
30	142	0	f	f
30	143	0	f	f
30	145	0	f	f
30	146	0	f	f
30	156	0	f	f
30	158	0	f	f
30	138	0	f	f
30	139	0	f	f
30	140	0	f	f
30	144	0	f	f
30	151	0	f	f
30	152	0	f	f
30	153	0	f	f
30	154	0	f	f
30	155	0	f	f
30	157	0	f	f
30	147	0	f	f
30	148	0	f	f
30	149	0	f	f
30	150	0	f	f
30	159	0	f	f
30	165	0	f	f
30	166	0	f	f
30	160	0	f	f
30	161	0	f	f
30	162	0	f	f
30	163	0	f	f
30	164	0	f	f
40	90	0	f	f
40	86	0	f	f
40	91	0	f	f
40	92	0	f	f
40	93	0	f	f
40	98	0	f	f
40	87	0	f	f
40	88	0	f	f
40	89	0	f	f
40	94	0	f	f
40	95	0	f	f
40	96	0	f	f
40	97	0	f	f
40	99	0	f	f
40	100	0	f	f
40	101	0	f	f
40	104	0	f	f
40	102	0	f	f
40	107	0	f	f
40	116	0	f	f
40	113	0	f	f
40	118	0	f	f
40	103	0	f	f
40	105	0	f	f
40	106	0	f	f
40	108	0	f	f
40	109	0	f	f
40	110	0	f	f
40	111	0	f	f
40	112	0	f	f
40	121	0	f	f
40	122	0	f	f
40	124	0	f	f
40	114	0	f	f
40	115	0	f	f
40	117	0	f	f
40	119	0	f	f
40	120	0	f	f
40	123	0	f	f
40	128	0	f	f
40	129	0	f	f
40	130	0	f	f
40	133	0	f	f
40	134	0	f	f
40	136	0	f	f
40	131	0	f	f
40	132	0	f	f
40	135	0	f	f
40	137	0	f	f
40	141	0	f	f
40	142	0	f	f
40	143	0	f	f
40	145	0	f	f
40	146	0	f	f
40	156	0	f	f
40	158	0	f	f
40	138	0	f	f
40	139	0	f	f
40	140	0	f	f
40	144	0	f	f
40	151	0	f	f
40	152	0	f	f
40	153	0	f	f
40	154	0	f	f
40	155	0	f	f
40	157	0	f	f
40	147	0	f	f
40	148	0	f	f
40	149	0	f	f
40	150	0	f	f
40	159	0	f	f
40	165	0	f	f
40	166	0	f	f
40	160	0	f	f
40	161	0	f	f
40	162	0	f	f
40	163	0	f	f
40	164	0	f	f
39	90	0	f	f
39	86	0	f	f
39	91	0	f	f
39	92	0	f	f
39	93	0	f	f
39	98	0	f	f
39	87	0	f	f
39	88	0	f	f
39	89	0	f	f
39	94	0	f	f
39	95	0	f	f
39	96	0	f	f
39	97	0	f	f
39	99	0	f	f
39	100	0	f	f
39	101	0	f	f
39	104	0	f	f
39	102	0	f	f
39	107	0	f	f
39	116	0	f	f
39	113	0	f	f
39	118	0	f	f
39	103	0	f	f
39	105	0	f	f
39	106	0	f	f
39	108	0	f	f
39	109	0	f	f
39	110	0	f	f
39	111	0	f	f
39	112	0	f	f
39	121	0	f	f
39	122	0	f	f
39	124	0	f	f
39	114	0	f	f
39	115	0	f	f
39	117	0	f	f
39	119	0	f	f
39	120	0	f	f
39	123	0	f	f
39	126	0	f	f
39	128	0	f	f
39	129	0	f	f
39	125	0	f	f
39	127	0	f	f
39	130	0	f	f
39	133	0	f	f
39	134	0	f	f
39	136	0	f	f
39	131	0	f	f
39	132	0	f	f
39	135	0	f	f
39	137	0	f	f
39	141	0	f	f
39	142	0	f	f
39	143	0	f	f
39	145	0	f	f
39	146	0	f	f
39	156	0	f	f
39	158	0	f	f
39	138	0	f	f
39	139	0	f	f
39	140	0	f	f
39	144	0	f	f
39	151	0	f	f
39	152	0	f	f
39	153	0	f	f
39	154	0	f	f
39	155	0	f	f
39	157	0	f	f
39	147	0	f	f
39	148	0	f	f
39	149	0	f	f
39	150	0	f	f
39	159	0	f	f
39	165	0	f	f
39	166	0	f	f
39	160	0	f	f
39	161	0	f	f
39	162	0	f	f
39	163	0	f	f
39	164	0	f	f
42	90	0	f	f
42	86	0	f	f
42	91	0	f	f
42	92	0	f	f
42	93	0	f	f
42	98	0	f	f
42	87	0	f	f
42	88	0	f	f
42	89	0	f	f
42	94	0	f	f
42	95	0	f	f
42	96	0	f	f
42	97	0	f	f
42	99	0	f	f
42	100	0	f	f
42	101	0	f	f
42	104	0	f	f
42	102	0	f	f
42	107	0	f	f
42	116	0	f	f
42	113	0	f	f
42	118	0	f	f
42	103	0	f	f
42	105	0	f	f
42	106	0	f	f
42	108	0	f	f
42	109	0	f	f
42	110	0	f	f
42	111	0	f	f
42	112	0	f	f
42	121	0	f	f
42	122	0	f	f
42	124	0	f	f
42	114	0	f	f
42	115	0	f	f
42	117	0	f	f
42	119	0	f	f
42	120	0	f	f
42	123	0	f	f
42	126	0	f	f
42	128	0	f	f
42	129	0	f	f
42	125	0	f	f
42	127	0	f	f
42	130	0	f	f
42	133	0	f	f
42	134	0	f	f
42	136	0	f	f
42	131	0	f	f
42	132	0	f	f
42	135	0	f	f
42	137	0	f	f
42	141	0	f	f
42	142	0	f	f
42	143	0	f	f
42	145	0	f	f
42	146	0	f	f
42	156	0	f	f
42	158	0	f	f
42	138	0	f	f
42	139	0	f	f
42	140	0	f	f
42	144	0	f	f
42	151	0	f	f
42	152	0	f	f
42	153	0	f	f
42	154	0	f	f
42	155	0	f	f
42	157	0	f	f
42	147	0	f	f
42	148	0	f	f
42	149	0	f	f
42	150	0	f	f
42	159	0	f	f
42	165	0	f	f
42	166	0	f	f
42	160	0	f	f
42	161	0	f	f
42	162	0	f	f
42	163	0	f	f
42	164	0	f	f
43	90	0	f	f
43	86	0	f	f
43	91	0	f	f
43	92	0	f	f
43	93	0	f	f
43	98	0	f	f
43	87	0	f	f
43	88	0	f	f
43	89	0	f	f
43	94	0	f	f
43	95	0	f	f
43	96	0	f	f
43	97	0	f	f
43	99	0	f	f
43	100	0	f	f
43	101	0	f	f
43	104	0	f	f
43	102	0	f	f
43	107	0	f	f
43	116	0	f	f
43	113	0	f	f
43	118	0	f	f
43	103	0	f	f
43	105	0	f	f
43	106	0	f	f
43	108	0	f	f
43	109	0	f	f
43	110	0	f	f
43	111	0	f	f
43	112	0	f	f
43	121	0	f	f
43	122	0	f	f
43	124	0	f	f
43	114	0	f	f
43	115	0	f	f
43	117	0	f	f
43	119	0	f	f
43	120	0	f	f
43	123	0	f	f
43	128	0	f	f
43	129	0	f	f
43	130	0	f	f
43	133	0	f	f
43	134	0	f	f
43	136	0	f	f
43	131	0	f	f
43	132	0	f	f
43	135	0	f	f
43	137	0	f	f
43	141	0	f	f
43	142	0	f	f
43	143	0	f	f
43	145	0	f	f
43	146	0	f	f
43	156	0	f	f
43	158	0	f	f
43	138	0	f	f
43	139	0	f	f
43	140	0	f	f
43	144	0	f	f
43	151	0	f	f
43	152	0	f	f
43	153	0	f	f
43	154	0	f	f
43	155	0	f	f
43	157	0	f	f
43	147	0	f	f
43	148	0	f	f
43	149	0	f	f
43	150	0	f	f
43	159	0	f	f
43	165	0	f	f
43	166	0	f	f
43	160	0	f	f
43	161	0	f	f
43	162	0	f	f
43	163	0	f	f
43	164	0	f	f
1	86	0	f	t
1	87	0	f	t
1	88	0	f	t
2	86	0	f	t
2	87	0	f	t
2	88	0	f	t
13	90	0	f	t
13	91	0	f	t
13	89	0	f	t
14	90	0	f	t
14	91	0	f	t
14	89	0	f	t
4	104	0	f	t
4	105	0	f	t
4	106	0	f	t
5	104	0	f	t
5	105	0	f	t
5	106	0	f	t
7	92	0	f	t
7	93	0	f	t
7	94	0	f	t
8	92	0	f	t
8	93	0	f	t
8	94	0	f	t
10	95	0	f	t
10	96	0	f	t
10	97	0	f	t
11	95	0	f	t
11	96	0	f	t
11	97	0	f	t
16	99	0	f	t
16	100	0	f	t
17	98	0	f	t
17	99	0	f	t
17	100	0	f	t
19	101	0	f	t
19	102	0	f	t
19	103	0	f	t
20	101	0	f	t
20	102	0	f	t
20	103	0	f	t
22	107	0	f	t
22	108	0	f	t
22	109	0	f	t
23	107	0	f	t
23	108	0	f	t
23	109	0	f	t
26	110	0	f	t
26	111	0	f	t
26	112	0	f	t
28	113	0	f	t
28	114	0	f	t
28	115	0	f	t
29	113	0	f	t
29	114	0	f	t
29	115	0	f	t
32	116	0	f	t
32	118	0	f	t
32	117	0	f	t
34	121	0	f	t
34	119	0	f	t
34	120	0	f	t
35	121	0	f	t
35	119	0	f	t
35	120	0	f	t
37	122	0	f	t
37	124	0	f	t
37	123	0	f	t
38	122	0	f	t
38	124	0	f	t
38	123	0	f	t
40	126	0	f	t
40	125	0	f	t
40	127	0	f	t
43	126	0	f	t
43	125	0	f	t
43	127	0	f	t
44	128	0	f	t
44	129	0	f	t
44	130	0	f	t
1	90	0	t	f
1	96	0	t	f
1	103	0	t	f
1	114	0	t	f
1	130	0	t	f
1	145	0	t	f
1	154	0	t	f
1	161	0	t	f
2	95	0	t	f
2	118	0	t	f
2	124	0	t	f
2	125	0	t	f
2	127	0	t	f
2	130	0	t	f
2	133	0	t	f
2	134	0	t	f
2	136	0	t	f
2	131	0	t	f
2	132	0	t	f
2	135	0	t	f
2	137	0	t	f
2	141	0	t	f
2	142	0	t	f
2	143	0	t	f
2	145	0	t	f
2	146	0	t	f
2	156	0	t	f
2	158	0	t	f
2	138	0	t	f
2	139	0	t	f
2	140	0	t	f
2	144	0	t	f
2	151	0	t	f
2	152	0	t	f
2	153	0	t	f
2	154	0	t	f
2	155	0	t	f
2	157	0	t	f
2	147	0	t	f
2	148	0	t	f
2	149	0	t	f
2	150	0	t	f
2	159	0	t	f
2	165	0	t	f
2	166	0	t	f
2	160	0	t	f
2	161	0	t	f
2	162	0	t	f
2	163	0	t	f
2	164	0	t	f
3	90	0	t	f
3	86	0	t	f
3	91	0	t	f
3	92	0	t	f
3	93	0	t	f
3	98	0	t	f
3	87	0	t	f
3	88	0	t	f
3	89	0	t	f
3	94	0	t	f
3	95	0	t	f
3	96	0	t	f
3	97	0	t	f
3	99	0	t	f
3	100	0	t	f
3	101	0	t	f
3	104	0	t	f
3	102	0	t	f
3	107	0	t	f
3	116	0	t	f
3	113	0	t	f
3	118	0	t	f
3	103	0.100000001	t	f
3	105	0	t	f
3	106	0	t	f
3	108	0	t	f
3	109	0	t	f
3	110	0	t	f
3	111	0	t	f
3	112	0	t	f
3	120	0	t	f
3	131	0	t	f
3	138	0	t	f
3	148	0	t	f
4	90	0	t	f
4	96	0	t	f
4	108	0	t	f
4	119	0	t	f
4	136	0	t	f
4	158	0	t	f
4	157	0	t	f
4	147	0	t	f
4	148	0	t	f
4	149	0	t	f
4	150	0	t	f
4	159	0	t	f
4	165	0	t	f
4	166	0	t	f
4	160	0	t	f
4	161	0	t	f
4	162	0	t	f
4	163	0	t	f
4	164	0	t	f
5	90	0	t	f
5	86	0	t	f
5	91	0	t	f
5	92	0	t	f
5	93	0	t	f
5	98	0	t	f
5	87	0	t	f
5	88	0	t	f
5	89	0	t	f
5	94	0	t	f
5	95	0	t	f
5	96	0	t	f
5	97	0	t	f
5	99	0	t	f
5	100	0	t	f
5	101	0	t	f
5	102	0	t	f
5	107	0	t	f
5	116	0	t	f
5	113	0	t	f
5	118	0	t	f
5	103	0	t	f
5	108	0	t	f
5	109	0	t	f
5	110	0	t	f
5	111	0	t	f
5	112	0	t	f
5	121	0	t	f
5	122	0	t	f
5	124	0	t	f
5	114	0	t	f
5	115	0	t	f
5	117	0	t	f
5	119	0	t	f
5	120	0	t	f
5	123	0	t	f
5	126	0	t	f
5	128	0	t	f
5	129	0	t	f
5	125	0	t	f
5	127	0	t	f
5	130	0	t	f
5	133	0	t	f
5	134	0	t	f
5	136	0	t	f
5	131	0	t	f
5	132	0	t	f
5	135	0	t	f
5	137	0	t	f
5	141	0	t	f
5	142	0	t	f
5	143	0	t	f
5	145	0	t	f
5	146	0	t	f
5	156	0	t	f
5	158	0	t	f
5	154	0	t	f
5	161	0	t	f
6	88	0	t	f
6	107	0	t	f
6	112	0	t	f
6	128	0	t	f
6	137	0	t	f
6	144	0	t	f
6	159	0	t	f
7	98	0	t	f
7	104	0	t	f
7	102	0	t	f
7	107	0	t	f
7	116	0	t	f
7	113	0	t	f
7	118	0	t	f
7	103	0	t	f
7	105	0	t	f
7	106	0	t	f
7	108	0	t	f
7	109	0	t	f
7	110	0	t	f
7	111	0	t	f
7	112	0	t	f
7	121	0	t	f
7	122	0	t	f
7	124	0.25	t	f
7	114	0	t	f
7	115	0	t	f
7	117	0	t	f
7	119	0	t	f
7	120	0	t	f
7	123	0	t	f
7	126	0	t	f
7	128	0	t	f
7	129	0	t	f
7	125	0	t	f
7	127	0	t	f
7	130	0	t	f
7	133	0	t	f
7	134	0	t	f
7	136	0	t	f
7	131	0	t	f
7	132	0	t	f
7	135	0	t	f
7	137	0	t	f
7	141	0	t	f
7	142	0	t	f
7	143	0	t	f
7	145	0	t	f
7	146	0	t	f
7	156	0	t	f
7	158	0	t	f
7	138	0	t	f
7	139	0	t	f
7	140	0	t	f
7	144	0	t	f
7	151	0	t	f
7	152	0	t	f
7	153	0	t	f
7	154	0	t	f
7	155	0	t	f
7	157	0	t	f
7	147	0	t	f
7	148	0	t	f
7	149	0	t	f
7	150	0	t	f
7	159	0	t	f
7	165	0	t	f
7	166	0	t	f
7	160	0	t	f
7	161	0	t	f
7	162	0	t	f
7	163	0	t	f
7	164	0	t	f
8	90	0	t	f
8	86	0	t	f
8	91	0	t	f
8	98	0	t	f
8	100	0	t	f
8	108	0	t	f
\.


--
-- Data for Name: query_words; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY query_words (query, word, pos, sense, synonyms) FROM stdin;
1	speaks	NNS		{}
1	in	IN		{}
1	chicago	NN		{stops,Michigan,Windy_City,boodle,Chicago,Newmarket}
1	obama	NN		{}
2	visits	NNS		{sojourn,visit}
2	obama	NN		{}
2	chicago	RB		{}
3	visit	VB		{inspect,confab,travel_to,chatter,chaffer,jaw,natter,chitchat,shoot_the_breeze,chat,chit-chat,visit,chew_the_fat,call_in,call,bring_down,claver,impose,inflict,gossip,see,confabulate}
3	obama	NN		{}
3	chicago	RB		{}
3	not	RB		{non,not}
3	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
4	wins	NNS		{win,profits,winnings}
4	2016	CD		{}
4	cruz	NN		{}
4	caucus	NN		{caucus}
4	iowa	NN		{Ioway,Hawkeye_State,Iowa,IA}
4	ted	VBD		{}
5	wins	NNS		{win,profits,winnings}
5	cruz	NN		{}
5	ted	VBD		{}
5	caucus	VBZ		{caucus}
6	win	VB		{succeed,acquire,win,advance,come_through,gain,get_ahead,pull_ahead,deliver_the_goods,make_headway,bring_home_the_bacon,gain_ground}
6	cruz	NN		{}
6	caucus	RB		{}
6	not	RB		{non,not}
6	ted	VBD		{}
6	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
7	anti	VBP		{}
7	releases	NNS		{firing,expiration,acquittance,vent,spillage,liberation,spill,dismission,waiver,discharge,passing,departure,tone_ending,button,sacking,exit,sack,release,press_release,freeing,dismissal,outlet,handout,loss,going}
7	album	NN		{album,record_album}
7	rihanna	NN		{}
8	releases	NNS		{firing,expiration,acquittance,vent,spillage,liberation,spill,dismission,waiver,discharge,passing,departure,tone_ending,button,sacking,exit,sack,release,press_release,freeing,dismissal,outlet,handout,loss,going}
8	album	NN		{album,record_album}
8	rihanna	NN		{}
9	release	VB		{unloosen,loose,unloose,resign,expel,unblock,turn,relinquish,liberate,let_go,discharge,bring_out,free,give_up,publish,exhaust,unfreeze,release,eject,issue,secrete,put_out,let_go_of}
9	album	NN		{album,record_album}
9	rihanna	NN		{}
9	not	RB		{non,not}
9	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
16	outbreak	NN		{irruption,eruption,outbreak}
16	chipotle	NN		{chipotle}
16	coli	NN		{}
16	e.	NNP		{}
16	has	VBZ		{accept,sustain,suffer,ingest,have_got,consume,get,possess,cause,stimulate,make,throw,own,give_birth,have,take_in,let,receive,feature,birth,induce,take,bear,give,deliver,experience,hold}
17	outbreak	JJ		{}
17	chipotle	NN		{chipotle}
17	has	VBZ		{accept,sustain,suffer,ingest,have_got,consume,get,possess,cause,stimulate,make,throw,own,give_birth,have,take_in,let,receive,feature,birth,induce,take,bear,give,deliver,experience,hold}
18	have	VB		{accept,sustain,suffer,ingest,have_got,consume,get,possess,cause,stimulate,make,throw,own,give_birth,have,take_in,let,receive,feature,birth,induce,take,bear,give,deliver,experience,hold}
18	outbreak	JJ		{}
18	chipotle	NN		{chipotle}
18	not	RB		{non,not}
18	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
22	logo	VBP		{}
22	changes	NNS		{change,variety,alteration,modification}
22	uber	NN		{}
23	logo	VBP		{}
23	changes	NNS		{change,variety,alteration,modification}
23	company	NN		{caller,ship's_company,party,fellowship,society,company,troupe,companionship}
23	tech	NN		{tech,technical_school}
24	change	VB		{alter,change,exchange,interchange,deepen,switch,modify,transfer,commute,vary,convert,shift}
24	uber	NN		{}
24	not	RB		{non,not}
24	logo	RB		{}
24	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
44	hits	NNS		{hitting,collision,strike,smasher,striking,hit,bang,smash}
44	hurricane	NN		{hurricane}
44	us	PRP		{}
45	occurs	NNS		{}
45	natural	JJ		{instinctive,rude,innate,lifelike,born,natural,raw}
45	in	IN		{}
45	disaster	NN		{tragedy,cataclysm,disaster,calamity,catastrophe}
45	us	PRP		{}
46	hit	VB		{slay,stumble,reach,come_to,attain,polish_off,dispatch,score,murder,hit,impinge_on,strike,run_into,gain,make,bump_off,arrive_at,collide_with,tally,remove,pip,off,rack_up,shoot}
46	hurricane	NN		{hurricane}
46	not	RB		{non,not}
46	us	PRP		{}
46	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
10	birth	JJ		{}
10	kate	NN		{}
10	middleton	VBD		{}
10	gives	VBZ		{fall_in,present,reach,commit,render,consecrate,pass,sacrifice,chip_in,cave_in,turn_over,give_way,hand,collapse,ease_up,pass_on,contribute,return,pay,make,founder,throw,grant,have,generate,move_over,kick_in,establish,feed,dedicate,impart,yield,apply,open,gift,break,leave,give,devote,afford,hold}
11	birth	JJ		{}
11	princess	NN		{princess}
11	gives	VBZ		{fall_in,present,reach,commit,render,consecrate,pass,sacrifice,chip_in,cave_in,turn_over,give_way,hand,collapse,ease_up,pass_on,contribute,return,pay,make,founder,throw,grant,have,generate,move_over,kick_in,establish,feed,dedicate,impart,yield,apply,open,gift,break,leave,give,devote,afford,hold}
12	give	VB		{fall_in,present,reach,commit,render,consecrate,pass,sacrifice,chip_in,cave_in,turn_over,give_way,hand,collapse,ease_up,pass_on,contribute,return,pay,make,founder,throw,grant,have,generate,move_over,kick_in,establish,feed,dedicate,impart,yield,apply,open,gift,break,leave,give,devote,afford,hold}
12	birth	JJ		{}
12	not	RB		{non,not}
12	kate	NN		{}
12	middleton	VBD		{}
12	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
13	visible	JJ		{seeable,visible}
13	comet	NN		{comet}
13	catalina	NN		{}
13	becomes	VBZ		{get,turn,go,suit,become}
14	visible	JJ		{seeable,visible}
14	comet	NN		{comet}
14	becomes	VBZ		{get,turn,go,suit,become}
15	become	VB		{get,turn,go,suit,become}
15	visible	JJ		{seeable,visible}
15	comet	NN		{comet}
15	not	RB		{non,not}
15	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
19	occurs	NNS		{}
19	shooting	VBG		{charge,inject,scud,scoot,buck,bourgeon,flash,blast,fool_away,film,fritter,fool,hit,tear,pullulate,snap,spud,shoot_down,dissipate,fritter_away,sprout,germinate,photograph,dash,pip,frivol_away,dart,take,burgeon_forth,shoot}
19	school	NN		{school_day,school,schooltime,schoolhouse,shoal,schooling}
20	occurs	NNS		{}
20	shooting	VBG		{charge,inject,scud,scoot,buck,bourgeon,flash,blast,fool_away,film,fritter,fool,hit,tear,pullulate,snap,spud,shoot_down,dissipate,fritter_away,sprout,germinate,photograph,dash,pip,frivol_away,dart,take,burgeon_forth,shoot}
20	mass	NN		{mass,volume,Mass,mint,flock,bulk,quite_a_little,raft,muckle,peck,multitude,wad,the_great_unwashed,good_deal,masses,deal,spate,tidy_sum,pot,heap,mess,passel,stack,lot,hoi_polloi,plenty,mickle,mountain,hatful,sight,pile,people,batch,great_deal,slew}
21	occur	VB		{pass,take_place,fall_out,go_on,occur,come,happen,pass_off,hap,come_about}
34	employees	NNS		{employee}
34	off	IN		{}
34	twitter	NN		{twitter,chirrup}
21	shooting	VBG		{charge,inject,scud,scoot,buck,bourgeon,flash,blast,fool_away,film,fritter,fool,hit,tear,pullulate,snap,spud,shoot_down,dissipate,fritter_away,sprout,germinate,photograph,dash,pip,frivol_away,dart,take,burgeon_forth,shoot}
21	school	NN		{school_day,school,schooltime,schoolhouse,shoal,schooling}
21	not	RB		{non,not}
21	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
25	drops	NNS		{drop-off,pearl,driblet,drop,bead,fall,dip,cliff,drop_curtain,free_fall,drop_cloth,drib}
25	presidential	JJ		{presidential}
25	of	IN		{}
25	out	IN		{}
25	race	NN		{wash,slipstream,subspecies,raceway,race,backwash,airstream}
25	candidate	NN		{nominee,campaigner,prospect,candidate}
26	drops	NNS		{drop-off,pearl,driblet,drop,bead,fall,dip,cliff,drop_curtain,free_fall,drop_cloth,drib}
26	presidential	JJ		{presidential}
26	of	IN		{}
26	out	IN		{}
26	o'malley	NN		{}
26	race	NN		{wash,slipstream,subspecies,raceway,race,backwash,airstream}
26	martin	NN		{Martin,martin,Dino_Paul_Crocetti,Steve_Martin,Mary_Martin,Dean_Martin,St._Martin}
27	drop	VB		{dangle,strike_down,put_down,set_down,dismiss,devolve,throw_away,cut_down,overleap,knock_off,shake_off,throw_off,overlook,neglect,drop,degenerate,drop_off,drop_down,drip,cast_off,discharge,leave_out,shed,swing,send_packing,deteriorate,expend,cast,throw,unload,omit,dribble,spend,flatten,fell,pretermit,miss,send_away,sink}
27	presidential	JJ		{presidential}
27	not	RB		{non,not}
27	out	RP		{}
27	of	IN		{}
27	o'malley	NN		{}
27	race	NN		{wash,slipstream,subspecies,raceway,race,backwash,airstream}
27	martin	NN		{Martin,martin,Dino_Paul_Crocetti,Steve_Martin,Mary_Martin,Dean_Martin,St._Martin}
27	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
28	are	VBP		{constitute,exist,equal,live,embody,make_up,be,comprise,personify,cost,follow,represent}
28	panthers	NNS		{panther,mountain_lion,cougar,puma,catamount,Felis_onca,Felis_concolor,jaguar,painter,Panthera_onca}
28	50	CD		{}
28	in	IN		{}
28	carolina	NN		{Carolinas,Carolina}
28	bowl	NN		{stadium,bowl,sports_stadium,bowlful,pipe_bowl,trough,roll,bowling_ball,arena}
28	super	NN		{superintendent,super}
31	see	VB		{encounter,regard,check,reckon,get_wind,go_through,catch,image,assure,discover,consider,insure,go_steady,see_to_it,view,realise,envision,project,hear,watch,go_out,fancy,picture,escort,date,ascertain,meet,witness,learn,run_into,visualize,ensure,determine,get_a_line,run_across,visit,take_in,look,find_out,interpret,examine,construe,visualise,come_across,control,figure,pick_up,understand,attend,take_care,get_word,find,experience,see,realize}
31	punxsutawney	NN		{}
31	phil	NN		{}
31	not	RB		{non,not}
31	shadow	RB		{}
31	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
32	see	VB		{encounter,regard,check,reckon,get_wind,go_through,catch,image,assure,discover,consider,insure,go_steady,see_to_it,view,realise,envision,project,hear,watch,go_out,fancy,picture,escort,date,ascertain,meet,witness,learn,run_into,visualize,ensure,determine,get_a_line,run_across,visit,take_in,look,find_out,interpret,examine,construe,visualise,come_across,control,figure,pick_up,understand,attend,take_care,get_word,find,experience,see,realize}
32	groundhog	NN		{groundhog,woodchuck,Marmota_monax}
32	not	RB		{non,not}
32	shadow	RB		{}
32	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
33	shadow	VBP		{dwarf,shade,overshadow,shadow,shade_off}
33	sees	NNS		{see}
33	groundhog	NN		{groundhog,woodchuck,Marmota_monax}
34	lays	NNS		{lay,ballad}
35	employees	NNS		{employee}
35	off	RP		{}
35	company	NN		{caller,ship's_company,party,fellowship,society,company,troupe,companionship}
35	tech	NN		{tech,technical_school}
35	lays	VBZ		{lay,place,pose,put_down,repose,set,put,position}
36	lay	VB		{rest,lay,place,pose,put_down,repose,set,lie_down,consist,put,lie_in,lie,dwell,position}
36	not	RB		{non,not}
36	employees	NNS		{employee}
36	off	RP		{}
36	twitter	NN		{twitter,chirrup}
36	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
37	dies	NNS		{dice,die,dysprosium,atomic_number_66,Dy}
37	winehouse	NN		{}
37	amy	PRP$		{}
38	dies	NNS		{dice,die,dysprosium,atomic_number_66,Dy}
38	famous	JJ		{famous,renowned,noted,notable,celebrated,illustrious,far-famed,famed}
38	someone	NN		{individual,person,someone,mortal,soul,somebody}
29	are	VBP		{constitute,exist,equal,live,embody,make_up,be,comprise,personify,cost,follow,represent}
29	panthers	NNS		{panther,mountain_lion,cougar,puma,catamount,Felis_onca,Felis_concolor,jaguar,painter,Panthera_onca}
29	in	IN		{}
29	carolina	NN		{Carolinas,Carolina}
29	bowl	NN		{stadium,bowl,sports_stadium,bowlful,pipe_bowl,trough,roll,bowling_ball,arena}
29	super	NN		{superintendent,super}
30	50	CD		{}
30	not	RB		{non,not}
30	are	VBP		{constitute,exist,equal,live,embody,make_up,be,comprise,personify,cost,follow,represent}
30	carolina	NN		{Carolinas,Carolina}
30	bowl	NN		{stadium,bowl,sports_stadium,bowlful,pipe_bowl,trough,roll,bowling_ball,arena}
30	super	NN		{superintendent,super}
30	in	IN		{}
30	panthers	NNS		{panther,mountain_lion,cougar,puma,catamount,Felis_onca,Felis_concolor,jaguar,painter,Panthera_onca}
40	retrial	JJ		{}
40	to	TO		{}
40	for	IN		{}
40	adnan	NN		{}
40	court	NN		{court_of_law,court,court_of_justice,royal_court,tourist_court,Court,tribunal,lawcourt,Margaret_Court,judicature,motor_lodge,courtroom,motor_hotel,homage,motor_inn,courtyard}
40	syed	VBD		{}
40	goes	VBZ		{go_away,last,fit,expire,run_low,decease,die,conk_out,perish,pass_away,conk,lead,go,run,pass,croak,belong,fail,depart,give_way,get,survive,buy_the_farm,give_out,snuff_it,live_on,rifle,give-up_the_ghost,drop_dead,pop_off,start,plump,work,operate,endure,get_going,sound,extend,function,cash_in_one's_chips,live,run_short,exit,choke,travel,blend,locomote,move,blend_in,break,break_down,go_bad,become,hold_out,kick_the_bucket,hold_up,proceed}
39	die	VB		{expire,become_flat,decease,die,conk_out,perish,pass_away,conk,go,pass,croak,fail,give_way,buy_the_farm,give_out,snuff_it,give-up_the_ghost,drop_dead,pop_off,pall,cash_in_one's_chips,exit,die_out,choke,break,break_down,go_bad,kick_the_bucket}
39	winehouse	NN		{}
39	not	RB		{non,not}
39	amy	PRP$		{}
39	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
42	court	VB		{solicit,court,woo,romance}
42	go	VB		{go_away,last,fit,expire,run_low,decease,die,conk_out,perish,pass_away,conk,lead,go,run,pass,croak,belong,fail,depart,give_way,get,survive,buy_the_farm,give_out,snuff_it,live_on,rifle,give-up_the_ghost,drop_dead,pop_off,start,plump,work,operate,endure,get_going,sound,extend,function,cash_in_one's_chips,live,run_short,exit,choke,travel,blend,locomote,move,blend_in,break,break_down,go_bad,become,hold_out,kick_the_bucket,hold_up,proceed}
42	not	RB		{non,not}
42	to	TO		{}
42	adnan	NN		{}
42	syed	VBD		{}
42	does	VBZ		{perform,manage,suffice,do,execute,coiffure,cause,make_out,answer,coif,practice,set,make,get_along,dress,fare,exercise,coiffe,practise,come,serve,arrange,behave,act}
43	adnan	NN		{}
43	court	NN		{court_of_law,court,court_of_justice,royal_court,tourist_court,Court,tribunal,lawcourt,Margaret_Court,judicature,motor_lodge,courtroom,motor_hotel,homage,motor_inn,courtyard}
43	to	TO		{}
43	syed	VBD		{}
43	goes	VBZ		{go_away,last,fit,expire,run_low,decease,die,conk_out,perish,pass_away,conk,lead,go,run,pass,croak,belong,fail,depart,give_way,get,survive,buy_the_farm,give_out,snuff_it,live_on,rifle,give-up_the_ghost,drop_dead,pop_off,start,plump,work,operate,endure,get_going,sound,extend,function,cash_in_one's_chips,live,run_short,exit,choke,travel,blend,locomote,move,blend_in,break,break_down,go_bad,become,hold_out,kick_the_bucket,hold_up,proceed}
\.


--
-- Data for Name: sources; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY sources (id, source_name, reliability) FROM stdin;
1	TEST_SOURCE	1
2	CNN	1
\.


--
-- Name: sources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: username-to-replace
--

SELECT pg_catalog.setval('sources_id_seq', 4, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY users (id, phone, email) FROM stdin;
1	555-555-5555	username-to-replacejpb+event_detection_test@gmail.com
2	\N	event.detection.carleton@gmail.com
3	\N	event.detection.carleton@gmail.com
4	\N	event.detection.carleton@gmail.com
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: username-to-replace
--

SELECT pg_catalog.setval('users_id_seq', 4, true);


--
-- Data for Name: validation_algorithms; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY validation_algorithms (id, algorithm, enabled, base_class, validator_type, threshold, parameters) FROM stdin;
19	Keyword	t	eventdetection.validator.implementations.KeywordValidator	OneToOne	0.5	"KeywordValidator.json"
20	Swoogle Semantic Analysis	t	eventdetection.validator.implementations.SwoogleSemanticAnalysisValidator	OneToOne	0.5	{"instance": {"url-prefix": "http://swoogle.umbc.edu/StsService/GetStsSim?operation=api", "max-sentences": 5}}
21	SEMILAR Semantic Analysis	t	eventdetection.validator.implementations.SEMILARSemanticAnalysisValidator	OneToOne	0.5	"SEMILARSemanticAnalysisValidator.json"
22	TextRank Swoogle Semantic Analysis	t	eventdetection.validator.implementations.TextRankSwoogleSemanticAnalysisValidator	OneToOne	0.5	{"instance": {"url-prefix": "http://swoogle.umbc.edu/StsService/GetStsSim?operation=api"}}
23	Clustering	t	eventdetection.validator.implementations.ClusteringValidator	ManyToMany	0.5	\N
\.


--
-- Name: validation_algorithms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: username-to-replace
--

SELECT pg_catalog.setval('validation_algorithms_id_seq', 23, true);


--
-- Data for Name: validation_results; Type: TABLE DATA; Schema: public; Owner: username-to-replace
--

COPY validation_results (query, algorithm, article, validates, invalidates) FROM stdin;
\.


--
-- Name: articles_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: articles_url_key; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY articles
    ADD CONSTRAINT articles_url_key UNIQUE (url);


--
-- Name: feeds_feed_name_key; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_feed_name_key UNIQUE (feed_name);


--
-- Name: feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (id);


--
-- Name: feeds_url_key; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_url_key UNIQUE (url);


--
-- Name: queries_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY queries
    ADD CONSTRAINT queries_pkey PRIMARY KEY (id);


--
-- Name: query_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY query_articles
    ADD CONSTRAINT query_articles_pkey PRIMARY KEY (query, article);


--
-- Name: query_words_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY query_words
    ADD CONSTRAINT query_words_pkey PRIMARY KEY (query, word, pos, sense);


--
-- Name: sources_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: sources_source_name_key; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_source_name_key UNIQUE (source_name);


--
-- Name: unique_queries; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY queries
    ADD CONSTRAINT unique_queries UNIQUE (userid, subject, verb, direct_obj, indirect_obj, loc);


--
-- Name: unique_users; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY users
    ADD CONSTRAINT unique_users UNIQUE (phone, email);


--
-- Name: unqiue_algorithm; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY validation_algorithms
    ADD CONSTRAINT unqiue_algorithm UNIQUE (algorithm);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: validation_algorithms_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY validation_algorithms
    ADD CONSTRAINT validation_algorithms_pkey PRIMARY KEY (id);


--
-- Name: validation_results_pkey; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY validation_results
    ADD CONSTRAINT validation_results_pkey PRIMARY KEY (query, algorithm, article);


--
-- Name: word_pos; Type: CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY query_words
    ADD CONSTRAINT word_pos UNIQUE (query, word, pos);


--
-- Name: generate_invalidates; Type: TRIGGER; Schema: public; Owner: username-to-replace
--

CREATE TRIGGER generate_invalidates BEFORE INSERT OR UPDATE ON validation_results FOR EACH ROW EXECUTE PROCEDURE generate_invalidates();


--
-- Name: make_empty_string; Type: TRIGGER; Schema: public; Owner: username-to-replace
--

CREATE TRIGGER make_empty_string BEFORE INSERT OR UPDATE ON queries FOR EACH ROW EXECUTE PROCEDURE make_empty_string();


--
-- Name: articles_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY articles
    ADD CONSTRAINT articles_source_fkey FOREIGN KEY (source) REFERENCES sources(id) ON DELETE CASCADE;


--
-- Name: feeds_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_source_fkey FOREIGN KEY (source) REFERENCES sources(id) ON DELETE CASCADE;


--
-- Name: queries_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY queries
    ADD CONSTRAINT queries_userid_fkey FOREIGN KEY (userid) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: query_articles_article_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY query_articles
    ADD CONSTRAINT query_articles_article_fkey FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE;


--
-- Name: query_articles_query_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY query_articles
    ADD CONSTRAINT query_articles_query_fkey FOREIGN KEY (query) REFERENCES queries(id) ON DELETE CASCADE;


--
-- Name: query_words_query_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY query_words
    ADD CONSTRAINT query_words_query_fkey FOREIGN KEY (query) REFERENCES queries(id) ON DELETE CASCADE;


--
-- Name: validation_results_algorithm_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY validation_results
    ADD CONSTRAINT validation_results_algorithm_fkey FOREIGN KEY (algorithm) REFERENCES validation_algorithms(id) ON DELETE CASCADE;


--
-- Name: validation_results_article_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY validation_results
    ADD CONSTRAINT validation_results_article_fkey FOREIGN KEY (article) REFERENCES articles(id) ON DELETE CASCADE;


--
-- Name: validation_results_query_fkey; Type: FK CONSTRAINT; Schema: public; Owner: username-to-replace
--

ALTER TABLE ONLY validation_results
    ADD CONSTRAINT validation_results_query_fkey FOREIGN KEY (query) REFERENCES queries(id) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: username-to-replace
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM username-to-replace;
GRANT ALL ON SCHEMA public TO username-to-replace;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

