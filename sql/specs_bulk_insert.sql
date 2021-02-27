-- if the table cameras does not exist
CREATE TABLE specs
FROM LOADER specs_loader('data/2013_camera_specs');  -- should be the absolute path to the dir

-- if the table exists and you want to add new data
COPY LOADER INTO specs
FROM specs_loader('data/2013_camera_specs');  -- should be the absolute path to the dir
