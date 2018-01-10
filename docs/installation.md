# Introduction

This pipeline assess your [FastQ](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) with Fastqc before and after
trimming. The triming is done with a wrapper of [Atropos](https://atropos.readthedocs.io/en/latest/) called
[Autotropos](https://atropos.readthedocs.io/en/latest/). The wrapper detect and remove automatically 3'-end adapters.
Results are reported in a HTML report using [MultiQC](http://multiqc.info/).

# Installing Raw-QC

The installation is pretty simple, just download the repository by copying and pasting these commands:
```
git clone https://gitlab.curie.fr/ngs-research/raw-qc.git
sudo ln -s $(realpath raw-qc/raw-qc) /usr/local/bin
```
If you do not have root right, create symbolic link in a local bin present in your `PATH`.

Some dependencies need to be installed. We propose to use Anaconda with the Bioconda channel.

You need to add `conda-forge` and `bioconda` channels:
```
conda config --add channels conda-forge
conda config --add channels bioconda
```

And then you can create your environment:
```
conda create --name raw-qc --file raw-qc/requirements.txt
source activate raw-qc
git clone https://gitlab.curie.fr/data-analysis/autotropos.git
cd autotropos
python setup.py install
```
By the way, if these tools are already available, you can just add their directory path in the config.json file.
