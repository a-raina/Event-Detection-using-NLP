import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from numpy import zeros
from Utils.DataSource import *
import nltk.corpus
from Keywords_Wordnet.KeywordExtractor import *
import re
from collections import Counter
from sklearn.feature_extraction.text import TfidfTransformer
import io
from Utils.Globals import *


class MatrixCreator:

    def __init__(self):
        """
        Initialize class variables
        :return: None
        """
        self.ds = DataSource()
        self.ids = []
        self.num_entries = 0
        self.num_articles = 0
        self.num_article_words = 0
        self.article_titles = []
        self.stopwords = set(nltk.corpus.stopwords.words('english'))
        self.lemmatizer = WordNetLemmatizer()


    def get_num_entries(self):
        """
        Gets the number of non-zero entries in the matrix.
        :return: number of non-zero entries in the matrix
        """
        return self.num_entries

    def get_num_articles(self):
        """
        Gets the number of articles, which is the number of rows in the matrix
        :return: number of articles
        """
        return self.num_articles


    def get_num_article_words(self):
        """
        Gets the number of unique words across all documents
        :return: number of unique words across all documents
        """
        return self.num_article_words

    def get_article_titles(self):
        """
        Gets ordered list of article titles corresponding to
        article ids in self.ids
        :return: list of article titles
        """
        return self.article_titles

    def get_article_ids(self):
        """
        Gets article ids
        :return: list of article ids
        """
        return self.ids

    def retrieve_article_ids_titles_filenames(self):
        """
        Retrieves article ids, titles, and filenames from database
        and sets class variables
        :return: None
        """
        articles = self.ds.get_article_ids_titles_filenames()
        self.ids = []
        self.article_titles = []
        self.filenames = []
        for article in articles:
            if os.path.isfile(articles_path + article[2]):
                self.ids.append(article[0])
                self.article_titles.append(article[1])
                self.filenames.append(article[2])
        self.num_articles = len(self.article_titles)

    def get_article_text_by_article(self):
        """
        Gets list of sets of words by article, along with set of keywords
        across all articles
        :return: Set of words used in all articles
        """
        pattern = re.compile(r'TITLE:(.*)TEXT:(.*)', re.DOTALL)

        self.article_words_by_article = []
        all_article_words_set = set()

        for idx, filename in enumerate(self.filenames):
            article_file = open(articles_path + filename, "r", encoding="utf8")
            body = article_file.read()
            article_file.close()
            tagged_items = re.match(pattern, body)
            title_tagged = tagged_items.group(1)
            body_tagged = tagged_items.group(2)

            extractor = KeywordExtractor()
            title_text, _ = extractor.preprocess_keywords(title_tagged)
            body_text, _ = extractor.preprocess_keywords(body_tagged)
            body_text.extend(title_text)

            body_text = [Counter(sentence.strip().split()) for sentence in body_text]
            body_text_counter = Counter()
            for sentence in body_text:
                body_text_counter.update(sentence)
                all_article_words_set.update(sentence.keys())

            self.article_words_by_article.append(body_text_counter)
        self.num_article_words = len(all_article_words_set)
        return all_article_words_set

    def construct_matrix(self):
        """
        Constructs an articles by words numpy array and populates it
        with tfidf values for each article-word cell.
        :return: tfidf matrix, or None if matrix empty (usually occurs when no articles found for some reason,
        (for example, if working directory is not root directory)
        """

        # Initialize article ids and titles
        self.retrieve_article_ids_titles_filenames()

        # Get keywords to construct matrix
        all_article_words_list = list(self.get_article_text_by_article())
        matrix = zeros((self.num_articles, self.num_article_words))
        num_entries = 0
        for article_word_idx, article_word in enumerate(all_article_words_list):
            for article_idx, article_id in enumerate(self.ids):
                if article_word in self.article_words_by_article[article_idx]:
                    matrix[article_idx, article_word_idx] += self.article_words_by_article[article_idx][article_word]
                    num_entries += 1
        self.num_entries = num_entries # Count num entries to calculate K

        #if matrix is empty, we cannot use it
        if matrix.shape == (0, 0):
            return None
        transformer = TfidfTransformer()
        tfidf_matrix = transformer.fit_transform(matrix).toarray()
        return tfidf_matrix

def main():
    mc = MatrixCreator()
    mc.construct_matrix()

if __name__ == "__main__":
    main()
