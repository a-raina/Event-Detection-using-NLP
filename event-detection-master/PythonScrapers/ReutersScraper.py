import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from bs4 import BeautifulSoup
import sys
import urllib.request
import json

def read():
    """
    Reads the main content from a Reuters page
    """
    json_text = ""
    with sys.stdin as fileIn:
        for line in fileIn:
            json_text = json_text + line
    json_obj = json.loads(json_text)
    page = urllib.request.urlopen(json_obj["url"])
    soup = BeautifulSoup(page, "html.parser")
    text = soup.find(id = "articleText")
    print("\n".join(text.strings))

def main():
    read()

if __name__ == "__main__":
    main()
