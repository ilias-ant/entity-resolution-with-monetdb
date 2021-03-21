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
