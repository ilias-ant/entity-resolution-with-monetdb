# Entity Resolution with MonetDB
**In-Database Machine Learning**

A proof-of-concept approach on an entity resolution task, with [Tensorflow](https://github.com/tensorflow/tensorflow) 
for the machine learning part and **everything** happening inside a [MonetDB](https://www.monetdb.org/Home) instance. 
This project was part of the course **Large Scale Data Management** at the MSc in Data Science of AUEB, carried out 
during the Winter Quarter 2020-21.

In other words, a MonetDB database instance that performs machine learning and de-duplicates products that are 
essentially the same, in its own right.

## Task Details

The task consists of identifying which product specifications (in short, specs) from multiple e-commerce websites 
represent the same real-world product.

*example product spec*
```json
{
    "<page title>": "Samsung Smart WB50F Digital Camera White Price in India",
    
    "brand": "Samsung",
    
    "dimension": "101 x 68 x 27.1 mm",
    
    "display": "LCD 3 Inches",
    
    "pixels": "Optical Sensor Resolution (in MegaPixel)\n16.2 MP",
    
    "battery": "Li-Ion"
}
```

We are provided with a dataset including ~**30k** specs in JSON format, each spec containing a list of (attribute_name, 
attribute_value) pairs extracted from a different web page, collected across 24 different web sources.

Each spec is stored as a file, and files are organized into directories, each directory corresponding to a different
web source (e.g., *www.alibaba.com*).
All specs refer to cameras and include information about the camera model (e.g. *Canon EOS 5D Mark II*) and, possibly, 
accessories (e.g. *lens kit, bag, tripod*). Accessories do not contribute to product identification: for instance, a 
*Canon EOS 5D Mark II* that is sold as a bundle with a bag represents the same core product as a *Canon EOS 5D Mark II* 
that is sold alone.

For a more detailed view of the task, the datasets, the evaluation process, see the *Other References* section below.

## System Dependencies

- Debian-based distribution (tested against [Ubuntu 18.04.5](https://releases.ubuntu.com/18.04/) and [Pop!_OS 20.04](https://pop.system76.com/))
- MonetDB with embedded Python3 support (tested against [v11.39.11, v11.41.5](https://www.monetdb.org/Downloads/ReleaseNotes))

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

# create a db farm, preferably at this project's root dir
monetdbd create ecommercedbfarm
monetdbd start ecommercedbfarm

# create a database, with python3 support enabled
monetdb create ecommercedb
monetdb set embedpy3=true ecommercedb
monetdb release ecommercedb
```

Now, to run a simple health check:

```shell
mclient -u monetdb -d ecommercedb  # password is the default (<monetdb>)
```

and run the following:

```sql
CREATE OR REPLACE FUNCTION python_healthcheck () 
RETURNS STRING 
LANGUAGE python {
    import sys 


    return sys.version
};

SELECT python_healthcheck();
```

this should display your system-wide Python version.

## Data Loading

Make sure that the dataset is in extracted form. For example, you can use:

```shell
tar xvzf data/camera_specs.tar.gz -C ./data
```

All the necessary SQL statements (UDFs etc.) are available in the ``entity-resolution-with-monetdb/sql/`` directory, 
with each independent component hosted in a separate ``.sql`` file.

**NOTE**: Also, for convenience, there is the ``entity-resolution-with-monetdb/main.sql`` available, which contains all the SQL statements together 
and can be used for a quicker build.

Simply cast the SQL statements, preferably in the order below, in the ``mclient`` shell:

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

We would like to block together cameras of the same brand. This will help us restrict the 
"potential matching" space, as cameras that belong to different blocks should not, in principle, refer to the same 
camera! 

To implement the blocking step, we will need the following:

10. sql/text_utils.sql
11. sql/brands_create.sql
12. sql/cameras_add_brand_id.sql
13. sql/brands_bulk_insert.sql
14. sql/blocking.sql

## Filtering

After block formation, we would also like to filter out "easy" matches, by extracting-via-heuristics and comparing the 
models of the cameras. We would thus end up - for each block - with a subset of cameras that 
match both on brand and model (and basically refer to the same camera).

To implement the filtering step, we will need the following:

15. sql/filtering.sql

## Matching

What we have gained from blocking & filtering is that we now only have to work (and eventually perform pair-wise 
comparisons) with the camera subsets that remained unmatched within blocks.

Before we proceed, let's make sure that [Tensorflow](https://github.com/tensorflow/tensorflow) is installed. Running the
following statement in the ``mclient``:

```sql
CREATE OR REPLACE FUNCTION tensorflow_healthcheck () 
RETURNS STRING 
LANGUAGE python {
    import tensorflow as tf 
    
    
    return tf.version.VERSION
};

SELECT tensorflow_healthcheck();
```
should display the Tensorflow version. In case the error ``No module named 'tensorflow'`` emerges, simply install the library:

```shell
python3 -m pip install tensorflow
```

and perform again the health check through the ``mclient``. 

Now, onto the "matching" step.

A first crucial observation is that the labelled dataset is transitively closed (i.e., if A matches with B and B matches
with C, then A matches with C).

-- \# *work in progress* 🚧

## Papers

- [End-to-End Entity Resolution for Big Data: A Survey](https://arxiv.org/pdf/1905.06397.pdf)
- [Evaluation of entity resolution approaches on real-world match problems](https://dbs.uni-leipzig.de/file/EvaluationOfEntityResolutionApproaches_vldb2010_CameraReady.pdf)
- [A Survey of Blocking and Filtering Techniques for Entity Resolution](https://arxiv.org/pdf/1905.06167.pdf)
- [IDEL: In-Database Entity Linking with Neural Embeddings](https://arxiv.org/abs/1803.04884)
- [Deep Integration of Machine Learning Into Column Stores](https://openproceedings.org/2018/conf/edbt/paper-293.pdf)
- [Deep Learning for Entity Matching: A Design Space Exploration](http://pages.cs.wisc.edu/~anhai/papers1/deepmatcher-sigmod18.pdf)
- [Vectorized UDFs in Column-Stores](https://mytherin.github.io/papers/2016-vectorizedudfs.pdf)
- [devUDF: Increasing UDF development efficiency through IDE](https://openproceedings.org/2019/conf/edbt/EDBT19_paper_242.pdf)
- [Don’t Keep My UDFs Hostage - Exporting UDFs For
Debugging Purposes](http://sbbd.org.br/2018/wp-content/uploads/sites/3/2018/02/p246-251.pdf)

## Other References

- [SIGMOD 2020 Contest: Task Details](http://www.inf.uniroma3.it/db/sigmod2020contest/task.html)
- [MonetDB/Python Loader Functions](https://www.monetdb.org/blog/monetdbpython-loader-functions)  
- [Embedded Python/NumPy in MonetDB](https://www.monetdb.org/blog/embedded-pythonnumpy-monetdb)
- [FaBIAM Architecture Overview](https://fashionbrain-project.eu/showcase/MonetDB/output1.html)
