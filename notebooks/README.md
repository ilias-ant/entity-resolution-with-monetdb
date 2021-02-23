The `notebooks/` directory hosts a number of Jupyter notebooks that
are used for R&D purposes. They are not part of the overall functionality, but a place where ideas are tested before 
migrated to the MonetDB instance as a proper utility.

You can interact with the Jupyter notebooks in your browser with:

```shell
python3 -m pip install poetry
```
and then:
```shell
poetry check
poetry install
poetry run jupyter notebook
```
