import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from PythonValidators.Validator import KeywordValidator

if __name__ == "__main__":
    print(KeywordValidator().validate(int(sys.argv[1]), int(sys.argv[2])))
