-- this script contains all the statements needed to perform the task, from schema creation till the very end
-- all you have to do is replace the absolute paths to the datafiles where necessary
-- note: each separate component/action is also available for study under the sql/ directory

------------------------------------------------------------------------------------------------------------------
-- DATA LOADING --------------------------------------------------------------------------------------------------
-- load all the available data in the database and create a schema

CREATE OR REPLACE LOADER cameras_loader(dirpath STRING)
LANGUAGE PYTHON {
    import json
    import os


    for subdir in os.listdir(dirpath):

        temp = os.path.join(dirpath, subdir)

        for datafile in os.listdir(temp):

            with open(os.path.join(temp, datafile), 'r') as f:

                data = json.loads(f.read())

            _emit.emit(
                {
                    'id': subdir + '//' + datafile.split('.json')[0],  # keep this as global identifier
                    'page_title': data['<page title>']   # we expect page title to be present in each new camera
                }
            )
};

CREATE OR REPLACE LOADER specs_loader(dirpath STRING)
LANGUAGE PYTHON {
    import json
    import os


    def parse(data):

        data.pop('<page title>', None)

        for key, value in data.items():

            if isinstance(value, list):

                for element in set(value):  # de-duplicate
                    yield key, element

            else:
                yield key, value


    for subdir in os.listdir(dirpath):

        temp = os.path.join(dirpath, subdir)

        for datafile in os.listdir(temp):

            # the reference to the cameras relation
            camera_id = subdir + '//' + datafile.split('.json')[0]

            with open(os.path.join(temp, datafile), 'r') as f:

                content = json.loads(f.read())

            for spec_name, spec_value in parse(content):

                _emit.emit({'camera_id': camera_id, 'name': spec_name, 'value': spec_value})
};

CREATE TABLE cameras
FROM LOADER cameras_loader('/home/iantonopoulos/projects/entity-resolution-with-monetdb/data/2013_camera_specs');

ALTER TABLE cameras ADD PRIMARY KEY (id);

CREATE TABLE specs
FROM LOADER specs_loader('/home/iantonopoulos/projects/entity-resolution-with-monetdb/data/2013_camera_specs');

ALTER TABLE specs ADD CONSTRAINT "fk_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);
ALTER TABLE specs ADD CONSTRAINT "specs_uc" UNIQUE (camera_id, name, value);

CREATE TABLE labels (
    "left_camera_id" VARCHAR(128),
    "right_camera_id" VARCHAR(128),
    "same_product" BOOLEAN
);

COPY 46665 OFFSET 2 RECORDS INTO labels
FROM '/home/iantonopoulos/projects/entity-resolution-with-monetdb/data/sigmod_medium_labelled_dataset.csv'
USING DELIMITERS E',',E'\n';

ALTER TABLE labels ADD PRIMARY KEY (left_camera_id, right_camera_id);
ALTER TABLE labels ADD CONSTRAINT "fk_cameras_id_1" FOREIGN KEY (left_camera_id) REFERENCES cameras (id);
ALTER TABLE labels ADD CONSTRAINT "fk_cameras_id_2" FOREIGN KEY (right_camera_id) REFERENCES cameras (id);


---------------------------------------------------------------------------------------------------------------------
-- TEXT UTILS -------------------------------------------------------------------------------------------------------
-- create various text processing utils

CREATE OR REPLACE FUNCTION to_lowercase(text STRING)
RETURNS STRING
LANGUAGE PYTHON_MAP {
    return numpy.array([title.lower() for title in text], dtype=numpy.object)
};

CREATE OR REPLACE FUNCTION sanitize_text(text STRING)
RETURNS STRING
LANGUAGE PYTHON_MAP {

    def depunctuate(txt):

        for ch in [",", ":", ";", "!", "?", "(", ")", "[", "]", "{", "}", "/", "|", '"', "*"]:
            if ch in txt:
                txt = txt.replace(ch, " ")

        return txt.replace("-", "")

    return numpy.array([depunctuate(title) for title in text], dtype=numpy.object)
};

CREATE OR REPLACE FUNCTION fix_aliases(text STRING)
RETURNS STRING
LANGUAGE PYTHON_MAP {

    aliases = {
        "cannon": "canon", "canonpowershot": "canon", "eos": "canon", "used canon": "canon", "fugi": "fujifilm",
        "fugifilm": "fujifilm", "fuji": "fujifilm", "fujufilm": "fujifilm", "fijifilm": "fujifilm",
        "fuijifilm": "fujifilm", "general": "ge", "gopros": "gopro", "go pro": "gopro", "hikvision3mp":"hikvision",
        "hikvisionip": "hikvision", "bell+howell": "howell", "howellwp7": "howell", "minotla": "minolta",
        "canon&nikon": "nikon", "olympuss": "olympus", "panosonic": "panasonic", "pentax": "ricoh",
        "ssamsung": "samsung", "repairsony": "sony", "elf": "elph", "s480016mp": "s4800", "vivicam": "v", "plus": "+",
        "1080p": "", "720p": "", "t3i": "600d", "kodax": "kodak", "nixon": "nikon"
    }

    def replace_aliases(txt):

        for alias, correction in aliases.items():
            if alias in txt:
                txt = txt.replace(alias, correction)

        return txt

    return numpy.array([replace_aliases(title) for title in text], dtype=numpy.object)
};


---------------------------------------------------------------------------------------------------------------------
-- BLOCKING ---------------------------------------------------------------------------------------------------------
-- perform blocking on cameras via extracted brand


CREATE TABLE brands (
    "id" SERIAL,
    "name" VARCHAR(128) NOT NULL UNIQUE
);

ALTER TABLE cameras ADD COLUMN brand_id INTEGER;
ALTER TABLE cameras ADD CONSTRAINT "fk_brand_id" FOREIGN KEY (brand_id) REFERENCES brands (id);

INSERT INTO brands (name)
VALUES ('aiptek'), ('apple'), ('argus'), ('benq'), ('canon'), ('casio'), ('coleman'), ('contour'), ('dahua'),
       ('epson'), ('fujifilm'), ('garmin'), ('ge'), ('gopro'), ('hasselblad'), ('hikvision'), ('howell'), ('hp'),
       ('intova'), ('jvc'), ('kodak'), ('leica'), ('lg'), ('lowepro'), ('lytro'), ('minolta'), ('minox'), ('motorola'),
       ('mustek'), ('nikon'), ('olympus'), ('panasonic'), ('pentax'), ('philips'), ('polaroid'), ('ricoh'), ('sakar'),
       ('samsung'), ('sanyo'), ('sekonic'), ('sigma'), ('sony'), ('tamron'), ('toshiba'), ('vivitar'), ('vtech'),
       ('wespro'), ('yourdeal');

-- extracts the camera brand from text, based on a close-set of brands
CREATE OR REPLACE FUNCTION camera_brand(text STRING, brands STRING)
RETURNS STRING
LANGUAGE PYTHON_MAP {
    import re


    def adjust_short_brand(b):

        return b if len(b) > 2 else " {} ".format(b)

    # create a matcher based on brands input
    matcher = re.compile(r'|'.join(adjust_short_brand(b) for b in brands[0].split(',')))


    def retrieve_brand(txt):

        match = matcher.search(txt)

        return match.group().strip() if match else ''

    return numpy.array([retrieve_brand(title) for title in text], dtype=numpy.object)
};

UPDATE cameras
SET brand_id = extraction.brand_id   -- assign to block
FROM (
    WITH processed_camera (id, extracted_brand) AS (
        SELECT
        id, camera_brand(fix_aliases(sanitize_text(to_lowercase(page_title))), (SELECT listagg(name) FROM brands))
        FROM cameras
    )
    SELECT processed_camera.id AS camera_id, processed_camera.extracted_brand, b.id AS brand_id
    FROM processed_camera
    INNER JOIN brands b ON processed_camera.extracted_brand = b.name
) AS extraction
WHERE cameras.id = extraction.camera_id;


---------------------------------------------------------------------------------------------------------------------
-- FILTERING --------------------------------------------------------------------------------------------------------
-- perform filtering within blocks, based on extracted model, and thus create matched and unmatched clusters

ALTER TABLE cameras ADD COLUMN signature VARCHAR(128);

-- extracts the camera model from text, based on heuristics
CREATE OR REPLACE FUNCTION camera_model(text STRING)
RETURNS STRING
LANGUAGE PYTHON_MAP {
    import re


    measurement_units = [
        "cm", "mm", "nm", "inch", "gb", "mb", "mp", "megapixel", "megapixels", "mega", "ghz", "hz", "mah", "cmos", "mps"
    ]


    def model_contains_measurement_units(m):

        contains = False
        for unit in measurement_units:

            if m.endswith(unit):
                contains = True

        return contains


    def adjusted_model(m, txt):

        if m in ['1d', '5d', '7d', '1ds']:  # canon models heurisric

            if ' mark iv ' in txt:
                m = '{}_{}'.format(m, 'mark4')
            elif ' mark iii ' in txt:
                m = '{}_{}'.format(m, 'mark3')
            elif ' mark ii ' in txt:
                m = '{}_{}'.format(m, 'mark2')
            elif ' mark i ' in txt:
                m = '{}_{}'.format(m, 'mark1')

        return m


    def retrieve_model(txt):

        models = re.findall(r'[a-z]{1,2}\d+\s|\d+[a-z]{1,2}\s', txt, flags=re.IGNORECASE)

        models = [model for model in models if not model_contains_measurement_units(model.strip())]

        # position-wise, leftmost extracted model is likelier to be the model
        return adjusted_model(models[0].strip(), txt) if models else ''

    return numpy.array([retrieve_model(title) for title in text], dtype=numpy.object)
};

-- store the signatures
UPDATE cameras
SET signature = (
WITH matches (camera_id, camera_brand, camera_model) AS (
SELECT cameras.id as camera_id,
       b.name as camera_brand,
       camera_model(fix_aliases(sanitize_text(to_lowercase(page_title)))) as camera_model
FROM cameras
INNER JOIN brands b ON cameras.brand_id = b.id
WHERE camera_model(fix_aliases(sanitize_text(to_lowercase(page_title)))) <> '')
SELECT camera_brand  || '_' || camera_model FROM matches WHERE matches.camera_id = cameras.id);

---------------------------------------------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------------------------------------------
-- perform matching within blocks, on the unmatched products (aka those without an extracted signature)
