import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from Utils.DataSource import *
import json

class Cluster:
    ds = DataSource()

    def __init__(self, id):
        """
        Creates a cluster object
        :param id: cluster id from algorithm
        :return: None
        """
        self.id = id
        self.article_ids = []
        self.article_titles = []
        self.keywords = None

    def add_article(self, article_id, article_title):
        """
        Adds an article to the cluster
        :param article_id: article id
        :param article_title: article title
        :return: None
        """
        self.article_ids.append(article_id)
        self.article_titles.append(article_title)


    def is_valid_cluster(self, num_articles):
        """
        Checks if cluster is valid: meaning it contains more than one article,
        but fewer article than a quarter of all the articles considered
        :param num_articles: number of articles considered
        :return: true if valid cluster; else false
        """
        return num_articles / 4 > len(self.article_ids) > 1


    def get_keywords(self):
        """
        gets the cumulative list of keywords for the cluster
        :return: set of keywords
        """
        # don't build keywords dictionary if it has already been built
        if self.keywords is None:
            self.keywords = set()
            keyword_dicts = [json.loads(self.ds.get_article_keywords(article)[0])
                            for article in self.article_ids]
            for kw_dict in keyword_dicts:
                for pos in kw_dict:
                    for kw in kw_dict[pos]:
                        self.keywords.add(kw[0])
        return self.keywords

    def get_article_ids(self):
        """
        Returns the article ids associated with this cluster
        :return: list of articles ids
        """
        return self.article_ids
