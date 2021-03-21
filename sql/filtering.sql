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

-- store the matches
INSERT INTO matched_cameras
WITH matches (camera_id, camera_brand, camera_model) AS (
SELECT cameras.id as camera_id,
       b.name as camera_brand,
       camera_model(fix_aliases(sanitize_text(to_lowercase(page_title)))) as camera_model
FROM cameras
INNER JOIN brands b ON cameras.brand_id = b.id
WHERE camera_model(fix_aliases(sanitize_text(to_lowercase(page_title)))) <> '')
SELECT camera_id, camera_brand  || '_' || camera_model from matches;  -- signature: brand + model

-- store all the rest here
INSERT INTO unmatched_cameras
SELECT cameras.id FROM cameras
WHERE NOT EXISTS (SELECT id FROM matched_cameras WHERE cameras.id = matched_cameras.camera_id);
