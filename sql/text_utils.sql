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