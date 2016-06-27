#!/usr/bin/python

# import cgitb
# cgitb.enable()
import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

import psycopg2
import re
from Utils.Globals import *


class DataSource:
    def __init__(self):
        """
        Create a DataSource object
        :return: None
        """
        db = database
        try:
            # create a connection to event_detection database
            conn = psycopg2.connect(user='root', database=db)
            conn.autocommit = True
        except:
            print("Error: cannot connect to event_detection database")
            sys.exit()
        try:
            self.cursor = conn.cursor()
        except:
            print("Error: cannot create cursor")
            sys.exit()

    def get_unprocessed_queries(self):
        """
        Gets all queries from the database that are not yet marked as processed
        :return: all unprocessed queries
        """
        self.cursor.execute("SELECT q.id, q.subject, q.verb, q.direct_obj, q.indirect_obj, q.loc \
                             FROM queries q \
                             WHERE q.processed = false")
        return self.cursor.fetchall()

    def get_unprocessed_query_article_pairs(self):
        """
        Gets all query-article pairs that are not marked as processed
        :return: all unprocessed query-article pairs
        """
        self.cursor.execute("SELECT qa.query, qa.article FROM query_articles qa\
                            WHERE qa.processed = false")
        return self.cursor.fetchall()

    def get_query_synonyms(self, query_id):
        """
        Gets information about a query
        :param query_id: the query to retrieve synonyms for
        :return: word, pos, sense and synonyms for the query
        """
        self.cursor.execute("SELECT word, pos, sense, synonyms FROM query_words WHERE query=%s", (query_id,))
        return self.cursor.fetchall()

    def get_article_keywords(self, article_id):
        """
        Gets keywords for an article
        :param article_id: the id to retrieve keywords for
        :return: the keywords for the article
        """
        self.cursor.execute("SELECT keywords FROM articles WHERE id=%s", (article_id, ))
        words = self.cursor.fetchone()
        return words

    def get_all_article_keywords(self):
        """
        Gets keywords for all articles
        :return: the keywords for all articles
        """
        self.cursor.execute("SELECT keywords FROM articles WHERE keywords IS NOT null;")
        return self.cursor.fetchall()

    def get_all_titles_and_keywords(self):
        """
        Gets titles and keywords for all articles
        Does not retrieve these if the keywords are null (article unprocessed)
        :return: titles and keywords for all articles
        """
        self.cursor.execute("SELECT title, keywords FROM articles WHERE keywords IS NOT null;")
        return self.cursor.fetchall()

    def get_all_article_ids_and_keywords(self):
        """
        Gets ids and keywords for all articles
        Does not retrieve these if the keywords are null (article unprocessed)
        :return: ids and keywords for all articles
        """
        self.cursor.execute("SELECT id, keywords FROM articles WHERE keywords IS NOT null;")
        return self.cursor.fetchall()

    def get_articles(self):
        """
        Gets all article ids
        :return: ids for all articles
        """
        self.cursor.execute("SELECT id FROM articles")
        return self.cursor.fetchall()

    def get_all_article_ids_and_filenames(self):
        """
        Gets ids and filenames for all articles
        :return: ids and filenames for all articles
        """
        self.cursor.execute("SELECT id, filename FROM articles;")
        return self.cursor.fetchall()

    def get_article_ids_titles_filenames(self):
        """
        Gets ids, titles and filenames for all articles
        :return: ids, titles and filenames for all articles
        """
        self.cursor.execute("SELECT id, title, filename FROM articles;")
        return self.cursor.fetchall()

    def insert_query_word_synonym(self, query_id, query_word, pos_group, synonyms):
        """
        Inserts information about a query into query words
        :param query_id: the id of the query
        :param query_word: the word from the query
        :param pos_group: to POS for the query word
        :param synonyms: the synonyms for the query word
        :return: None
        """
        self.cursor.execute("INSERT INTO query_words (query, word, pos, sense, synonyms) VALUES (%s, %s ,%s, '',%s)", \
                                    (query_id, query_word, pos_group, synonyms))

    def post_validator_update(self, matching_prob, query_id, article_id):
        """
        Updates query articles after the validator is run
        :param matching_prob: the probability of the match
        :param query_id: the query id
        :param article_id: the article id
        :return: None
        """
        self.cursor.execute("UPDATE query_articles SET processed=true, accuracy=%s WHERE query=%s AND article=%s",\
                           (matching_prob, query_id, article_id))

    def post_query_processor_update(self, query_id):
        """
        Sets a query to processed in the database
        This involves setting it to processed in the queries table and adding a row with it and all articles
        in the query_articles table
        :param query_id: the query id
        :return: None
        """
        self.cursor.execute("UPDATE queries SET processed=true WHERE id=%s", (query_id, ))
        for article_id in self.get_articles():
            self.cursor.execute("INSERT  INTO query_articles (query, article) VALUES (%s, %s) ON CONFLICT DO NOTHING", (query_id, article_id))

    def get_query_elements(self, query_id):
        """
        Gets the subject, verb, direct object, indirect object and location for a query
        :param query_id: the query id
        :return: the subject, verb, direct object, indirect object and location
        """
        self.cursor.execute("SELECT subject, verb, direct_obj, indirect_obj, loc FROM queries WHERE id=%s", (query_id, ))
        elements = self.cursor.fetchone()
        elements = [element for element in elements if element is not None or element is not ""]
        return elements

    def get_article_url(self, article_id):
        """
        Gets the URL for an article
        :param article_id: the article id
        :return: the article URL
        """
        self.cursor.execute("SELECT url FROM articles WHERE id=%s", (article_id, ))
        return str(self.cursor.fetchone()[0])

    def get_article_title(self, article_id):
        """
        Gets the title for an article
        :param article_id: the article id
        :return: the article title
        """
        self.cursor.execute("SELECT title FROM articles WHERE id=%s", (article_id, ))
        return str(self.cursor.fetchone()[0])

    def get_email_and_phone(self, query_id):
        """
        Gets the article and phone number associated to a query
        :param query_id: the query id
        :return: the phone number and email
        """
        self.cursor.execute("SELECT userid FROM queries WHERE id="+str(query_id))
        user_id = self.cursor.fetchone()[0]
        self.cursor.execute("SELECT phone FROM users WHERE id="+str(user_id))
        phone = str(self.cursor.fetchone()[0])
        if phone is not None:
            phone = re.sub(r'-', '', phone)
            phone = "+1" + phone
        self.cursor.execute("SELECT email FROM users WHERE id="+str(user_id))
        email = str(self.cursor.fetchone()[0])
        return phone, email

    def get_unprocessed_articles(self):
        """
        Gets all unprocessed articles that need keyword extraction to be performed
        :return: id, title, filename, url and source for all unprocessed articles
        """
        self.cursor.execute("SELECT id, title, filename, url, source FROM articles WHERE keywords is null;")
        return self.cursor.fetchall()

    def add_keywords_to_article(self, article_id, keyword_string):
        """
        Adds keyword JSON string to an article
        :param article_id: the article id
        :param keyword_string: the JSON string of keywords
        :return: None
        """
        self.cursor.execute("UPDATE articles SET keywords = %s WHERE id = %s", (keyword_string, article_id))

    def article_processed(self, article_id):
        """
        Checks if an article has been processed
        :param article_id: the id of the article
        :return: True if the article has been processed, False otherwise
        """
        self.cursor.execute("SELECT keywords FROM articles WHERE id = %s;", (article_id, ))
        return self.cursor.fetchone()[0] is not None

    def query_route(self, query_id):
        """
        Gets a query for web app with validating article counts
        :param query_id: the id of the query
        :return: the query
        """
        self.cursor.execute("SELECT a.title, s.source_name as source, a.url \
                    FROM queries q \
                    INNER JOIN query_articles qa on q.id = qa.query \
                    INNER JOIN articles a on qa.article = a.id \
                    INNER JOIN sources s on s.id = a.source \
                    WHERE q.id = %s and qa.notification_sent = true;", (query_id,))
        articles = self.cursor.fetchall()

        self.cursor.execute("SELECT id, subject, verb, direct_obj, indirect_obj, loc FROM queries where id = %s;", (query_id,))
        query = self.cursor.fetchone()
        return articles, query

    def queries_route(self):
        """
        Gets all queries for web app with validating article counts
        :return: all queries
        """
        self.cursor.execute("SELECT q.id, q.subject, q.verb, q.direct_obj, q.indirect_obj, \
                           q.loc, count(qa.article) as article_count \
                    FROM queries q \
                    LEFT JOIN query_articles qa on q.id = qa.query and qa.notification_sent = true \
                    GROUP BY(q.id);")
        return self.cursor.fetchall()

    def new_query(self, email, phone, subject, verb, direct_obj, indirect_obj, loc):
        """
        Add a query to the database for a user
        :param email: the user's email
        :param phone: the user's phone number
        :param subject: the query subject
        :param verb: the query verb
        :param direct_obj: the query direct object
        :param indirect_obj: the query indirect object
        :param loc: the query location
        :return: True if no error
        """
        self.cursor.execute("SELECT id from users where email = %s and phone = %s", (email, phone))
        # use existing user if it exists
        user_id = self.cursor.fetchone()
        if user_id:
            user_id = user_id[0]
        else:
            self.cursor.execute("INSERT INTO users (email, phone) VALUES (%s, %s) RETURNING id;", (email, phone))
            user_id = self.cursor.fetchone()[0]

        try:
            self.cursor.execute("INSERT INTO queries (subject, verb, direct_obj, indirect_obj, loc, userid) \
                            VALUES (%s, %s, %s, %s, %s, %s);", (subject, verb, direct_obj, indirect_obj, loc, user_id))
        except psycopg2.IntegrityError:
            return False
        return True

    def add_article_to_query_articles(self, article_id):
        self.cursor.execute("SELECT id FROM queries;")
        query_ids = self.cursor.fetchall()
        for query_id in query_ids:
            self.cursor.execute("INSERT INTO query_articles (query, article) VALUES (%s, %s) ON CONFLICT DO NOTHING", (query_id, article_id))
        # query | article | accuracy | processed

    def articles_route(self):
        """
        Gets all queries for web app with source name strings
        :return: the article titles, source names and URLs
        """
        self.cursor.execute("SELECT title, s.source_name as source, url FROM articles a \
                        INNER JOIN sources s on s.id = a.source;")
        return self.cursor.fetchall()
