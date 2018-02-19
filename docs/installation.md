# Introduction

This pipeline assess your [FastQ](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) with Fastqc before and after
trimming. The triming is done with a wrapper of [Atropos](https://atropos.readthedocs.io/en/latest/) called
[Autotropos](https://atropos.readthedocs.io/en/latest/). The wrapper detect and remove automatically 3'-end adapters.
Results are reported in a HTML report using [MultiQC](http://multiqc.info/).

# Installing Raw-QC

The installation is pretty simple, but some dependencies need to be installed.
We propose to use Anaconda with the Bioconda channel.

You need to add `conda-forge` and `bioconda` channels:
```
conda config --add channels conda-forge
conda config --add channels bioconda
```

And then just download the repository by copying and pasting these commands:
```
git clone https://gitlab.curie.fr/ngs-research/raw-qc.git
cd raw-qc
conda create --name raw-qc --file requirements.txt
source activate raw-qc
python setup.py install
```

Now, you can [run Raw-QC](usage.md) !