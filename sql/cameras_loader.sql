CREATE LOADER cameras_loader(dirpath STRING)
LANGUAGE PYTHON {
    import json
    import os


    for subdir in os.listdir(dirpath):

        temp = os.path.join(dirpath, subdir)

        for datafile in os.listdir(temp):

            with open(os.path.join(temp, datafile), 'r') as f:

                data = json.loads(f.read())

            _emit.emit(
                {
                    'id': subdir + '//' + datafile.split('.json')[0],  # keep this as global identifier
                    'page_title': data['<page title>']   # we expect page title to be present in each new camera
                }
            )
};
