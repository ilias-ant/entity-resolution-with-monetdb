ALTER TABLE specs ADD PRIMARY KEY (id);
ALTER TABLE spec_matchings ADD CONSTRAINT "fk_specs_id_1" FOREIGN KEY (left_spec_id) REFERENCES specs (id);
ALTER TABLE spec_matchings ADD CONSTRAINT "fk_specs_id_2" FOREIGN KEY (right_spec_id) REFERENCES specs (id);