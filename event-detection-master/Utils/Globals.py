import sys; import os
import re

sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

import json

"""
Holds global information, some of which may be changed at runtime
"""
articles_path = "./articles/"
database = "event_detection"

def overwriteSelf(*args):
    f = open(sys.argv[0], 'r+')
    text = f.read()
    for arg in args:
        text = re.sub(arg[0], arg[1], text, flags=re.MULTILINE)
    f.seek(0)
    f.write(text)
    f.truncate()
    f.close()

def main():
    """
    supply arg "test" for test setup
    default reuglar setup
    :return: None
    """
    myfile = open('configuration.json')
    json_object = json.loads(myfile.read())
    myfile.close()
    if len(sys.argv) == 1:
        articles = json_object["paths"]["articles"][0]
        if articles[-1] != "/":
            articles = articles + "/"
        overwriteSelf(*[["^(articles_path = ).*?$", r'\1' + '"' + articles + '"'],
            ["^(database = ).*?$", r'\1' + '"' + json_object["database"]["name"] + '"']])
    elif sys.argv[1] == "test":
        overwriteSelf(*[["^(articles_path = ).*?$", r'\1' + '"Testing/articles_test/"'],
            ["^(database = ).*?$", r'\1' + '"event_detection_test"']])

if __name__ == "__main__":
    main()