The `notebooks/` directory hosts Jupyter notebooks that
are used for testing stuff out. They are not part of the overall functionality, but a place where ideas are evaluated 
before migrated to the MonetDB-based implementation.

To interact with the available Jupyter notebook(s) in your browser:

```shell
python3 -m pip install poetry
```
and then:
```shell
poetry check
poetry install
```
You are now ready to:
```shell
poetry run jupyter notebook
```
