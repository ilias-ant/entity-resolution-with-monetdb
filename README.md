# entity-resolution-with-monetdb
A proof-of-concept entity resolution task, with [Tensorflow](https://github.com/tensorflow/tensorflow), inside a [MonetDB](https://www.monetdb.org/Home) instance.

## Task Details

The task consists of identifying which product specifications (in short, specs) from multiple e-commerce websites represent the same real-world product.

You are provided with a dataset including ~30k specs in JSON format, each spec containing a list of (attribute_name, attribute_value) pairs extracted from a different web page, collected across 24 different web sources. We will refer to this dataset as dataset X.

Each spec is stored as a file, and files are organized into directories, each directory corresponding to a different web source (e.g., www.alibaba.com).
All specs refer to cameras and include information about the camera model (e.g. Canon EOS 5D Mark II) and, possibly, accessories (e.g. lens kit, bag, tripod). Accessories do not contribute to product identification: for instance, a Canon EOS 5D Mark II that is sold as a bundle with a bag represents the same core product as a Canon EOS 5D Mark II that is sold alone.

For a more detailed view of the task, the datasets, the evaluation process, refer to the official [task page](http://www.inf.uniroma3.it/db/sigmod2020contest/task.html) of SIGMOD 2020.

## Requirements

- Debian-based distribution (tested against Ubuntu 18.04.5 and 20.04.1)
- MonetDB with embedded Python3 support (tested against v11.39.11)

## MonetDB

```shell
apt install monetdb-python3
apt install monetdb-client

monetdbd create ecommercedbfarm

monetdbd start ecommercedbfarm

monetdb create ecommercedb

monetdb set embedpy3=true ecommercedb

monetdb release ecommercedb

mclient -u monetdb -d ecommercedb

# run statement sql/json_loader.sql

# run statement sql/create_specs_table.sql

# run statement sql/create_spec_matchings_table.sql

# run statement sql/create_constraint.sql
```


## References

- [IDEL: In-Database Entity Linking with Neural Embeddings](https://arxiv.org/abs/1803.04884)
