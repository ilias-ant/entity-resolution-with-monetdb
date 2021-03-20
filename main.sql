-- this script contains all the statements needed to perform the task, from schema creation till the very end
-- each separate component is also available for study under the sql/ directory
-- all you have to do is replace the absolute paths to the datafiles where necessary

-- DATA LOADING --------------------------------------------------------------------------------------------------

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
USING DELIMITERS ',';

ALTER TABLE labels ADD PRIMARY KEY (left_camera_id, right_camera_id);
ALTER TABLE labels ADD CONSTRAINT "fk_cameras_id_1" FOREIGN KEY (left_camera_id) REFERENCES cameras (id);
ALTER TABLE labels ADD CONSTRAINT "fk_cameras_id_2" FOREIGN KEY (right_camera_id) REFERENCES cameras (id);

-- BLOCKING ---------------------------------------------------------------------------------------------------------

CREATE TABLE blocks (
    "id" SERIAL,
    "name" VARCHAR(128) NOT NULL UNIQUE
);

ALTER TABLE cameras ADD COLUMN block_id INTEGER;
ALTER TABLE cameras ADD CONSTRAINT "fk_block_id" FOREIGN KEY (block_id) REFERENCES blocks (id);

INSERT INTO blocks (name)
VALUES ('aiptek'), ('apple'), ('argus'), ('benq'), ('canon'), ('casio'), ('coleman'), ('contour'), ('dahua'),
       ('epson'), ('fujifilm'), ('garmin'), ('ge'), ('gopro'), ('hasselblad'), ('hikvision'), ('howell'), ('hp'),
       ('intova'), ('jvc'), ('kodak'), ('leica'), ('lg'), ('lowepro'), ('lytro'), ('minolta'), ('minox'), ('motorola'),
       ('mustek'), ('nikon'), ('olympus'), ('panasonic'), ('pentax'), ('philips'), ('polaroid'), ('ricoh'), ('sakar'),
       ('samsung'), ('sanyo'), ('sekonic'), ('sigma'), ('sony'), ('tamron'), ('toshiba'), ('vivitar'), ('vtech'),
       ('wespro'), ('yourdeal');

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
        "fugifilm": "fujifilm", "fuji": "fujifilm", "fujufilm": "fujifilm", "general": "ge", "gopros": "gopro",
        "hikvision3mp":"hikvision", "hikvisionip": "hikvision", "bell+howell": "howell", "howellwp7": "howell",
        "minotla": "minolta", "canon&nikon": "nikon", "olympuss": "olympus", "panosonic": "panasonic",
        "pentax": "ricoh", "ssamsung": "samsung", "repairsony": "sony", "elf": "elph", "s480016mp": "s4800",
        "vivicam": "v", "plus": "+", "1080p": "", "720p": "", "(not Provided)": ""
    }

    def replace_aliases(txt):

        for alias, correction in aliases.items():
            if alias in txt:
                txt = txt.replace(alias, correction)

        return txt

    return numpy.array([replace_aliases(title) for title in text], dtype=numpy.object)
};

CREATE OR REPLACE FUNCTION camera_brand(text STRING)
RETURNS STRING
LANGUAGE PYTHON_MAP {
    import re


    matcher = re.compile(r'|'.join([
        "aiptek", "apple", "argus", "benq", "canon", "casio", "coleman", "contour", "dahua", "epson", "fujifilm",
        "garmin", "ge", "gopro", "hasselblad", "hikvision", "howell", "hp", "intova", "jvc", "kodak", "leica", "lg",
        "lowepro", "lytro", "minolta", "minox", "motorola", "mustek", "nikon", "olympus", "panasonic", "pentax",
        "philips", "polaroid", "ricoh", "sakar", "samsung", "sanyo", "sekonic", "sigma", "sony", "tamron", "toshiba",
        "vivitar", "vtech", "wespro", "yourdeal"
    ]))


    def retrieve_brand(txt):

        match = matcher.search(txt)

        return match.group() if match else ''

    return numpy.array([retrieve_brand(title) for title in text], dtype=numpy.object)
};

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


    def retrieve_model(txt):

        models = re.findall(r'[a-z]{1,2}\d+\s|\d+[a-z]{1,2}\s', txt, flags=re.IGNORECASE)

        models = [model.strip() for model in models if not model_contains_measurement_units(model.strip())]

        # position-wise, leftmost extracted model is likelier to be the model
        return models[0] if models else ''

    return numpy.array([retrieve_model(title) for title in text], dtype=numpy.object)
};

UPDATE cameras
SET block_id = extraction.block_id
FROM (
    WITH camera (id, extracted_brand)
    AS (SELECT id, camera_brand(fix_aliases(sanitize_text(to_lowercase(page_title)))) from cameras)
    SELECT camera.id AS camera_id, camera.extracted_brand, blocks.id AS block_id FROM camera
    INNER JOIN blocks ON camera.extracted_brand = blocks.name
    ) AS extraction
WHERE cameras.id = extraction.camera_id;

-- FILTERING --------------------------------------------------------------------------------------------------------

CREATE TABLE matched_cameras (
    "camera_id" VARCHAR(128) PRIMARY KEY,
    "signature" VARCHAR(256)
);

ALTER TABLE matched_cameras ADD CONSTRAINT "fk_matched_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);

CREATE TABLE unmatched_cameras (
    "camera_id" VARCHAR(128) PRIMARY KEY,
    "signature" VARCHAR(256)
);

ALTER TABLE unmatched_cameras ADD CONSTRAINT "fk_unmatched_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);

INSERT INTO matched_cameras
WITH matches (camera_id, camera_brand, camera_model) AS (
SELECT cameras.id,
       b.name as camera_brand,
       camera_model(sanitize_text(to_lowercase(page_title))) as camera_model
FROM cameras
INNER JOIN blocks b ON cameras.block_id = b.id
WHERE camera_model(sanitize_text(to_lowercase(page_title))) <> '')
SELECT camera_id, camera_brand  || '_' || camera_model from matches;

INSERT INTO unmatched_cameras
SELECT cameras.id, null FROM cameras
WHERE NOT EXISTS (SELECT id FROM matched_cameras WHERE cameras.id = matched_cameras.camera_id);
