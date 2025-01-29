# nf-refdb-amplicon
Nextflow pipeline for generating reference databases for amplicon sequences.

## How to install and run

**Install nextflow**
```
conda create -n nextflow -c conda-forge -c bioconda -c defaults nextflow
conda activate nextflow
```

**Clone the repo**
```
git clone https://github.com/mikerobeson/nf-refdb-amplicon
```
*Note: depending on the development cycle you may also need to clone and install the latest repo version of RESCRIPt into your QIIME 2 environment:*

```
conda activate qiime2-amplicon-2024.10 # or other recent version
git clone https://github.com/bokulich-lab/RESCRIPt
cd RESCRIPt
pip install .
```

**Run nextflow pipeline**:
Then change to the `nf-refdb-amplicon` directory:
```
cd nf-refdb-amplicon
```

### Then sun either the SSU (16S/18S rRNA gene) or the "extract sequence segments" (ess) pipeline:

- Use `-profile local` if running locally, or `-profile cluster` if running on HPC.
- Then set either `ssu` or `ess` for `params.pipeline_type` parameter within the `nextflow.config` file prior to running one of the pipelines outlined below.


```
nextflow run main.nf -profile <profile>
```

*Note: the `ess` pipeline is currently in alpha development. You'll have to provide files using the `params.segseqs`, `params.seqs`, and `params.taxa` parameters in the config file.*



## Cite
If you make use of this pipeline please cite RESCRIPt:

Michael S Robeson II, Devon R O'Rourke, Benjamin D Kaehler, Michal Ziemski, Matthew R Dillon, Jeffrey T Foster, Nicholas A Bokulich. (2021) RESCRIPt: Reproducible sequence taxonomy reference database management. PLoS Computational Biology 17 (11): e1009581. doi: [10.1371/journal.pcbi.1009581](http://dx.doi.org/10.1371/journal.pcbi.1009581).
