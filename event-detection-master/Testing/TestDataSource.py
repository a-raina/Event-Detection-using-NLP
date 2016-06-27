import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

import psycopg2
from psycopg2.extras import RealDictCursor
from Utils.Globals import *
from collections import defaultdict


class TestDataSource:
    """
    A class to get data for testing
    """
    def __init__(self, queries=None, articles=None):
        """
        Initializes a TesterDataSource
        :return: None
        """
        # grab the current database used in the JSON
        try:
            # connect to the database and set autocommit to true
            conn = psycopg2.connect(user="root", database="event_detection_test")
            conn.autocommit = True
        except psycopg2.Error:
            print("Error: cannot connect to event_detection_test database")
            sys.exit()
        try:
            self.cursor = conn.cursor(cursor_factory=RealDictCursor)
        except psycopg2.Error:
            print("Error: cannot create cursor")
            sys.exit()

        # initialize all instance variables to None
        self.query_articles = None
        self.articles = None
        self.queries = None
        self.results_by_algorithm = None
        self.algorithms = None
        self.validation_results = None
        self.validation_ratio = None
        self.articles = articles
        self.queries = queries
        self.algorithms = None
        self.results_by_algorithm = None

    def get_validation_ratio(self):
        """
        Gets the ratio of validated article/query pairs to all article/query pairs
        :return: the ratio
        """
        if self.validation_ratio is None:
            # get count of validated query articles
            self.cursor.execute("SELECT count(*) FROM query_articles where validates = true")
            # get count of all query articles
            validated = self.cursor.fetchone()
            self.cursor.execute("SELECT count(*) FROM query_articles")
            total = self.cursor.fetchone()
            self.validation_ratio = validated["count"] / total["count"]
        return self.validation_ratio

    def get_algorithms(self):
        """
        gets a list of algorithm ids
        :return: the list
        """
        if self.algorithms is None:
            self.cursor.execute("SELECT id, algorithm FROM validation_algorithms WHERE enabled = true")
            self.algorithms = self.cursor.fetchall()
        return self.algorithms

    def get_queries(self):
        """
        gets a list of query ids
        :return: the list
        """
        if self.queries is None:
            self.cursor.execute("SELECT id FROM queries WHERE enabled = true")
            queries = self.cursor.fetchall()
            self.queries = [query["id"] for query in queries]
        return self.queries

    def get_query_articles(self):
        """
        Gets a list of all query_articles and if the query validates the article
        Caches the list
        :return: the list of query articles
        """
        if self.query_articles is None:
            self.cursor.execute("SELECT query, article, validates FROM query_articles")
            query_articles_list = self.cursor.fetchall()
            self.query_articles = {(qa["query"], qa["article"]): qa["validates"] for qa in query_articles_list}
        return self.query_articles

    def get_articles(self):
        """
        Gets a list of article ids from the database
        :return: a list of article ids
        """
        if self.articles is None:
            # grab all article ids
            self.cursor.execute("SELECT id FROM articles")
            articles = self.cursor.fetchall()
            self.articles = [article["id"] for article in articles]
        return self.articles

    def get_validation_result(self, query_id, article_id, algorithm_id):
        """
        Gets the validation result for a specific query, article and algorithm
        :param query_id: the id of the query
        :param article_id: the id of the article
        :param algorithm_id: the id of the algorithm
        :return: the validation result for the given query id, article id and algorithm id
                 or None if no result found
        """
        # get results from database if we haven't already
        if self.validation_results is None:
            self.get_validation_results()

        # return the validation result if it has been recorded
        if (query_id, article_id, algorithm_id) in self.validation_results:
            return self.validation_results[(query_id, article_id, algorithm_id)]
        else:
            return None

    def get_validation_results(self):
        """
        Creates a dictionary of all validation results and caches it
        :return: the validation results
        """
        if self.validation_results is None:
            self.cursor.execute("SELECT * FROM validation_results")
            results = self.cursor.fetchall()
            # create dictionary with format (query_id, article_id, algorithm_id) -> validates probability
            self.validation_results = {(r["query"], r["article"], r["algorithm"]): r["validates"] for r in results}
        return self.validation_results

    def separate_algorithm_data(self):
        """
        separates out validation data by the algorithm used to validate
        :return: dictionary: {algorithm id: {(query id, article id) : validation value)}}
        """
        if self.results_by_algorithm is None:
            algorithm_datasets = defaultdict(dict)
            results = self.get_validation_results()
            for algorithm in self.get_algorithms():
                algorithm_id = algorithm["id"]
                for query_id in self.get_queries():
                    for article_id in self.get_articles():
                        if (query_id, article_id, algorithm_id) in results:
                            algorithm_datasets[algorithm_id][(query_id, article_id)] = results[(query_id, article_id, algorithm_id)]
                        else:
                            algorithm_datasets[algorithm_id][(query_id, article_id)] = 0
            self.results_by_algorithm = algorithm_datasets
        return self.results_by_algorithm

    def get_results_by_algorithms(self, algorithm_id):
        """
        Gets return validation data for a given algorithms
        :param algorithm_id: id of algorithm of interest
        :return: dictionary: {(query id, article id) : validation value)}
        """
        if self.results_by_algorithm is None:
            self.separate_algorithm_data()
        return self.results_by_algorithm[algorithm_id]

    def get_query_as_string(self, query_id):
        """
        Gets a string with query text for a given query
        :param query_id: the query's id
        :return: a string representing the query
        """
        self.cursor.execute("SELECT subject, verb, direct_obj, indirect_obj, loc FROM queries WHERE id = %s", (query_id, ))
        query = self.cursor.fetchone()
        return "{0} {1} {2} {3} {4}".format(query["subject"], query["verb"], query["direct_obj"], query["indirect_obj"], query["loc"])

    def get_article_title(self, article_id):
        """
        Gets the title for a given article
        :param article_id: the article's id
        :return: the title
        """
        self.cursor.execute("SELECT title FROM articles WHERE id = %s", (article_id, ))
        return self.cursor.fetchone()["title"]
