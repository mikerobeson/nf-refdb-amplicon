# nf-refdb-amplicon
Nextflow pipeline for generating reference databases for amplicon sequences.

## How to install and run

**Install nextflow**
```
conda create -n nextflow -c conda-forge -c bioconda -c defaults nextflow
conda activate nextflow
```

**Run pipeline**
```
cd nf-refdb-amplicon

nextflow run main.nf
```

*Note: add `-profile cluster` if running on HPC, or `-profile standard` if running locally.*

## Cite
If you make use of this pipeline please cite RESCRIPt:

Michael S Robeson II, Devon R O'Rourke, Benjamin D Kaehler, Michal Ziemski, Matthew R Dillon, Jeffrey T Foster, Nicholas A Bokulich. (2021) RESCRIPt: Reproducible sequence taxonomy reference database management. PLoS Computational Biology 17 (11): e1009581. doi: [10.1371/journal.pcbi.1009581](http://dx.doi.org/10.1371/journal.pcbi.1009581).