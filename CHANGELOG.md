# Raw-QC Version History

## Raw-QC v0.2dev

### News

- Raw-QC is now a package python to ease the installation.
- Rawqc_atropos is embedded in Raw-QC.

### Modification

- Rawqc_basic_metrics computation is speed up using a subsampling for the GC percent.
- Rawqc_atropos detection is speed up using a subsampling and the scratch directory.
- Rawqc_atropos use a different detection algorithm when reads are taller than 150 bases.

### Fixes

- Fix bug when rawqc_atropos found a remaining unknown base.
- Fix error when no log file is provided.
- Fix error when reads are smaller than 50 bases.
- Replace `-V` for `-v "PATH=$PATH"` to provide virtual environment on Torque.

## Raw-QC v0.1

The first version of Raw-QC in pure Bash.
