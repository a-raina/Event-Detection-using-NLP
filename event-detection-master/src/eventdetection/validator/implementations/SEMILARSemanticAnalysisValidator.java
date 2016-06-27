package eventdetection.validator.implementations;

import semilar.config.ConfigManager;
import semilar.data.Sentence;
import semilar.sentencemetrics.LexicalOverlapComparer;
import semilar.sentencemetrics.OptimumComparer;
import semilar.tools.preprocessing.SentencePreprocessor;
import semilar.tools.semantic.WordNetSimilarity;
import semilar.sentencemetrics.PairwiseComparer.NormalizeType;
import semilar.sentencemetrics.PairwiseComparer.WordWeightType;
import semilar.wordmetrics.LSAWordMetric;
import semilar.wordmetrics.WNWordMetric;

import edu.sussex.nlp.jws.*;
import edu.stanford.nlp.pipeline.StanfordCoreNLP;
import edu.stanford.nlp.ling.CoreAnnotations.*;
import edu.stanford.nlp.semgraph.SemanticGraph;
import edu.stanford.nlp.semgraph.SemanticGraphCoreAnnotations.CollapsedCCProcessedDependenciesAnnotation;
import edu.stanford.nlp.ling.*;
import edu.stanford.nlp.pipeline.Annotation;
import edu.stanford.nlp.util.CoreMap;

import eventdetection.common.Article;
import eventdetection.common.POSTagger;
import eventdetection.common.Query;
import eventdetection.common.Source;
import eventdetection.validator.ValidationResult;
import eventdetection.validator.ValidatorController;
import eventdetection.validator.types.OneToOneValidator;
import eventdetection.validator.types.Validator;
import eventdetection.common.ArticleManager;
import eventdetection.common.DBConnection;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Set;
import java.util.HashMap;
import java.util.HashSet;
import java.text.*;
import java.util.Properties;

import toberumono.json.JSONArray;
import toberumono.json.JSONObject;
import toberumono.json.JSONSystem;
import toberumono.json.JSONNumber;
import toberumono.structures.collections.lists.SortedList;
import toberumono.structures.tuples.Pair;
import toberumono.structures.SortingMethods;

/**
 * A SEMILAR validator using prebuilt library from http://deeptutor2.memphis.edu/
 * With some post-run modification
 *
 * @author Anmol Raina, Phuong Dinh and Julia Kroll
 */
public class SEMILARSemanticAnalysisValidator extends OneToOneValidator {
    
    // Various thresholds and constants for post processing
    // Test the following variables:
    private double HIGH_VALIDATION_THRESHOLD = 10; //THRESHOLD to accept validation return P = 1.0
                                                    // The max score depending on the HIGH_MATCH_SCORE, MEDIUM_MATCH_SCORE, TITLE_MULTIPLIER...
                                                    // 10 might be plenty for high HIGH_MATCH_SCORE, MEDIUM_MATCH_SCORE, TITLE_MULTIPLIER...
                                                    // but too low for low HIGH_MATCH_SCORE, MEDIUM_MATCH_SCORE, TITLE_MULTIPLIER...
                                                    // Sorrym but these variables are correlate
    private double MEDIUM_VALIDATION_THRESHOLD = 0.0; // Considering zone P ranging 0.0 to 0.9
    private double FIRST_ROUND_CONTENT_THRESHOLD = 0.10;
    private double FIRST_ROUND_TITLE_THRESHOLD = 0.15;
    private double TITLE_MULTIPLIER = 2;
    private double PRONOUN_SCORE = 0.5;
    private double HIGH_MATCH_SCORE = 4;
    private double MEDIUM_MATCH_SCORE = 2;
    private double LOW_MATCH_SCORE = 1;
    private double MIN_WORD_TO_WORD_THRESHOLD = 0.70;
    private double RELIABLE_TITLE_THRESHOLD = 0.4;

    // Number of most validated sentences per articles that we look at for post processing
    private int MAX_SENTENCES = 10;
    
    private static Pattern STOPWORD_RELN_REGEX = Pattern.compile("det|mark|cc|aux|punct|auxpass|cop|expl|goeswith|dep");
    private static Pattern USEFUL_RELN_REGEX = Pattern.compile("nmod|dobj|iobj|nsubj|nsubjpass|appos|conj|xcomp|ccomp");
    private static Pattern PRONOUN_REGEX = Pattern.compile("WP|WDT|PRP|WP\\$");
        // WP = wh-pronoun, WDT = wh-determiner, PRP = personal pronoun, WP$ = possessive wh-pronoun

    OptimumComparer optimumComparerWNLin;
    
    WNWordMetric wnMetricLin;
    SentencePreprocessor preprocessor;
    
	/**
	 * Constructs a new instance of the {@link Validator} for the given {@code ID}, {@link Query}, and {@link Article}
	 * @param config the configuration data
	 */
    public SEMILARSemanticAnalysisValidator(JSONObject config) {
        // Instantiating the thresholds with values from a JSON file
        HIGH_VALIDATION_THRESHOLD = ((JSONNumber<?>) config.get("HIGH_VALIDATION_THRESHOLD")).value().doubleValue();
        MEDIUM_VALIDATION_THRESHOLD = ((JSONNumber<?>) config.get("MEDIUM_VALIDATION_THRESHOLD")).value().doubleValue();
        FIRST_ROUND_CONTENT_THRESHOLD = ((JSONNumber<?>) config.get("FIRST_ROUND_CONTENT_THRESHOLD")).value().doubleValue();
        FIRST_ROUND_TITLE_THRESHOLD = ((JSONNumber<?>) config.get("FIRST_ROUND_TITLE_THRESHOLD")).value().doubleValue();
        TITLE_MULTIPLIER = ((JSONNumber<?>) config.get("TITLE_MULTIPLIER")).value().doubleValue();
        PRONOUN_SCORE = ((JSONNumber<?>) config.get("PRONOUN_SCORE")).value().doubleValue();
        HIGH_MATCH_SCORE = ((JSONNumber<?>) config.get("HIGH_MATCH_SCORE")).value().doubleValue();
        MEDIUM_MATCH_SCORE = ((JSONNumber<?>) config.get("MEDIUM_MATCH_SCORE")).value().doubleValue();
        LOW_MATCH_SCORE = ((JSONNumber<?>) config.get("LOW_MATCH_SCORE")).value().doubleValue();
        MIN_WORD_TO_WORD_THRESHOLD = ((JSONNumber<?>) config.get("MIN_WORD_TO_WORD_THRESHOLD")).value().doubleValue();
        RELIABLE_TITLE_THRESHOLD = ((JSONNumber<?>) config.get("RELIABLE_TITLE_THRESHOLD")).value().doubleValue();
        
        // Initializing an instance of the wnMetricLin algorithm 
        // wnMetricLin is a word-word comparison algorithm. Returns a double in range [0,1], where a higher number signifies higher similarity
        wnMetricLin = new WNWordMetric(WordNetSimilarity.WNSimMeasure.LIN, false);
        
        // optimumComparerWNLin is a sentence-sentence comparison algorithm. Returns a double in range [0,1], where a higher number signifies higher similarity
        optimumComparerWNLin = new OptimumComparer(wnMetricLin, 0.3f, false, WordWeightType.NONE, NormalizeType.AVERAGE);
        
        // another possible algorithm for word-word comparison
        //wnMetricWup = new WNWordMetric(WordNetSimilarity.WNSimMeasure.WUP, false);

        preprocessor = new SentencePreprocessor(SentencePreprocessor.TokenizerType.STANFORD, SentencePreprocessor.TaggerType.STANFORD, SentencePreprocessor.StemmerType.PORTER, SentencePreprocessor.ParserType.STANFORD);

    }


    /**
    * Compares query with every sentence in a given article. We store the number of sentences specified by MAX_SENTENCES and compute the average         * score of the top 5 sentences. If the average score of the article sentences or title passes the given thresholds, call the post processing         * function to further validate the articles.
    * @param query
    * @param article
    * @return validation score for the article
    */
	@Override
	public ValidationResult[] call(Query query, Article article) throws IOException {

        Sentence querySentence;
        Sentence articleSentence;
        
        SortedList<Pair<Double, CoreMap>> topN = new SortedList<>((a, b) -> b.getX().compareTo(a.getX()));
        
        StringBuilder phrase1 = new StringBuilder();
		phrase1.append(query.getSubject()).append(" ").append(query.getVerb());
		if (query.getDirectObject() != null && query.getDirectObject().length() > 0)
			phrase1.append(" ").append(query.getDirectObject());
		if (query.getIndirectObject() != null && query.getIndirectObject().length() > 0)
			phrase1.append(" ").append(query.getIndirectObject());
        if (query.getLocation() != null && query.getLocation().length() > 0)
			phrase1.append(" ").append(query.getLocation());       

        querySentence = preprocessor.preprocessSentence(phrase1.toString());
        
        Double tempScore;

        String title = article.getAnnotatedTitle().toString();
        Sentence articleTitle = preprocessor.preprocessSentence(title);
        Double tempTitle = (double) optimumComparerWNLin.computeSimilarity(querySentence, articleTitle);

        // Go through each sentence in the given article and compare it to the query. Store the number of articles specified by 
        // MAX_SENTENCES and their scores in a list
        for (Annotation paragraph : article.getAnnotatedText()) {
			List<CoreMap> sentences = paragraph.get(SentencesAnnotation.class);
			for (CoreMap sentence : sentences) {
                String sen = POSTagger.reconstructSentence(sentence);
                articleSentence = preprocessor.preprocessSentence(sen);
                tempScore = (double) optimumComparerWNLin.computeSimilarity(querySentence, articleSentence);
                if (tempScore.equals(Double.NaN))
                    continue;
                topN.add(new Pair<>(tempScore, sentence));
                if (topN.size() > MAX_SENTENCES)
                    topN.remove(topN.size() - 1);
            }
        }

        // Average of top 5 similar sentences
        double average = 0.0;
        int count = 0;
		for (Pair<Double, CoreMap> p : topN){
            count += 1;
            if (count > 5) {
                break;
            }
			average += p.getX();
        }
        average /= (double) count; 
        
        double validation = 0.0;
        if (average > FIRST_ROUND_CONTENT_THRESHOLD || tempTitle > FIRST_ROUND_TITLE_THRESHOLD) {
            validation = postProcess(topN, query,phrase1.toString(), title, tempTitle);
        }

        return new ValidationResult[]{new ValidationResult(article.getID(), validation)};
    }
    

    /* 
    * Post-process validation using semantic dependencies to compare a query's parts (subject, verb, object, location) to parts of 
    * article sentences and score their semantic and syntactic similarity.
    * @param topN Ordered(by descending) list of N highest matching sentences in an article
    * @param query
    * @param rawQuery
    * @param articleTitle
    * @param titleScore Score for the title based on it's similarity to the query
    * @return article's validation score
    */
    public double postProcess(SortedList<Pair<Double, CoreMap>> topN, Query query, String rawQuery, String articleTitle, double titleScore){

        // Gets query parts and tracks which parts are present (out of subject, verb, object, location)
        String subject, dirObject, indirObject, location;
        HashSet<String> userQueryParts = new HashSet<String>(); // because subject and verbs are compulsory
        userQueryParts.add("SUBJECT");
        userQueryParts.add("VERB");
        subject = query.getSubject();
        dirObject = "";
        indirObject = "";
        location = "";
        if (query.getDirectObject() != null && query.getDirectObject().length() > 0) {
            dirObject = query.getDirectObject();
            userQueryParts.add("OBJECT");
        }
        if (query.getIndirectObject() != null && query.getIndirectObject().length() > 0) {
            indirObject = query.getIndirectObject();
            userQueryParts.add("OBJECT");
        }
        // TODO problematic that we are counting direct object and indirect object as the same "OBJECT" in queryParts --
        // so later in postprocessing, if both exist in the query but only one matches, then we're thinking the sentence is better than it really is
        if (query.getLocation() != null && query.getLocation().length() > 0) {
            location = query.getLocation();
            userQueryParts.add("LOCATION");
        }

 
        HashMap<String, String> keywordNouns = new HashMap<String, String>();
        Annotation taggedQuery = POSTagger.annotate(rawQuery);

        // Store all query nouns in keywordNouns
        for (CoreLabel token: taggedQuery.get(TokensAnnotation.class)){
                String pos = token.get(PartOfSpeechAnnotation.class);
                if (pos.length() > 1 && pos.substring(0,2).equals("NN")){ // All noun tags start with NN
                    if (subject.contains(token.get(LemmaAnnotation.class))){
                        keywordNouns.put(token.get(LemmaAnnotation.class), "SUBJECT");
                    }
                    if (dirObject.contains(token.get(LemmaAnnotation.class))){
                        keywordNouns.put(token.get(LemmaAnnotation.class), "OBJECT");
                    }
                    if (indirObject.contains(token.get(LemmaAnnotation.class))){
                        keywordNouns.put(token.get(LemmaAnnotation.class), "OBJECT"); //We will treat DirObj and IndirObj the same
                    }
                }
            }

        HashSet<String> dependencyMatches = new HashSet<String>();
        HashSet<String> svolMatches = new HashSet<String>();
        HashMap<HashSet<String>, Integer> svolMatchCombinations = new HashMap<HashSet<String>, Integer>();
        double totalScore = 0;

        // ARTICLE CONTENT SCORE
        // For each sentence, find which query parts match the sentence
        // Aggregate across the article's top sentences to count how many of each SVOL (sentence/verb/object/location) combination appears.
        for (Pair<Double, CoreMap> p : topN){
            dependencyMatches = validationScore(query, p.getY(), keywordNouns);
            for (String matchPart : dependencyMatches) {
                if (!svolMatches.contains(matchPart)) {
                    svolMatches.add(matchPart);
                }
            }
            if (!svolMatchCombinations.containsKey(dependencyMatches)) {
                svolMatchCombinations.put(dependencyMatches, 1);
            }
            else {
                svolMatchCombinations.put(dependencyMatches, svolMatchCombinations.get(dependencyMatches) + 1);
            }
        }

        // Use counts of SVOL matches to calculate an article's sentences score
        for (HashSet<String> combi : svolMatchCombinations.keySet()) {
            int count = svolMatchCombinations.get(combi); 
            totalScore = totalScore + calcSentenceScore(combi, count, svolMatches, userQueryParts);
        }    

        Annotation annotatedTitle = POSTagger.annotate(articleTitle);
        CoreMap taggedTitle = annotatedTitle.get(SentencesAnnotation.class).get(0);
        
        // TITLE SCORE
        dependencyMatches = validationScore(query, taggedTitle, keywordNouns);
       
        double creditToSEMILARTitleScore = 0.0;
        if (titleScore > RELIABLE_TITLE_THRESHOLD) { // if post-processing title score is unreliably high, lower it
            creditToSEMILARTitleScore = TITLE_MULTIPLIER * MEDIUM_MATCH_SCORE;
        }
        totalScore += Math.max(creditToSEMILARTitleScore, calcSentenceScore(dependencyMatches, 1, svolMatches, userQueryParts) * TITLE_MULTIPLIER);

        // Decide how likely it is that an article validates the query [0,1]
        // and return the final validation score
        if (totalScore > HIGH_VALIDATION_THRESHOLD){
            return 1.0;
        } else if (totalScore > MEDIUM_VALIDATION_THRESHOLD) {
            return totalScore/HIGH_VALIDATION_THRESHOLD;
        }
        return 0.0;
    }

    /*
     * Calculates how well a sentence matches a query using its combination of SVOL matches.
     * @param combi Query parts matched in this sentence
     * @param count Number of times the SVOL combination appears in the entire article
     * @param svolMatches Query parts matched in entire article 
     * @param userQueryParts
     * @return sentence's validation score
     */ 
    public double calcSentenceScore(HashSet<String> combi, int count, HashSet<String> svolMatches, HashSet<String> userQueryParts){
        double totalScore = 0.0;
        
        // Check the sentence's pronouns -- if a subject or object pronoun was matched, and the subject or object exists in
        // another sentence, the pronoun increases the sentence's validation score. This score increase is only half of what
        // true subject and object matches receive.
        if (combi.contains("S_PRONOUN")) {
            if (svolMatches.contains("SUBJECT")) {
                totalScore += PRONOUN_SCORE; 
            }
            combi.remove("S_PRONOUN");
        }
        if (combi.contains("O_PRONOUN")) {
            if (svolMatches.contains("OBJECT")) {
                totalScore += PRONOUN_SCORE; 
            }
            combi.remove("O_PRONOUN");
        }
        
        // Calculate the sentence's score without pronouns
        // If the sentence matches 4/4 or 3/3 query parts, it earns a high match score.
        if ((userQueryParts.size() == 4 && combi.size() == 4) || (userQueryParts.size() == 3 && combi.size() == 3)) {
            totalScore += HIGH_MATCH_SCORE;
        } 
        // Else if the sentence matches 3/4, 2/3, or 2/2 query parts, it earns a medium match score.
        else if ((userQueryParts.size() == 4 && combi.size() == 3) || (userQueryParts.size() == 3 && combi.size() == 2) 
            || (userQueryParts.size() == 2 && combi.size() == 2)) {
            totalScore += MEDIUM_MATCH_SCORE;
        } 
        // Else if the sentence matches 2/4 query parts, or 1/2 query parts with the other part matching elsewhere in the article, 
        // it earns a low match score.
        else if ((userQueryParts.size() == 4 && combi.size() == 2) || (userQueryParts.size() == 2 && combi.size() == 1 && svolMatches.size() == 2)) {
            totalScore += LOW_MATCH_SCORE;
        }
        return totalScore * count; // TODO is multiplying by count double-counting unintentionally???
    }

    /* 
     * Find which parts of the query the sentence matches, including pronouns.
     * @param query
     * @param sentence
     * @param keywordNouns
     * @return Set containing strings of a sentence's matching query parts, including subject and object pronouns 
     */
    public HashSet<String> validationScore(Query query, CoreMap sentence, HashMap<String, String> keywordNouns){
        int matchedPerSentence = 0;
        
        // matchedTokens contains {SVO string: set of words that match that SVO}
        HashMap<String, HashSet<CoreLabel>> matchedTokens = new HashMap<String, HashSet<CoreLabel>>();
        
        // For each word in sentence, if the word is a noun, see if it matches a noun in the query (using lemmatization)
        // Store matched nouns from the sentence
        for (CoreLabel token: sentence.get(TokensAnnotation.class)){
            String pos = token.get(PartOfSpeechAnnotation.class);
            String lemma = token.get(LemmaAnnotation.class);

            if (pos.length() > 1 && pos.substring(0,2).equals("NN")){ // All noun tags start with NN
                for (String imptNoun:keywordNouns.keySet()){
                    double matchScore = 0.0;
                    matchScore = wnMetricLin.computeWordSimilarityNoPos(lemma.toLowerCase(), imptNoun.toLowerCase());
                    // TO DO: Adding stemmer would improve string comparison
                    if (lemma.toLowerCase().equals(imptNoun.toLowerCase())) { // for proper nouns and unknown words (eg mosque)
                        matchScore = 1;
                    }
                    if (matchScore > MIN_WORD_TO_WORD_THRESHOLD){
                        matchedPerSentence += 1;
                        if (!matchedTokens.containsKey(keywordNouns.get(imptNoun))) {
                            HashSet<CoreLabel> newTokenSet = new HashSet<CoreLabel>();
                            matchedTokens.put(keywordNouns.get(imptNoun), newTokenSet);
                        }
                        matchedTokens.get(keywordNouns.get(imptNoun)).add(token);
                    }           
                }
            }
        }
        if (matchedPerSentence > 0) {
            if (matchedTokens.containsKey("SUBJECT")) {
                return matchSVO(query, sentence, matchedTokens, "SUBJECT");
            }else if (matchedTokens.containsKey("OBJECT")) {
                return matchSVO(query, sentence, matchedTokens, "OBJECT");
            }
        }       
        return new HashSet<String>(); //String could only be SUBJECT, VERB, OBJECT, S_PRONOUN, O_PRONOUN, LOCATION
    }


    /* 
     * Given the query nouns found in a sentence, use semantic dependencies to find other related verbs and nouns 
     * and determine which query parts match the sentence.
     * @param query
     * @param sentence
     * @param matchedTokens
     * @param tokenType
     * @return set of matching query parts, including pronouns
     */
    public HashSet<String> matchSVO(Query query, CoreMap sentence, HashMap<String, HashSet<CoreLabel>> matchedTokens, String tokenType) {
        SemanticGraph dependencies = sentence.get(CollapsedCCProcessedDependenciesAnnotation.class);
        String verb = query.getVerb();// TODO .get(LemmaAnnotation.class);
        HashSet<String> dependencyMatches = new HashSet<String>(); // will add SUBJECT, VERB, OBJECT, S_PRONOUN, O_PRONOUN, LOCATION
        for (CoreLabel token : matchedTokens.get(tokenType)) { 
            if (PRONOUN_REGEX.matcher(token.tag()).find()) {
                if (tokenType.equals("SUBJECT")) {
                    dependencyMatches.add("S_PRONOUN");
                }
                else if (tokenType.equals("OBJECT")) {
                    dependencyMatches.add("O_PRONOUN");
                }
            }
            else { // for nouns that are not pronouns
                dependencyMatches.add(tokenType);
            }
            
            // From the semantic graph, get all verbs which have the given noun as a dependency
            List<IndexedWord> verbNodes = getVerbNodes(token, dependencies);

            // For each verb found, see if the verb matches the query verb
            for (IndexedWord verbNode : verbNodes){
                // TODO: Not only verb to verb, but also verb to adj (e.g) die == was dead
                if (verbNode != null) {
                    if (wnMetricLin.computeWordSimilarityNoPos(verbNode.lemma(), verb) > MIN_WORD_TO_WORD_THRESHOLD) {
                        dependencyMatches.add("VERB");
                    }
                    if (!dependencyMatches.contains("OBJECT") && matchedTokens.containsKey("OBJECT")){
                        dependencyMatches = recursiveSearchKeyword(verbNode, dependencies, tokenType, dependencyMatches, matchedTokens);
                    }
                }
            }
        }
        
        // If the query specifies a location, search for the location as a string inside the sentence using regular expressions,
        // ignoring "in", "on," "at" preceding the location if the user has entered them.
        String queryLocation = "";
        if (query.getLocation() != null && query.getLocation().length() > 0) {    
            queryLocation = query.getLocation();
            if (queryLocation.length() > 3) {
	            String potentialPrep = queryLocation.substring(0,3);
	            if (potentialPrep.equals("in ") || potentialPrep.equals("on ") || potentialPrep.equals("at ")){
	                queryLocation = queryLocation.substring(3);
	            }
	        }
        }    
        Pattern isLocationMatch = Pattern.compile("(^|[\\-\"' \t])" + queryLocation + "[$\\.!?\\-,;\"' \t]");
        if (!queryLocation.equals("") && isLocationMatch.matcher(sentence.toString()).find()) {
            dependencyMatches.add("LOCATION");
        }

        // If the sentence contains O_PRONOUN & OBJECT or S_PRONOUN & SUBJECT, remove the pronoun
        if (dependencyMatches.contains("O_PRONOUN") && dependencyMatches.contains("OBJECT")){
            dependencyMatches.remove("O_PRONOUN");
        }
        if (dependencyMatches.contains("S_PRONOUN") && dependencyMatches.contains("SUBJECT")){
            dependencyMatches.remove("S_PRONOUN");
        }
        return dependencyMatches;
    } 

    /* 
     * Given a node in a dependency tree, recursively search the node's descendents to find nouns in the sentence that match query nouns.
     * @param headNode
     * @param dependencies SemanticGraph of dependencies for sentence
     * @param tokenType subject or object
     * @param dependencyMatches matched query parts
     * @param matchedTokens matched nouns
     * @return a hash set of the type of query parts matched (subject pronoun, object pronoun, object)
     */
    public HashSet<String> recursiveSearchKeyword(IndexedWord headNode, SemanticGraph dependencies, String tokenType, HashSet<String> dependencyMatches, HashMap<String, HashSet<CoreLabel>> matchedTokens){

        // Look at a given head node's children to see if they match query nouns
        for (IndexedWord childNode : dependencies.getChildren(headNode)) {
            if (!STOPWORD_RELN_REGEX.matcher(dependencies.reln(headNode, childNode).getShortName()).find()){
                if (tokenType.equals("SUBJECT")) {
                    if (PRONOUN_REGEX.matcher(childNode.tag()).find()) {
                        dependencyMatches.add("O_PRONOUN");
                    }
                    else {
                        for (CoreLabel objectToken : matchedTokens.get("OBJECT")) { 

                            if (wnMetricLin.computeWordSimilarityNoPos(childNode.lemma(), objectToken.get(LemmaAnnotation.class)) > MIN_WORD_TO_WORD_THRESHOLD
                                || childNode.lemma().toLowerCase().equals(objectToken.get(LemmaAnnotation.class).toLowerCase())) {
                                dependencyMatches.add("OBJECT");
                                break;
                            } else {
                                if (USEFUL_RELN_REGEX.matcher(dependencies.reln(headNode, childNode).getShortName()).find()){
                                    dependencyMatches = recursiveSearchKeyword(childNode, dependencies, tokenType, dependencyMatches, matchedTokens);
                                }
                            }
                        }
                    }
                } else if (tokenType.equals("OBJECT")) {
                    if (PRONOUN_REGEX.matcher(childNode.tag()).find()) {
                        dependencyMatches.add("S_PRONOUN");
                    }                           
                }
            }
        }
        return dependencyMatches;
    }

    /* 
     * Search ancestors of a given node to find the nearest verb
     * @param token node in sentence dependency graph
     * @param dependencies SemanticGraph of dependencies for sentence 
     * @return a list of verbs related to a given noun
     */
    public List<IndexedWord> getVerbNodes(CoreLabel token, SemanticGraph dependencies) {

        List<IndexedWord> nounNodes = dependencies.getAllNodesByWordPattern(token.toString().split("-")[0]);
        List<IndexedWord> verbNodes = new ArrayList<IndexedWord>();
        for (IndexedWord nounNode : nounNodes) {
            IndexedWord parent = dependencies.getParent(nounNode);
            // Keep getting the next highest ancestor until a verb (tag starting with "V") is found
            while (parent != null && dependencies.getParent(parent) != null && !parent.tag().substring(0,1).equals("V")) {
                if (parent == dependencies.getParent(parent)){
                    break;
                }
                parent = dependencies.getParent(parent);
            }
            verbNodes.add(parent);
        }
        return verbNodes;
    }
}
