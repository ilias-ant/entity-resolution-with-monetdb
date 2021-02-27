CREATE LOADER specs_loader(dirpath STRING)
LANGUAGE PYTHON {
    import json
    import os


    def parse(data):

        data.pop('<page title>', None)

        for key, value in data.items():

            if isinstance(value, list):

                for element in set(value):  # de-duplicate
                    yield key, element

            else:
                yield key, value


    for subdir in os.listdir(dirpath):

        temp = os.path.join(dirpath, subdir)

        for datafile in os.listdir(temp):

            # the reference to the cameras relation
            camera_id = subdir + '//' + datafile.split('.json')[0]

            with open(os.path.join(temp, datafile), 'r') as f:

                content = json.loads(f.read())

            for spec_name, spec_value in parse(content):

                _emit.emit({'camera_id': camera_id, 'name': spec_name, 'value': spec_value})
};