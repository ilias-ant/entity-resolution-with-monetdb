-- just a proxy reference table to keep the matches from blocking & filtering
CREATE TABLE matched_cameras (
    "camera_id" VARCHAR(128) PRIMARY KEY,
    "signature" VARCHAR(256)
);

ALTER TABLE matched_cameras ADD CONSTRAINT "fk_matched_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);

-- just a proxy reference table to keep non-matches from blocking & filtering
CREATE TABLE unmatched_cameras (
    "camera_id" VARCHAR(128) PRIMARY KEY
);

ALTER TABLE unmatched_cameras ADD CONSTRAINT "fk_unmatched_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);
