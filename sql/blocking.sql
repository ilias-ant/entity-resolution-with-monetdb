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
