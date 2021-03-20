-- just a proxy table to keep the matches from blocking & filtering
CREATE TABLE matched_cameras (
    "camera_id" VARCHAR(128) PRIMARY KEY,
    "signature" VARCHAR(256)
);

ALTER TABLE matched_cameras ADD CONSTRAINT "fk_matched_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);

-- just a proxy table to keep non-matches from blocking & filtering
CREATE TABLE unmatched_cameras (
    "camera_id" VARCHAR(128) PRIMARY KEY,
    "signature" VARCHAR(256)
);

ALTER TABLE unmatched_cameras ADD CONSTRAINT "fk_unmatched_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);

-- store the matches
INSERT INTO matched_cameras
WITH matches (camera_id, camera_brand, camera_model) AS (
SELECT cameras.id,
       b.name as camera_brand,
       camera_model(sanitize_text(to_lowercase(page_title))) as camera_model
FROM cameras
INNER JOIN blocks b ON cameras.block_id = b.id
WHERE camera_model(sanitize_text(to_lowercase(page_title))) <> '')
SELECT camera_id, camera_brand  || '_' || camera_model from matches;

-- store all the rest here
INSERT INTO unmatched_cameras
SELECT cameras.id, null FROM cameras
WHERE NOT EXISTS (SELECT id FROM matched_cameras WHERE cameras.id = matched_cameras.camera_id);
