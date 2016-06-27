CREATE TYPE validator_type AS ENUM ('OneToOne', 'OneToMany', 'ManyToOne', 'ManyToMany', 'QueryOnly', 'ArticleOnly'); --This corresponds to ValidatorType in the Java code.

ALTER TABLE validation_algorithms ADD COLUMN base_class text not null default '';
ALTER TABLE validation_algorithms ADD COLUMN validator_type validator_type not null default 'OneToOne';
ALTER TABLE validation_algorithms ADD COLUMN threshold real not null default 0.50;
ALTER TABLE validation_algorithms ADD COLUMN parameters jsonb default null;
ALTER TABLE validation_algorithms ADD COLUMN enabled boolean not null default true;

ALTER TABLE validation_algorithms ADD CONSTRAINT unqiue_algorithm UNIQUE (algorithm);

INSERT INTO validation_algorithms (algorithm, base_class, validator_type, parameters) values
	('keyword', 'eventdetection.validator.implementations.KeywordValidator', 'OneToOne', '"KeywordValidator.json"'),
	('Swoogle Semantic Analysis', 'eventdetection.validator.implementations.SwoogleSemanticAnalysisValidator', 'OneToOne',
		'{"instance" : {"url-prefix" : "http://swoogle.umbc.edu/StsService/GetStsSim?operation=api", "max-sentences" : 5}}'),
	('SEMILAR Semantic Analysis', 'eventdetection.validator.implementations.SEMILARSemanticAnalysisValidator', 'OneToOne', '"SEMILARSemanticAnalysisValidator.json"'),
	('TextRank Swoogle Semantic Analysis', 'eventdetection.validator.implementations.TextRankSwoogleSemanticAnalysisValidator', 'OneToOne',
		'{"instance" : {"url-prefix" : "http://swoogle.umbc.edu/StsService/GetStsSim?operation=api"}}')
	ON CONFLICT (algorithm) DO UPDATE set (base_class, validator_type, parameters) = (EXCLUDED.base_class, EXCLUDED.validator_type, EXCLUDED.parameters);
ALTER TABLE validation_algorithms ALTER COLUMN base_class DROP DEFAULT;
