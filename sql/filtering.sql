-- approach A
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

INSERT INTO unmatched_camera_pairs
WITH inverse_index (camera_id, camera_brand, camera_model) AS (
    SELECT cameras.id, b.name, model(sanitize_text(to_lowercase(page_title)))
    FROM cameras
    INNER JOIN blocks b ON cameras.block_id = b.id
    WHERE model(sanitize_text(to_lowercase(page_title))) <> '')
SELECT left_index.camera_id, right_index.camera_id FROM inverse_index AS left_index
CROSS JOIN inverse_index AS right_index
WHERE NOT (left_index.camera_brand = right_index.camera_brand AND left_index.camera_model = right_index.camera_model)
AND left_index.camera_id < right_index.camera_id;  -- only on unique pairs

-- approach B
CREATE TEMP TABLE camera_pairs (
    left_camera_id VARCHAR(128), left_camera_brand VARCHAR(128), left_camera_model VARCHAR(128),
    right_camera_id VARCHAR(128),  right_camera_brand VARCHAR(128), right_camera_model VARCHAR(128)
) ON COMMIT PRESERVE RwhyOWS;

INSERT INTO tmp.camera_pairs
WITH inverse_index (camera_id, camera_brand, camera_model) AS (
    SELECT cameras.id, b.name, model(sanitize_text(to_lowercase(page_title)))
    FROM cameras
    INNER JOIN blocks b ON cameras.block_id = b.id
    WHERE model(sanitize_text(to_lowercase(page_title))) <> '')
SELECT * FROM inverse_index AS left_index
CROSS JOIN inverse_index AS right_index
WHERE left_index.camera_id < right_index.camera_id;

insert into matched_camera_pairs
select left_camera_id, right_camera_id
from tmp.camera_pairs
where left_camera_brand = right_camera_brand and left_camera_model = right_camera_model;

insert into unmatched_camera_pairs
select left_camera_id, right_camera_id
from tmp.camera_pairs
where not (left_camera_brand = right_camera_brand and left_camera_model = right_camera_model);
