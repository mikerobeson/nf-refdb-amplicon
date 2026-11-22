# nf-refdb-amplicon: Small Sub-Unit (SSU) Workflow

Builds ready-to-use taxonomic classifiers from three curated SSU rRNA reference databases (SILVA, GTDB, RDP). For each database, the workflow will download, curate and perform classifier training automatically, producing full-length and/or amplicon-specific classifiers.

---
## Table of Contents

- [nf-refdb-amplicon: Small Sub-Unit (SSU) Workflow](#nf-refdb-amplicon-small-sub-unit-ssu-workflow)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting Started](#getting-started)
  - [Usage](#usage)
    - [Basic Usage](#basic-usage)
    - [All Databases](#all-databases)
    - [Selecting Databases](#selecting-databases)
    - [Skipping classifier training](#skipping-classifier-training)
  - [Parameters](#parameters)
    - [Database selection](#database-selection)
    - [Classifier options](#classifier-options)
    - [Primer pairs](#primer-pairs)
  - [Output](#output)
  - [Cite](#cite)

---
## Introduction

The *nf-refdb-amplicon's* **SSU (Small Sub-Unit) workflow** builds taxonomic classifiers from curated *small sub-unit ribosomal RNA* (16S/18S) reference databases. It assumes the source databases contain full-length, well-curated sequences, so a single primer-pair search is sufficient to recover the target amplicon.

For each selected database, the workflow downloads the reference data, dereplicates sequences carrying matching taxa, culls those with excessive degenerate bases and trains for full-length Naive Bayes classifier. When primer pairs are configured, it additionally can extract the corresponding amplicon region and train a region-specific classifier, for more robust taxonomic classification. It should be noted that users can optionally choose between either types when training classifiers.

Currently, the workflow supports three databases:
- **SILVA**
- **GTDB**
- **RDP**

> [!TIP]
> Some primer pairs bind near the ends of the full-length genes, where many database records will not contain the binding site. As a result, primer-pair extraction will silently drop the sequences. To avoid this please use [ESS workflow](docs/ess_README.md) for such targets.

For a detailed walkthrough of the underlying methods, see these QIIME2 tutorials:
- [Processing, filtering, and evaluating the SILVA database (and other reference sequence data) with RESCRIPt](https://forum.qiime2.org/t/processing-filtering-and-evaluating-the-silva-database-and-other-reference-sequence-data-with-rescript/15494)
- [How to train a GTDB SSU classifier using RESCRIPt](https://forum.qiime2.org/t/how-to-train-a-gtdb-ssu-classifier-using-rescript/25725)


---
## Getting Started

 [!IMPORTANT]
> Installation and deployment instructions for setting up the pipeline are documented in the [primary README](../README.md).

Once set up, verify the workflow options with:

```bash
nextflow run main.nf --help ssu
```


---
## Usage

### Basic Usage
```bash
nextflow run main.nf --pipeline_type ssu [options] -profile <local,conda|cluster,conda>
```

>[!IMPORTANT]
> Check out the Parameter section below for more options

**Show help:**
```bash
nextflow run main.nf --help ssu
```

### All Databases
Building all three databases with both full-length and amplicon classifiers, using the primer pairs configured in `conf/ssu.config`.

```bash
nextflow run main.nf \
    --pipeline_type ssu \
    --ssu.databases 'silva,rdp,gtdb' \
    --qiime_conda_env /path/to/rachis-qiime2-2026.10 \
    -profile local,conda
```

### Selecting Databases
Pass a comma-separated list. Quote it so the shell does not split on the comma:

```bash
nextflow run main.nf \
    --pipeline_type ssu \
    --ssu.databases 'rdp,gtdb' \
    -profile local,conda
```

### Skipping classifier training
Useful for a first pass, when only the curated sequences and taxonomy are needed:

```bash
nextflow run main.nf \
    --pipeline_type ssu \
    --ssu_databases rdp \
    --build_full_classifier false \
    --build_amplicon_classifier false \
    -profile local,conda
```

---
## Parameters

### Database selection

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ssu.databases` | `silva,gtdb,rdp` | Databases to build. Options: `silva`, `gtdb`, `rdp` |


### Classifier options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--build_full_classifier` | `true` | Train a classifier on full-length sequences |
| `--build_amplicon_classifier` | `true` | Extract the amplicon region and train a region-specific classifier |


### Primer pairs
Amplicon extraction is driven by `params.primer_pairs` in `conf/ssu.config`. Because the value is a list of lists, it cannot be overridden from the command line; hence, edit the config file directly.

```groovy
primer_pairs = [
    ['515F806R', 'GTGYCAGCMGCCGCGGTAA', 'GGACTACNVGGGTWTCTAAT']
]
```

Each entry is `[name, forward_primer, reverse_primer]`. 

> [!TIP]
> The name appears in output filenames, so keep it short and descriptive. 
> Multiple pairs may be listed, where each produces its own set of extracted sequences and classifier.


---
## Output

Results are written to the directory given by `--outdir` (default: `results`), split by database.

```
results/
├── silva/
├── gtdb/
├── rdp/
└── pipeline_info/
```

Each database directory also carries `versions.yml` files recording the QIIME 2 and plugin versions used.

**`pipeline_info/`** collects the Nextflow execution reports: `timeline.html`, `report.html`, `trace.txt`, and `dag.html`.

> [!IMPORTANT]
> Under `-profile local`, published files are symlinks into `work/`, so deleting the work directory breaks them. `-profile cluster` publishes real copies.

---
## Cite
Please be sure to cite the following:

- **If using the SILVA data** : Versions are released under different licenses. Refer to the [current SILVA release license information](https://www.arb-silva.de/silva-license-information/) for more details. [How to cite SILVA](https://www.arb-silva.de/contact/).
- **If using GTDB data** : See the [GTDB "about" page](https://gtdb.ecogenomic.org/about) for more details. [How to cite GTDB](https://gtdb.ecogenomic.org/about).
- **If using RDP data** : See the [main RDP GitHub page](https://github.com/rdpstaff) and the [RDP sourceforge page](https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/) for more details. Please cite the following RDP aritcles: [Wang *et al*. 2007](http://dx.doi.org/10.1128/AEM.00062-07) & [Wang *et al*. 2024](https://doi.org/10.1128/mra.01063-23).