import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from PythonValidators.Validator import Query
from Utils.DataSource import *
import fcntl
import os, sys


class QueryProcessorDaemon:
    """
    class QueryArticleList -- processes queries to be used with the validator
    """
    def run(self):
        """
        add synonyms of new keywords into query_word table
        :return: Nothing
        """
        fd, fo = 0, 0
        try:
            if "--no-lock" not in sys.argv:
                fo = open(os.getenv("HOME") + "/.event-detection-active", "wb")
                fd = fo.fileno()
                fcntl.lockf(fd, fcntl.LOCK_EX)
            ds = DataSource()
            unprocessed_queries = ds.get_unprocessed_queries()
            for query in unprocessed_queries:
                # access into the queries SQL table and find which queries are not process
                THRESHOLD = None
                print(query)
                query_parts = {"query": " ".join(filter(None, query[1:6])), "subject": query[1], "verb": query[2],
                               "direct_obj": query[3], "indirect_obj": query[4], "location": query[5]}
                print(query_parts)
                synonyms = Query(query[0], query_parts, THRESHOLD).get_synonyms()
                print(synonyms)
                # synonyms = {NN: {word1: [list of synonym], word2: [list of synonym],...}, VB..}

                for pos_group in synonyms:
                    print(synonyms[pos_group])
                    for query_word in synonyms[pos_group]:
                        ds.insert_query_word_synonym(query[0], query_word, pos_group, synonyms[pos_group][query_word])

                ds.post_query_processor_update(query[0])
        finally:
            if "--no-lock" not in sys.argv:
                fcntl.lockf(fd, fcntl.LOCK_UN)
                fo.close()

if __name__ == "__main__":
    QueryProcessorDaemon().run()
