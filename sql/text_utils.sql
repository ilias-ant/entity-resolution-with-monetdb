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
        "fuijifilm": "fujifilm", "general": "ge", "gopros": "gopro", "hikvision3mp":"hikvision",
        "hikvisionip": "hikvision", "bell+howell": "howell", "howellwp7": "howell", "minotla": "minolta",
        "canon&nikon": "nikon", "olympuss": "olympus", "panosonic": "panasonic", "pentax": "ricoh",
        "ssamsung": "samsung", "repairsony": "sony", "elf": "elph", "s480016mp": "s4800", "vivicam": "v", "plus": "+",
        "1080p": "", "720p": "", "(not Provided)": ""
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