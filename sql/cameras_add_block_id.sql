ALTER TABLE cameras ADD COLUMN block_id INTEGER;
ALTER TABLE cameras ADD CONSTRAINT "fk_block_id" FOREIGN KEY (block_id) REFERENCES blocks (id);