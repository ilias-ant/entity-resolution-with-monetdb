# Entity Resolution with MonetDB
**In-Database Machine Learning**

A proof-of-concept approach on an entity resolution task, with [Tensorflow](https://github.com/tensorflow/tensorflow) 
for the machine learning part and **everything** happening inside a [MonetDB](https://www.monetdb.org/Home) instance. 

In other words, a MonetDB database instance that performs machine learning and de-duplicates products that are 
essentially the same, in its own right.

## Task Details

The task consists of identifying which product specifications (in short, specs) from multiple e-commerce websites 
represent the same real-world product.

You are provided with a dataset including ~30k specs in JSON format, each spec containing a list of (attribute_name, 
attribute_value) pairs extracted from a different web page, collected across 24 different web sources.

Each spec is stored as a file, and files are organized into directories, each directory corresponding to a different
web source (e.g., *www.alibaba.com*).
All specs refer to cameras and include information about the camera model (e.g. *Canon EOS 5D Mark II*) and, possibly, 
accessories (e.g. *lens kit, bag, tripod*). Accessories do not contribute to product identification: for instance, a 
*Canon EOS 5D Mark II* that is sold as a bundle with a bag represents the same core product as a *Canon EOS 5D Mark II* 
that is sold alone.

For a more detailed view of the task, the datasets, the evaluation process, refer to the official 
[task page](http://www.inf.uniroma3.it/db/sigmod2020contest/task.html) of SIGMOD 2020.

## System Dependencies

- Debian-based distribution (tested against [Ubuntu 18.04.5](https://releases.ubuntu.com/18.04/))
- MonetDB with embedded Python3 support (tested against [v11.39.11](https://www.monetdb.org/Downloads/ReleaseNotes))

## MonetDB setup

The [official documentation procedure](https://www.monetdb.org/downloads/deb/) should be followed, in order 
for your deb-based distribution to be able to install the MonetDB via the ``apt`` package manager.

To be precise, everything up until the ``sudo apt update`` command is sufficient. From there on, we will diverge a bit in order 
to get a MonetDB installation with embedded Python3 support, with the
following commands:  

```shell
# root permission may be needed here 
apt install monetdb-python3
apt install monetdb-client

# create a db farm
monetdbd create ecommercedbfarm
monetdbd start ecommercedbfarm

# create a database, with python3 support activated
monetdb create ecommercedb
monetdb set embedpy3=true ecommercedb
monetdb release ecommercedb
```

## Loading the Data

All the necessary SQL statements (UDFs etc.) are available in the ``sql/`` directory, with each independent component 
hosted in a separate ``.sql`` file.

```shell
mclient -u monetdb -d ecommercedb  # password is the default (<monetdb>)

# run statement sql/json_loader.sql
# run statement sql/create_specs_table.sql - this may take a while
# run statement sql/create_spec_matchings_table.sql
# run statement sql/create_constraint.sql
```

By this point, you should have a first, working database schema.

## References

- [Report: Entity Resolution with MonetDB](report.pdf)
- [IDEL: In-Database Entity Linking with Neural Embeddings](https://arxiv.org/abs/1803.04884)
- [SIGMOD 2020 Contest: Task Details](http://www.inf.uniroma3.it/db/sigmod2020contest/task.html)
- [Embedded Python/NumPy in MonetDB](https://www.monetdb.org/blog/embedded-pythonnumpy-monetdb)
- [devUDF: Increasing UDF development efficiency through IDE
Integration](https://openproceedings.org/2019/conf/edbt/EDBT19_paper_242.pdf)