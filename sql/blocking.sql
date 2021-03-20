-- extract brand from page title and assign each camera to a (brand) block accordingly
UPDATE cameras
SET brand_id = extraction.brand_id
FROM (
    WITH camera (id, extracted_brand)
    AS (SELECT id, camera_brand(fix_aliases(sanitize_text(to_lowercase(page_title)))) from cameras)
    SELECT camera.id AS camera_id, camera.extracted_brand, brands.id AS brand_id FROM camera
    INNER JOIN brands ON camera.extracted_brand = brands.name
    ) AS extraction
WHERE cameras.id = extraction.camera_id;
