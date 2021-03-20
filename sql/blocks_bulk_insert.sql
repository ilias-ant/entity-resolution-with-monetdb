-- this is an initial closed set of brands, which will help us perform blocking
-- this list can be later expanded, according to our needs and our approach of the cold-start problem:
-- how our ML-based application will handle newly seen camera brands on the market ? we will ignore this aspect for now.

INSERT INTO blocks (name)
VALUES ('aiptek'), ('apple'), ('argus'), ('benq'), ('canon'), ('casio'), ('coleman'), ('contour'), ('dahua'),
       ('epson'), ('fujifilm'), ('garmin'), ('ge'), ('gopro'), ('hasselblad'), ('hikvision'), ('howell'), ('hp'),
       ('intova'), ('jvc'), ('kodak'), ('leica'), ('lg'), ('lowepro'), ('lytro'), ('minolta'), ('minox'), ('motorola'),
       ('mustek'), ('nikon'), ('olympus'), ('panasonic'), ('pentax'), ('philips'), ('polaroid'), ('ricoh'), ('sakar'),
       ('samsung'), ('sanyo'), ('sekonic'), ('sigma'), ('sony'), ('tamron'), ('toshiba'), ('vivitar'), ('vtech'),
       ('wespro'), ('yourdeal');