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

Make sure that the dataset is extracted. For example, you can use:

```shell
tar xvzf data/camera_specs.tar.gz -C ./data
```

All the necessary SQL statements (UDFs etc.) are available in the ``sql/`` directory, with each independent component 
hosted in a separate ``.sql`` file.

Just open:

```shell
mclient -u monetdb -d ecommercedb  # password is the default (<monetdb>)
```
and cast the SQL statements, preferably in the above order:

1. sql/cameras_loader.sql
2. sql/specs_loader.sql
3. sql/cameras_bulk_insert.sql
4. sql/cameras_constraints.sql
5. sql/specs_bulk_insert.sql
6. sql/specs_constraints.sql
7. sql/labels_create.sql
8. sql/labels_bulk_insert.sql
9. sql/labels_constraints.sql
   
By this point, you should have a first, working database schema. 

## Blocking

We would like to block together cameras of the same brand. This will later enable us to perform the pairwise comparisons
necessary for the entity resolution step only on suitable sub-spaces and not between all possible pairs.

To implement the blocking step, we will need the following:

10. sql/text_utils.sql
11. sql/blocks_create.sql
12. sql/cameras_add_block_id.sql
13. sql/blocks_bulk_insert.sql
14. sql/blocking.sql

## Filtering
15. sql/matched_camera_pairs_create.sql
16. sql/matched_camera_pairs_constraints.sql
17. sql/filtering.sql

**note**: you can also use the unified `main.sql` in order to run everything at once!

## References

- [Report: Entity Resolution with MonetDB](report.pdf)
- [A Survey of Blocking and Filtering Techniques for Entity Resolution](https://arxiv.org/pdf/1905.06167.pdf)  
- [IDEL: In-Database Entity Linking with Neural Embeddings](https://arxiv.org/abs/1803.04884)
- [SIGMOD 2020 Contest: Task Details](http://www.inf.uniroma3.it/db/sigmod2020contest/task.html)
- [MonetDB/Python Loader Functions](https://www.monetdb.org/blog/monetdbpython-loader-functions)  
- [Embedded Python/NumPy in MonetDB](https://www.monetdb.org/blog/embedded-pythonnumpy-monetdb)
- [Deep Learning for Entity Matching: A Design Space Exploration](http://pages.cs.wisc.edu/~anhai/papers1/deepmatcher-sigmod18.pdf)  
- [devUDF: Increasing UDF development efficiency through IDE
Integration](https://openproceedings.org/2019/conf/edbt/EDBT19_paper_242.pdf)
- [Don’t Keep My UDFs Hostage - Exporting UDFs For
Debugging Purposes](http://sbbd.org.br/2018/wp-content/uploads/sites/3/2018/02/p246-251.pdf)  