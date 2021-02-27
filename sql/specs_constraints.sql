ALTER TABLE specs ADD CONSTRAINT "fk_cameras_id" FOREIGN KEY (camera_id) REFERENCES cameras (id);
ALTER TABLE specs ADD CONSTRAINT "specs_uc" UNIQUE (camera_id, name, value);
