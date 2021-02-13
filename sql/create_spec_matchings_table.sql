CREATE TABLE spec_matchings (left_spec_id text, right_spec_id text, label int);

COPY OFFSET 2 INTO spec_matchings 
FROM '../sigmod_medium_labelled_dataset.csv'
USING DELIMITERS ',';