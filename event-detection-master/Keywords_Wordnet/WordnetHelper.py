import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from nltk.corpus import wordnet
from collections import defaultdict

def get_synonyms(word, pos):
	"""Gets a list of synonyms of a given word"""
	synonyms = set()
	pos = get_pos_tag_for_wordnet(pos)
	# loop over all synsets with correct part-of-speech
	for synset in wordnet.synsets(word, pos):
		for lemma in synset.lemmas():
			synonyms.add(lemma.name())
	return list(synonyms)


def get_hypernyms(word, pos):
	"""Gets a list of hypernyms of a given word (one level up)"""
	hypernyms = set()
	pos = get_pos_tag_for_wordnet(pos)
	# loop over all synsets with correct part-of-speech
	for synset in wordnet.synsets(word, pos):
		for hypernym in synset.hypernyms():
			for lemma in hypernym.lemmas():
				hypernyms.add(lemma.name())
	return list(hypernyms)


def get_synonym_list(tagged_sequence):
	"""Returns a dictionary of lists of synonyms for a tagged sequence of words"""
	results = defaultdict(dict)
	for word_tag in tagged_sequence:
		word = word_tag[0]
		tag = word_tag[1]
		results[word_tag[1]][word] = get_synonyms(word, tag)
	return results


def get_hypernym_list(tagged_sequence):
	"""Returns a dictionary of lists of hypernyms for a tagged sequence of words"""
	results = defaultdict(dict)
	for word_tag in tagged_sequence:
		word = word_tag[0]
		tag = word_tag[1]
		results[word_tag[1]][word] = get_hypernyms(word, tag)
	return results


def get_pos_tag_for_wordnet(tag):
	"""Returns the wordnet version of a part of speech tag if it exists"""
	if tag.startswith("NN"):
		return wordnet.NOUN
	elif tag.startswith("VB"):
		return wordnet.VERB
	elif tag.startswith("JJ"):
		return wordnet.ADJ
	elif tag.startswith("RB"):
		return wordnet.ADV
	else:
		return ""
