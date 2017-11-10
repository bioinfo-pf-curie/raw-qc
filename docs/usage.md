# Running Raw-QC

## Configuration

Once installed, just go to your analysis directory and run:
```
raw-qc --get-config
```
Raw-QC will copy the JSON configuration file to set your pipeline. It looks like:
```
"autotropos":
{
    "path": "",
    "options": "--auto",
    "threads": 8,
    "memory": "16g",
    "nodes": 1,
    "time": "01:00:00"
},
```
There are several options:
- path: the directory path of the executable
- options: compatible options of the tool
- threads: number of threads used by the tool and number of process requested to the cluster
- memory: quantity of RAM necessary requested to the cluster
- nodes: number of nodes requested to the cluster
- time: time requested to the cluster

## Running

Once the configuration file is filled, you can run the pipeline:
```
raw-qc --config-file config.json --read1 seq_R1.fastq.gz --read2 seq_R2.fastq.gz --output-dir analysis
```
Raw-QC will run the pipeline locally on your sample. Add the `--cluster` option to run it on the cluster.
To use the pipeline with multiple samples, you must provide a mple sample sheet like:
```
ID1,BIO_NAME1,R1,R2
ID2,BIO_NAME2,R1,R2
ID3,BIO_NAME3,R1,R2
```
And the command line is:
```
raw-qc --config-file config.json --sample-plan sample_sheet.csv --cluster --output-dir analysis
```
