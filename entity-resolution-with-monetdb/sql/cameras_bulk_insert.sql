-- if the table cameras does not exist
CREATE TABLE cameras
FROM LOADER cameras_loader('data/2013_camera_specs');  -- should be the absolute path to the dir

-- if the table exists and you want to add new data
COPY LOADER INTO cameras
FROM cameras_loader('data/2013_camera_specs');  -- should be the absolute path to the dir
