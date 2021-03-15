-- extract brand from page title and assign each camera to a block accordingly
UPDATE cameras
SET block_id = extraction.block_id
FROM (
    WITH camera (id, extracted_brand)
    AS (SELECT id, brand(fix_aliases(sanitize_text(to_lowercase(page_title)))) from cameras)
    SELECT camera.id AS camera_id, camera.extracted_brand, blocks.id AS block_id FROM camera
    INNER JOIN blocks ON camera.extracted_brand = blocks.name
    ) AS extraction
WHERE cameras.id = extraction.camera_id;
