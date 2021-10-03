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

-- extract brand from page title and assign each camera to a (brand) block accordingly
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
