CREATE LOADER json_loader(dirpath STRING) 
LANGUAGE PYTHON {
    import json
    import os


    def prepare_json(data):

        for key, value in data.items():

            if isinstance(value, list):
                # concatenate multiple values into one
                data[key] = ' '.join(value)
        
        return data
    
    for subdir in os.listdir(dirpath):

        temp = os.path.join(dirpath, subdir)

        for datafile in os.listdir(temp):

            with open(os.path.join(temp, datafile), 'r') as f:

                data = json.loads(f.read())
            
            # keep global identifier it, format it as in labelled dataset
            data['id'] = subdir + '//' + datafile.split('.json')[0]

            _emit.emit(prepare_json(data))

};
