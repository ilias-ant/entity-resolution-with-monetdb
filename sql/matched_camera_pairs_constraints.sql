ALTER TABLE matched_camera_pairs ADD PRIMARY KEY (left_camera_id, right_camera_id);
ALTER TABLE matched_camera_pairs ADD CONSTRAINT "fk_cameras_id_1" FOREIGN KEY (left_camera_id) REFERENCES cameras (id);
ALTER TABLE matched_camera_pairs ADD CONSTRAINT "fk_cameras_id_2" FOREIGN KEY (right_camera_id) REFERENCES cameras (id);
