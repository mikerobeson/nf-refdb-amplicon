# nf-refdb-amplicon: Extract Sequence Segments (ESS) Workflow

The **ESS (Extract Sequence Segments) workflow** automates the iterative reference database curation approach described in the [RESCRIPt `extract-seq-segments` tutorial](https://forum.qiime2.org/t/using-rescripts-extract-seq-segments/22903). It is designed for building reference databases for **any marker gene** where PCR primer-pair extraction alone is insufficient to capture all relevant reference sequences.

---
## Table of Contents

- [nf-refdb-amplicon: Extract Sequence Segments (ESS) Workflow](#nf-refdb-amplicon-extract-sequence-segments-ess-workflow)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting Started](#getting-started)
  - [Usage](#usage)
    - [Custom Data](#custom-data)
    - [NCBI](#ncbi)
    - [UNITE](#unite)
    - [MIDORI2](#midori2)
    - [PR2](#pr2)
  - [Parameters](#parameters)
    - [Data Source](#data-source)
    - [Custom Input](#custom-input)
    - [Primer based Segment Extraction](#primer-based-segment-extraction)
    - [Output Naming](#output-naming)
    - [ESS Iteration Parameters](#ess-iteration-parameters)
    - [NCBI](#ncbi-1)
    - [UNITE](#unite-1)
    - [MIDORI2](#midori2-1)
    - [PR2 (Protist Ribosomal Reference)](#pr2-protist-ribosomal-reference)
    - [SILVA](#silva)
    - [GTDB (Genome Taxonomy Database)](#gtdb-genome-taxonomy-database)
    - [RDP (Ribosomal Database Project)](#rdp-ribosomal-database-project)
  - [Output](#output)
  - [Cite](#cite)

---
## Introduction
Reference sequences spanning a region of interest are often retrieved from online databases such as GenBank. This retrieval is typically performed by searching for and extracting segments using PCR primer pairs. However, many repository sequences lack primer binding sites because:

- Primers were trimmed before deposition
- The sequence spans a region not targeted by either primer
- The sequence only contains a match to one primer
- The sequence is of low quality

*nf-refdb-amplicon's* **ESS workflow** solves this by using previously extracted segments as queries against the full reference set. Any reference sequence that contains a segment matching the query pool (within a user-defined identity threshold) will have that segment extracted. This process is **iterated** to progressively expand the reference pool.

> [!IMPORTANT]
> For a detailed walkthrough of the underlying methods, see these QIIME 2 Forum tutorials:
> - [Using RESCRIPt's `extract-seq-segments` to extract reference sequences without PCR primer pairs](https://forum.qiime2.org/t/using-rescripts-extract-seq-segments-to-extract-reference-sequences-without-pcr-primer-pairs/23618)
> - [Train a taxonomy classifier by extracting an amplicon region from a curated sequence alignment (using SILVA as an example)](https://forum.qiime2.org/t/train-a-taxonomy-classifier-by-extracting-an-amplicon-region-from-a-curated-sequence-alignment-using-silva-as-an-example/34289)


---
## Getting Started

> [!IMPORTANT]
> Installation and deployment instructions for setting up the pipeline are documented in the [primary README](../README.md).

Once set up, verify the workflow options with:

```bash
nextflow run main.nf --help ess
```


---
## Usage

**Basic Usage:**
```bash
nextflow run main.nf --pipeline_type ess [options] -profile <local,conda|cluster,conda>
```

Every run needs a **data source** (`--ess.source`) and a **starting pool**, either supplied directly with `--ess.seqsegs`, or generated automatically from `--ess.fwd_primer` & `--ess.rev_primer`.

>[!IMPORTANT]
> Check out the Parameter section below for more options

**Show help:**
```bash
nextflow run main.nf --help ess
```


### Custom Data
When users already have sequence, taxonomy, and starting-segment artifacts, they can point the workflow to those local files so no external data is downloaded.

```bash
nextflow run main.nf \
    --pipeline_type ess \
    --ess.source custom \
    --ess.seqs data/test_trnL_seqs.qza \
    --ess.taxa data/test_trnL_taxa.qza \
    --ess.seqsegs data/test_trnL_seeds.qza \
    --ess.db trnL \
    --ess.amp_seg trnLgh \
    --ess.max_iter 2 \
    --qiime_conda_env /path/to/rachis-qiime2-2026.4 \
    -profile local,conda
```
> [!WARNING]
> Ensure the paths point to valid .qza artifacts
> The run will fail if required inputs are missing or invalid.

> [!TIP]
> `--ess.db` and `--ess.amp_seg` only affect output file names (`trnL_trnLgh_culled_seqs.qza`, etc.), so it is recommended to set them to something meaningful for markers.


### NCBI
User provides an NCBI Entrez query. The workflow will download matching records and extract initial amplicon segments using the supplied forward and reverse primers.

```bash
nextflow run main.nf \
    --pipeline_type ess \
    --ess.source ncbi \
    --ess.ncbi_query '"Bacillus subtilis"[Organism] AND 16S[Title] AND 1000:2000[SLEN]' \
    --ess.fwd_primer GTGYCAGCMGCCGCGGTAA \
    --ess.rev_primer GGACTACNVGGGTWTCTAAT \
    --ess.extract_min_length 10 \
    --ess.extract_max_length 600 \
    --ess.max_iter 1 \
    --ess.train_classifier false \
    --qiime_conda_env /path/to/rachis-qiime2-2026.4 \
    -profile local,conda
```

> [!TIP]
> Entrez syntax uses double quotes internally, so the full query must be wrapped in single quotes. 
> Restricting by `[SLEN]` keeps test downloads small — broad queries spanning whole clades or marker genes can retrieve hundreds of thousands of records.


### UNITE
Fungal and eukaryote ITS sequences are retrieved directly from UNITE's PlutoF REST API.

```bash
nextflow run main.nf \
    --pipeline_type ess \
    --ess.source unite \
    --ess.unite_version '2025-02-19' \
    --ess.unite_taxon_group fungi \
    --ess.unite_cluster_id dynamic \
    --ess.unite_singletons false \
    --ess.fwd_primer CTTGGTCATTTAGAGGAAGTAA \
    --ess.rev_primer GCTGCGTTCTTCATCGATGC \
    --ess.extract_min_length 10 \
    --ess.extract_max_length 600 \
    --ess.max_iter 2 \
    --ess.train_classifier true \
    --qiime_conda_env /path/to/rachis-qiime2-2026.4 \
    -profile local,conda
```

In the above usage, the primers shown are ITS1F / ITS2.

> [!NOTE]
> `--ess.unite_version` accepts UNITE's **date-based** release strings (e.g. `2025-02-19`). Run `qiime rescript get-unite-data --help` for accepted values.
> `--ess.unite_cluster_id` accepts `99`, `97`, or `dynamic`.
> `fungi` produces a smaller download; `eukaryotes` is larger but provides outgroups, which improves fungi / non-fungi discrimination.


### MIDORI2

Mitochondrial marker genes. Gene identifiers follow MIDORI2's internal codes — `srRNA`
for 12S, `lrRNA` for 16S, `CO1` for COI.

```bash
nextflow run main.nf \
    --pipeline_type ess \
    --ess.source midori2 \
    --ess.midori2_target_gene srRNA \
    --ess.fwd_primer GTCGGTAAAACTCGTGCCAGC \
    --ess.rev_primer CATAGTGGGGTATCTAATCCCAGTTTG \
    --ess.extract_min_length 10 \
    --ess.extract_max_length 250 \
    --ess.max_iter 2 \
    --ess.train_classifier true \
    --qiime_conda_env /path/to/rachis-qiime2-2026.4 \
    -profile local,conda
```

Here, the primers shown are MiFish-U (12S, fish eDNA). 

> [!NOTE]
> The tighter `--ess.extract_max_length 250`, matched to the short MiFish amplicon.


### PR2

Protist and eukaryote SSU rRNA sequences.

```bash
nextflow run main.nf \
    --pipeline_type ess \
    --ess.source pr2 \
    --ess.pr2_version '5.1.0' \
    --ess.fwd_primer GTGYCAGCMGCCGCGGTAA \
    --ess.rev_primer GGACTACNVGGGTWTCTAAT \
    --ess.extract_min_length 10 \
    --ess.extract_max_length 600 \
    --ess.max_iter 1 \
    --ess.train_classifier false \
    --qiime_conda_env /path/to/rachis-qiime2-2026.4 \
    -profile local,conda
```

> [!TIP]
> Available versions depend on the installed RESCRIPt build. So, please check `qiime rescript get-pr2-data --help`.


---
## Parameters

### Data Source

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ess.source` | `custom` | Data source. Options: `custom`, `ncbi`, `unite`, `midori2`, `pr2`, `silva`, `gtdb`, `rdp` |


### Custom Input
When `--ess.source` is `custom`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ess.seqs` | — | Path to sequences (`.qza`) — **required** |
| `--ess.taxa` | — | Path to taxonomy (`.qza`) — **required** |
| `--ess.seqsegs` | — | Path to sequence segments (`.qza`) — **required** |


### Primer based Segment Extraction
When `--ess.source` is *NOT* `custom` and `--ess.seqsegs` is *NOT* provided, the pipeline generates initial segments using primer extraction

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ess.fwd_primer` | `null` | Forward primer sequence (5'→3') — required if no `seqsegs` |
| `--ess.rev_primer` | `null` | Reverse primer sequence (5'→3') — required if no `seqsegs` |
| `--ess.extract_min_length` | `10` | Minimum extracted segment length |
| `--ess.extract_max_length` | `0` | Maximum extracted segment length (`0` = disabled) |


### Output Naming

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ess.db` | `refdb` | Database name for output files |
| `--ess.amp_seg` | `segment` | Amplicon segment name |


### ESS Iteration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ess.iteration_schedule` | `[[0.7, 2]]` | (perc_identity, n_iters) pairs run in order, each stage seeding the next, e.g. "[(0.7, 2), (0.8, 2), (0.9, 1)]" or "0.7:2,0.8:2,0.9:1" |
| `--ess.min_seq_len` | `10` | Minimum sequence length |
| `--ess.max_seq_len` | `50000` | Maximum sequence segment length |
| `--ess.train_classifier` | `true` | Train classifier from output |

> [!TIP]
> Setting `--ess.perc_identity` between `0.7` and `0.9` is typically ideal. 
> More conservative settings (`0.9`) reduce the chance of extracting spurious segments but often require more iterations to expand the reference pool. 
> Some amplicons may need only 1–2 iterations, while others may need 4–6.


### NCBI
When `--ess.source` is `ncbi`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ncbi_query` | — | NCBI Entrez query string — **required** |
| `--ncbi.ranks` | `kingdom phylum class order family genus species` | List of taxonomic ranks for building NCBI taxonomy |
| `--ncbi.rank_propagation` | `true` | Enable rank propagation |

The query follows standard NCBI Entrez syntax. Example:
```bash
--ess.ncbi_query "txid35493[ORGN] AND (trnL OR tRNA-Leu) AND (chloroplast[Filter] OR plastid[Filter]) NOT environmental sample[Filter] NOT uncultured[Title]"
```

> [!TIP]
> Run `qiime rescript get-ncbi-data --help` for more info.


### UNITE
When `--ess.source` is `unite`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--unite.version` | `2025-02-19` | UNITE version |
| `--unite.taxon_group` | `eukaryotes` | Taxon group: `fungi` or `eukaryotes` |
| `--unite.cluster_id` | `dynamic` | Cluster ID threshold: `99`, `97`, or `dynamic` |
| `--unite.singletons` | `false` | Include singletons |

> [!TIP]
> Run `qiime rescript get-unite-data --help` for more info.


### MIDORI2
When `--ess.source` is `midori2`

> [!NOTE]
> We are still in the process of upgrading the current MIDORI2 module to the latest RESCRIPt parameters. 
> Please note that some features may not work and may produce errors when run.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--ess.midori2_target_gene` | `COI` | Target mitochondrial gene |
| `--ess.midori2_version` | `273` | MIDORI2 version |

> [!TIP]
> Run `qiime rescript get-midori2-data --help` for the full list of target genes.


### PR2 (Protist Ribosomal Reference)
When `--ess.source` is `pr2`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--pr2.version` | `5.1.1` | PR2 version (e.g., `5.1.1`) |
| `--pr2.ranks`   | `domain supergroup division subdivision class order family genus species` | List of taxonomic ranks for building PR2 taxonomy database |

> [!TIP]
> Run `qiime rescript get-pr2-data --help` for more info.


### SILVA
When `--ess.source` is `silva`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `silva.version` | `144` | SILVA version |
| `silva.target`  | `SSURef_N99` | SILVA target |
| `silva.ranks`   | `domain phylum class order family genus` | Taxonomy ranks |
| `silva.rank_propagation` | `true` | Enable rank propagation |
| `silva.download_sequences` | `unaligned` | Download type |

> [!TIP]
> Run `qiime rescript get-silva-data --help` for more info.


### GTDB (Genome Taxonomy Database)
When `--ess.source` is `gtdb`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--gtdb.version` | `220.0` | GTDB version |
| `--gtdb.domain`  | `Both`  | Domain |
| `--gtdb.dbtype`  | `SpeciesReps` | DB type |

> [!TIP]
> Run `qiime rescript get-silva-data --help` for more info.


### RDP (Ribosomal Database Project)
When `--ess.source` is `rdp`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--rdp.version` | `19` | RDP training set version |
| `--rdp.dirname` | `RDPClassifier_16S_trainsetNo19_QiimeFormat` | RDP directory name |
| `--rdp.url` | See SourceForge | Download URL link |


---
## Output
Results are written to the directory given by `--outdir` (default: `results`).

```
results/
├── ess/
│   ├── downloaded_data/     # reference sequences + taxonomy (ncbi, unite, pr2)
│   ├── initial_segments/    # primer-extracted starting segment pool
│   ├── iterations/          # per-iteration curated output
│   │   ├── iter_1/
│   │   └── iter_2/
│   └── classifier/          # trained classifier
└── pipeline_info/           # execution reports
```

Each published directory also contains a `versions.yml` recording the QIIME 2 and plugin versions used by that step.

The **`downloaded_data/`** directory holds the raw artifacts retrieved from a public database — `<source>_sequences.qza` and `<source>_taxonomy.qza`. It is absent when `--ess.source custom`, since those files are user-supplied.

**`initial_segments/`** appears only when `--ess.seqsegs` is omitted and primers are supplied instead. It contains `initial_seq_segments.qza`, the seed pool for the first iteration.

**`iterations/`** contains one subdirectory per cycle (`iter_1/`, `iter_2/`, …), each with the curated sequences (`<db>_<amp_seg>_culled_seqs.qza`), matching taxonomy (`<db>_<amp_seg>_derep_taxa.qza`), and the `state.json` handed to the next iteration. The `<db>` and `<amp_seg>` prefixes come from `--ess.db` and `--ess.amp_seg`, so `--ess.db trnL --ess.amp_seg trnLgh` yields `trnL_trnLgh_culled_seqs.qza`.

The culled sequences from the **final** iteration are the curated reference database. Because each iteration's output seeds the next, sequence counts should grow between iterations — comparing counts across `iter_*/` is the quickest way to judge whether further iterations are worthwhile. Intermediate artifacts (matched, unmatched, and pre-culled dereplicated sequences) remain in the work directory.

**`classifier/`** holds `ess_classifier.qza`, trained on the final iteration, and is written only when `--ess.train_classifier true`. It is ready for use with `qiime feature-classifier classify-sklearn`.

**`pipeline_info/`** collects the Nextflow execution reports: `timeline.html`, `report.html`, `trace.txt`, and `dag.html`.

> [!IMPORTANT]
> Under `-profile local`, published files are symlinks into `work/`, so deleting the work directory breaks them. `-profile cluster` publishes real copies.


---
## Cite
Please be sure to cite the following:

- **If using NCBI Genbank data** : See the [NCBI disclaimer and copyright notice](https://www.ncbi.nlm.nih.gov/home/about/policies/) for more details. [How to cite NCBI](https://support.nlm.nih.gov/knowledgebase/article/KA-03391/en-us).
- **If using MIDORI2 data** : See the [MIDORI2 website](https://www.reference-midori.info/) for more details. **Cite:** Leray, M., Knowlton, N., & Machida, R. J. (2022). MIDORI2: A collection of quality controlled, preformatted, and regularly updated reference databases for taxonomic assignment of eukaryotic mitochondrial sequences. *Environmental DNA*, 4(4), 894–907. doi: [10.1002/edn3.303](https://doi.org/10.1002/edn3.303).
- **If using UNITE data** : Licensed under CC BY-SA 4.0. See [UNITE citation page](https://unite.ut.ee/cite.php) for more details. **Cite:** Abarenkov, K., Nilsson, R. H., Larsson, K.-H., Taylor, A. F. S., May, T. W., Frøslev, T. G., *et al*. (2024). The UNITE database for molecular identification and taxonomic communication of fungi and other eukaryotes: sequences, taxa and classifications reconsidered. *Nucleic Acids Research*. doi: [10.1093/nar/gkad1039](https://doi.org/10.1093/nar/gkad1039).
- **If using PR2 data** : See the [PR2 database](https://pr2-database.org/) for more details. **Cite:** Guillou, L., Bachar, D., Audic, S., Bass, D., Berney, C., Bittner, L., *et al*. (2013). The Protist Ribosomal Reference database (PR2): a catalog of unicellular eukaryote Small Sub-Unit rRNA sequences with curated taxonomy. *Nucleic Acids Research*, 41(D1), D597–D604. doi: [10.1093/nar/gks1160](https://doi.org/10.1093/nar/gks1160).
- **If using the SILVA data** : Versions are released under different licenses. Refer to the [current SILVA release license information](https://www.arb-silva.de/silva-license-information/) for more details. [How to cite SILVA](https://www.arb-silva.de/contact/).
- **If using GTDB data** : See the [GTDB "about" page](https://gtdb.ecogenomic.org/about) for more details. [How to cite GTDB](https://gtdb.ecogenomic.org/about).
- **If using RDP data** : See the [main RDP GitHub page](https://github.com/rdpstaff) and the [RDP sourceforge page](https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/) for more details. Please cite the following RDP aritcles: [Wang *et al*. 2007](http://dx.doi.org/10.1128/AEM.00062-07) & [Wang *et al*. 2024](https://doi.org/10.1128/mra.01063-23).