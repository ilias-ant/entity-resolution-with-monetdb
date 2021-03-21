COPY 46665 OFFSET 2 RECORDS INTO labels
FROM 'data/sigmod_medium_labelled_dataset.csv'  -- should be the absolute path to the CSV file
USING DELIMITERS E',',E'\n';