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

CREATE OR REPLACE FUNCTION brand(text STRING)
RETURNS STRING
LANGUAGE PYTHON_MAP {

    brands = [
        "aiptek", "apple", "argus", "benq", "canon", "casio", "coleman", "contour", "dahua", "epson", "fujifilm",
        "garmin", "ge", "gopro", "hasselblad", "hikvision", "howell", "hp", "intova", "jvc", "kodak", "leica", "lg",
        "lowepro", "lytro", "minolta", "minox", "motorola", "mustek", "nikon", "olympus", "panasonic", "pentax",
        "philips", "polaroid", "ricoh", "sakar", "samsung", "sanyo", "sekonic", "sigma", "sony", "tamron", "toshiba",
        "vivitar", "vtech", "wespro", "yourdeal"
    ]

    def retrieve_brand(txt):

        retrieved_brands = [brand for brand in brands if brand in txt]

        return max(retrieved_brands, key=len) if retrieved_brands else ''

    return numpy.array([retrieve_brand(title) for title in text], dtype=numpy.object)
};

CREATE OR REPLACE FUNCTION model(text STRING)
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

        return max(models, key=len) if models else ''

    return numpy.array([retrieve_model(title) for title in text], dtype=numpy.object)
};

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

-- BLOCKING ---------------------------------------------------------------------------------------------------------

UPDATE cameras
SET block_id = extraction.block_id
FROM (
    WITH camera (id, extracted_brand)
    AS (SELECT id, brand(fix_aliases(sanitize_text(to_lowercase(page_title)))) from cameras)
    SELECT camera.id AS camera_id, camera.extracted_brand, blocks.id AS block_id FROM camera
    INNER JOIN blocks ON camera.extracted_brand = blocks.name
    ) AS extraction
WHERE cameras.id = extraction.camera_id;

-- FILTERING --------------------------------------------------------------------------------------------------------

CREATE TABLE matched_camera_pairs (
    "left_camera_id" VARCHAR(128),
    "right_camera_id" VARCHAR(128)
);

ALTER TABLE matched_camera_pairs ADD PRIMARY KEY (left_camera_id, right_camera_id);
ALTER TABLE matched_camera_pairs ADD CONSTRAINT "fk_mcp_cameras_id_1" FOREIGN KEY (left_camera_id) REFERENCES cameras (id);
ALTER TABLE matched_camera_pairs ADD CONSTRAINT "fk_mcp_cameras_id_2" FOREIGN KEY (right_camera_id) REFERENCES cameras (id);

INSERT INTO matched_camera_pairs
WITH inverse_index (camera_id, camera_brand, camera_model) AS (
    SELECT cameras.id, b.name, model(sanitize_text(to_lowercase(page_title)))
    FROM cameras
    INNER JOIN blocks b ON cameras.block_id = b.id
    WHERE model(sanitize_text(to_lowercase(page_title))) <> '')
SELECT left_index.camera_id, right_index.camera_id FROM inverse_index AS left_index
CROSS JOIN inverse_index AS right_index
WHERE left_index.camera_brand = right_index.camera_brand AND left_index.camera_model = right_index.camera_model
AND left_index.camera_id < right_index.camera_id;  -- only on unique pairs
