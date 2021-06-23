# Configuration of the reference genomes

The pipeline needs a reference genome for alignment and annotation.
All annotation data and paths must be defined/modified in the `conf/genomes.conf` file.

These paths can be supplied on the command line at run time (see the [usage](usage.md) documentation),
but for convenience it's often better to save these paths in a Nextflow config file.
See below the instructions on how to do this.

## Adding paths to a config file

Specifying long paths every time you run the pipeline is a pain.
To make this easier, the pipeline comes configured to understand reference genome keywords which correspond
to preconfigured paths to genomes.

Note that this genome key must be specified in the config file `conf/genomes.conf`.

To use this system, add paths to your config file using the following template:

```nextflow
params {
  genomes {
    fastqScreenGenomes {
      Genome ID  = '<PATH TO genome>/pre-built Bowtie2 indices'
    }
    'OTHER-GENOME' {
      // [..]
    }
  }
}
```

You can add as many genomes as you like as long as they have unique IDs.

