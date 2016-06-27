import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from Clustering.MatrixCreator import *
from math import sqrt
class AbstractClusterer:
    """
    Abstact Clusterer: An interface for clusters, which cluster articles
    """
    def __init__(self):
        """
        obligatory init
        :return: nothing
        """
        pass

    def pre_cluster(self):
        """
        pre_cluster: creates matrix for clustering, gets article titles and ids
        :return: the matrix for clustering
        """
        # Cluster by article title words
        self.matrix_creator = MatrixCreator()

        #None if original matrix was empty
        matrix = self.matrix_creator.construct_matrix()
        self.article_titles = self.matrix_creator.get_article_titles()
        self.article_ids = self.matrix_creator.get_article_ids()

        return matrix

    def cluster(self):
        """
        Performs clustering on articles
        :return: a list of clusters
        """
        assert False
