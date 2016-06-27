# We use term extraction and clustering methods found in this paper http://nlg18.csie.ntu.edu.tw:8080/lwku/c12.pdf
import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from nltk import pos_tag, word_tokenize
from nltk.corpus import stopwords
from Keywords_Wordnet.KeywordExtractor import *
import re
from Utils.DataSource import *
from Keywords_Wordnet.WordnetHelper import *
import json
from nltk.stem.wordnet import WordNetLemmatizer
from nltk.stem.snowball import SnowballStemmer


class AbstractValidator:
  """
  Abstact Validator: An interface for validators, which validate queries with articles
  """
  def __init__(self):
      """
      obligatory init
      :return: nothing
      """
      pass

  def validate(self, query, article):
      """
      All validators must have a validate method
      :param Query: query to validate
      :param Article: article used for validation
      :return:
      """
      assert False


class KeywordValidator(AbstractValidator):
    """
    class KeywordValidator: Uses keywords from an article to validate a query
    """
    def __init__(self):
        """
        initializes query_article_lists, a list of list of articles defined around a query
        :return: nothing
        """
        self.query_article_lists = []
        self.lemmatizer = WordNetLemmatizer()

    def add_query(self, query):
        """
        add_query: adds query to queries to be validated, inits empty query_article_list
        :param query: query to add
        :return: nothing
        """
        query_article_list = QueryArticleList(query)
        self.query_article_lists.append(query_article_list)

    #TODO: WHAT DOES THIS DO
    def add_to_query_article_list(self, article):
        """
        adds to
        :param article: article to add to queries
        :return: list of queries article was added to
        """
        queries_added_to = []
        return queries_added_to

    def get_query_article_lists(self):
        """
        get_query_article_lists
        :return: self.query_article_lists: list of list of articles defined around a query
        """
        return self.query_article_lists

    def validate(self, query_id, article_id):
        """
        validate -- evaluates how much article validates query
        :param query: query to validate
        :param article: article to validate with
        :return: match_percentage (relative measure of how well article validates query)
        """
        max_match_value = 0
        # Need to process query and article formats
        ds = DataSource()
        query_synonyms_raw = ds.get_query_synonyms(query_id) # [('and', 'CC', 'Random', []), ('julia', 'NN', 'Random', []), ('phuong', 'JJ', 'Random', []), ('test', 'NN', 'Random', ['trial', 'run', 'mental_test', 'test', 'tryout', 'trial_run', 'exam', 'examination', 'mental_testing', 'psychometric_test']), ('validator', 'NN', 'Random', [])]
        query_synonyms = {}

        for w in query_synonyms_raw:
            query_synonyms[self.normalize_keyword(w[0])] = [self.normalize_keyword(synonym) for synonym in w[3]]
        article_keyword = json.loads(ds.get_article_keywords(article_id)[0]) #{NN: [list of keywords], VB:[list of verb keywords]}

        article_keywords_flat = set()
        for pos in article_keyword:
            for item in article_keyword[pos]:
                article_keywords_flat.add(self.normalize_keyword(item[0]))

        match_value = 0
        # find matches
        for query_word in query_synonyms:
            max_match_value += 2
            if query_word in article_keywords_flat:
                match_value += 2
            else:
                for synonym in query_synonyms[query_word]:
                    if synonym in article_keywords_flat:
                        match_value += 1
                        break
        match_percentage = 0 if max_match_value == 0 else (match_value / max_match_value)
        return match_percentage

    def normalize_keyword(self, word):
        lemma = self.lemmatizer.lemmatize(word.lower())
        stem = (SnowballStemmer("english").stem(lemma))
        return stem



class Source:
    """
    class Source -- source of an article
    """
    def __init__(self, id, name, reliability):
        """
        creates a source object
        :param id: number to uniquify source
        :param name: name of source, ex CNN
        :param reliability: how reliable a source is -- default is 1.0
        :return: nothing
        """
        self.id = id
        self.name = name
        self.reliability = reliability

    def get_ID(self):
        """
        :return: source id
        """
        return self.id

    def get_name(self):
        """
        :return: source name
        """
        return self.name

    def get_reliability(self):
        """
        :return: source reliability
        """
        return self.reliability

    def load_from_SQL(self, id):
        """
        loads source from database
        :param id: source id
        :return: source object
        """
        return



class Article:
    """
    Article class
    """
    def __init__(self, title, body, url, source):
        """
        creates an article object
        :param title: article title
        :param body: tagged article body title and text
        :param url: article url
        :param source: article source
        :return: nothing
        """

        pattern =  re.compile(r'TITLE:(.*)TEXT:(.*)', re.DOTALL)
        tagged_items = re.match(pattern, body)


        self.title_tagged = tagged_items.group(1)
        self.body_tagged = tagged_items.group(2)
        self.title = title
        self.url = url
        self.source = source

    def extract_keyword(self):
        """
        extracts keywords from text
        :return: keywords extracted
        """
        extractor = KeywordExtractor()
        self.keyword = extractor.extract_keywords(self)
        return self.keyword

    def get_keyword(self):
        """
        returns None if keywords not yet extracted
        :return: keywords
        """
        return self.keyword

    def is_linked_to(self, other_article):
        """
        determines if an article is linked to another article
        :param other_article: article to check against
        :return: True if semantically related
        """
        return False

    def get_title(self):
        """
        :return: article title
        """
        return self.title

class QueryElement:
    """
    Query element class -- A part of a query and its role, synonyms, and words in hierarchies
    ex. Beyonce as the subject
    """
    def __init__(self, role, word):
        """
        creates a QueryElement object
        :param role: role of element, ex. Subject
        :param word: word itself, ex Beyonce
        :return: nothing
        """
        self.role = role
        self.word = word
        self.synonyms = self.get_synonyms()
        self.hierarchies = self.get_hierarchies()

    def get_synonyms(self):
        """
        :return: synonyms of query element
        """
        return []

    def get_hierarchies(self):
        """
        :return: words in query element's hierarchy, ex America is a hierarchy for Ohio
        """
        return []


class Query:
    """
    Query class -- for the query a user submits
    """


    def __init__(self, id, query_parts, threshold):
        """
        creates a query object
        :param id: query id from database
        :param query_parts: parts of query -- subject, verb, etc.
        :param threshold: how well an article must match query to validate it
        :return: nothing
        """
        self.threshold = threshold
        self.id = id
        self.subject = QueryElement("subject", query_parts["subject"])
        self.verb = QueryElement("verb", query_parts["verb"])
        self.direct_obj = QueryElement("direct_obj", query_parts["direct_obj"])
        self.indirect_obj = QueryElement("indirect_obj", query_parts["indirect_obj"])
        self.location = QueryElement("location", query_parts["location"])
        self.query = query_parts["query"]

        stoplist_file  = open(KeywordExtractor.stoplist_file)
        self.stop_list = set(stoplist_file.readlines())
        stoplist_file.close()

        self.query_tagged = self.tag_query() # [('Beyonce', 'NN'), ('releases', 'NNS'), ('song', 'NN')]
        self.synonyms_with_tag = {} # {'NNS': {'releases': []}, 'NN': {'Beyonce': [], 'song': []}}
        self.generate_synonyms_with_tag()

    def get_id(self):
        """
        :return: query id
        """
        return self.id

    def tag_query(self):
        """
        part of speech tags a query
        :return: the tagged form of the query
        """
        return pos_tag(word_tokenize(self.query))

    def generate_synonyms_with_tag(self):
        """
        generates synonyms for each word in the query, using only synonyms with same part of speech
        :return:
        """
        for tagged_word in self.query_tagged:
            if tagged_word[0].lower() not in self.stop_list:      # tagged_word[0] = word
                if tagged_word[1] not in self.synonyms_with_tag:  # tagged_word[1] = tag
                    self.synonyms_with_tag[tagged_word[1]] = {}
                self.synonyms_with_tag[tagged_word[1]][tagged_word[0]] = get_synonyms(tagged_word[0],tagged_word[1])
                # TODO actually get synonyms
        print(self.synonyms_with_tag)
    def get_synonyms(self):
        """
        :return: synonyms with their tags of the words in the query
        """
        return self.synonyms_with_tag

    def get_threshold(self):
        """
        :return: query's threshold -- how well an article must match query to validate it
        """
        return self.threshold

    def get_elements(self):
        """
        :return: elements of query: subject, verb, direct object, indirect object, location
        (only subject and verb are guaranteed to not be None)
        """
        return self.subject, self.verb, self.direct_obj, self.indirect_obj, self.location

class QueryArticleList:
    """
    class QueryArticleList -- a query, and a list of articles defined around it
    """
    def __init__(self, query):
        """
        inits an article list around a query
        :param query: the query to add articles to a list for
        :return: nothing
        """
        self.query = query
        self.articles = []

    def add_article(self, article):
        """
        adds an article to a query article list
        :param article: article to add
        :return: Nothing
        """
        self.articles.append(article)

    def get_num_articles(self):
        """
        gets number of articles in query article list
        :return: number of articles in query article list
        """
        return len(self.articles)
