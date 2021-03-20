ALTER TABLE cameras ADD COLUMN brand_id INTEGER;
ALTER TABLE cameras ADD CONSTRAINT "fk_brand_id" FOREIGN KEY (brand_id) REFERENCES brands (id);