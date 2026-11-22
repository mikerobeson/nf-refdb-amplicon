#!/usr/bin/env nextflow

/*
========================================================================================
    nf-refdb-amplicon
========================================================================================
    Nextflow pipeline for generating reference databases for amplicon sequences.

    GitHub : https://github.com/mikerobeson/nf-refdb-amplicon
    Website: https://github.com/bokulich-lab/RESCRIPt
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    IMPORT SUBWORKFLOWS
========================================================================================
*/

include { SSU } from './subworkflows/SSU/ssu.nf'
include { ESS } from './subworkflows/ESS/ess.nf'


/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {

    // Pipeline information
    log.info """
    ===================================================================

    ███╗  ██╗███████╗    ██████╗ ███████╗███████╗██████╗ ██████╗
    ████╗ ██║██╔════╝    ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗
    ██╔██╗██║█████╗  ─── ██████╔╝█████╗  █████╗  ██║  ██║██████╔╝
    ██║╚████║██╔══╝      ██╔══██╗██╔══╝  ██╔══╝  ██║  ██║██╔══██╗
    ██║ ╚███║██║         ██║  ██║███████╗██║     ██████╔╝██████╔╝
    ╚═╝  ╚══╝╚═╝         ╚═╝  ╚═╝╚══════╝╚═╝     ╚═════╝ ╚═════╝
     █████╗ ███╗   ███╗██████╗ ██╗     ██╗ ██████╗  ██████╗ ███╗  ██╗
    ██╔══██╗████╗ ████║██╔══██╗██║     ██║██╔════╝ ██╔═══██╗████╗ ██║
    ███████║██╔████╔██║██████╔╝██║     ██║██║      ██║   ██║██╔██╗██║
    ██╔══██║██║╚██╔╝██║██╔═══╝ ██║     ██║██║      ██║   ██║██║╚████║
    ██║  ██║██║ ╚═╝ ██║██║     ███████╗██║╚██████╗ ╚██████╔╝██║ ╚███║
    ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚══╝

    nf-refdb-amplicon v${workflow.manifest.version}
    ===================================================================
    Pipeline type   : ${params.pipeline_type ?: 'not set'}
    Output directory: ${params.outdir}
    ===================================================================
    """.stripIndent()


    // Help messages
    if (params.help) {

        // --help ssu
        if (params.help == 'ssu') {
            log.info """
            ===================================================================
            SSU Pipeline Help (--pipeline_type ssu)
            ===================================================================

            The SSU pipeline builds reference databases for Small Subunit
            ribosomal RNA (16S/18S) from supported public repositories.

            Usage:
                nextflow run main.nf --pipeline_type ssu [options] -profile <local,conda | cluster,conda>

            SSU Parameters:
                --ssu.databases             Databases to build (comma-separated) [default: ${params.ssu.databases}]
                                            Available: silva, rdp, gtdb
                --build_full_classifier     Build full-length classifier [default: ${params.build_full_classifier}]
                --build_amplicon_classifier Build amplicon classifier [default: ${params.build_amplicon_classifier}]

            Primer Pairs:
                --primer_pairs              List of primer pairs for amplicon region extraction [default: null]
                                            Format: [[name, forward_primer, reverse_primer], ...]

                                            Do not use 'full' as a primer pair name — it is reserved.

                                            Note: Some primer-pair combinations may not work if a
                                            primer is towards the end of the full-length SSU sequence,
                                            as the primer sequence may not be present at that location.
                                            For these cases, use the ESS pipeline instead.

                                            Available primer pairs (uncomment in conf/ssu.config):
                                              27F338R   : AGAGTTTGATYMTGGCTCAG / GCTGCCTCCCGTAGGAGT
                                              27F534R   : AGAGTTTGATYMTGGCTCAG / ATTACCGCGGCTGCTGG
                                              357wF805R : CCTACGGGNGGCWGCAG    / GACTACHVGGGTATCTAATCC
                                              357wF806R : CCTACGGGNGGCWGCAG    / GGACTACHVGGGTWTCTAAT
                                              515F806R  : GTGYCAGCMGCCGCGGTAA  / GGACTACNVGGGTWTCTAAT
                                              515F926R  : GTGYCAGCMGCCGCGGTAA  / CCGYCAATTYMTTTRAGTTT
                                              515F944R  : GTGCCAGCMGCCGCGGTAA  / GAATTAAACCACATGCTC
                                              939F1378R : GAATTGACGGGGGCCCGCACAAG / CGGTGTGTACAAGGCCCGGGAACG

            SILVA Parameters:
               --silva.version              SILVA version [default: ${params.silva?.version ?: '144'}]
               --silva.target               SILVA target [default: ${params.silva?.target ?: 'SSURef_NR99'}]
               --silva.ranks                Taxonomy ranks [default: ${params.silva?.ranks ?: 'domain phylum class order family genus'}]
               --silva.rank_propagation     Enable rank propagation [default: ${params.silva?.rank_propagation ?: true}]
               --silva.download_sequences   Download type [default: ${params.silva?.download_sequences ?: 'unaligned'}]

            GTDB Parameters:
               --gtdb.version          GTDB version [default: ${params.gtdb?.version ?: '232.0'}]
               --gtdb.domain           Domain [default: ${params.gtdb?.domain ?: 'Both'}]
               --gtdb.dbtype           DB type [default: ${params.gtdb?.dbtype ?: 'SpeciesReps'}]

            RDP Parameters:
                --rdp.version           RDP training set version [default: ${params.rdp?.version ?: '19'}]
                --rdp.dirname           RDP directory name [default: ${params.rdp?.dirname ?: 'N/A'}]
                --rdp.url               Download URL [default: SourceForge]

            Examples:
                # Build RDP and GTDB only, no classifiers:
                nextflow run main.nf --pipeline_type ssu \\
                    --ssu.databases 'rdp,gtdb' \\
                    --build_full_classifier false \\
                    --build_amplicon_classifier false \\
                    -profile local,conda

                # Build all databases with default amplicon classifier (515F806R):
                nextflow run main.nf --pipeline_type ssu \\
                    --ssu.databases 'silva,rdp,gtdb' \\
                    -profile local,conda

                # To change primer pairs, edit conf/ssu.config directly
            ===================================================================
            """.stripIndent()
        exit 0
        }

        // --help ess
        if (params.help == 'ess') {
            log.info """
            ===================================================================
            ESS Pipeline Help (--pipeline_type ess)
            ===================================================================

            The ESS pipeline performs iterative Evaluate, Select, Subset
            curation of reference sequences. Supports custom user files or
            downloading from public databases via RESCRIPt.

            Usage:
                nextflow run main.nf --pipeline_type ess [options] -profile <local,conda | cluster,conda>

            Data Source:
                --ess.source                Data source [default: ${params.ess.source}]
                                            Options: custom, ncbi, unite, midori2, pr2, silva, gtdb, rdp

            Custom Input (when --ess.source custom):
                --ess.seqs                  Path to sequences (.qza) [required]
                --ess.taxa                  Path to taxonomy (.qza) [required]
                --ess.seqsegs               Path to sequence segments (.qza) [required]

            Primer-Based Segment Extraction:
                When --ess.source is not 'custom' and --ess.seqsegs is not provided,
                the pipeline generates initial segments using primer extraction.

                --ess.fwd_primer            Forward primer sequence (5'->3') [default: ${params.ess.fwd_primer ?: 'null (required if no seqsegs)'}]
                --ess.rev_primer            Reverse primer sequence (5'->3') [default: ${params.ess.rev_primer ?: 'null (required if no seqsegs)'}]
                --ess.extract_min_length    Minimum extracted segment length [default: ${params.ess.extract_min_length}]
                --ess.extract_max_length    Maximum extracted segment length [default: ${params.ess.extract_max_length ?: '0 (disabled)'}]

            Output:
                --ess.db                    Database name for output files [default: ${params.ess.db}]
                --ess.amp_seg               Amplicon segment name [default: ${params.ess.amp_seg}]

            ESS Iteration Parameters:
                --ess.iteration_schedule    (perc_identity, n_iters) pairs run in order, each stage seeding the next, e.g.
                                            "[(0.7, 2), (0.8, 2), (0.9, 1)]" or "0.7:2,0.8:2,0.9:1" [default: ${params.ess.iteration_schedule}]
                --ess.min_seq_len           Minimum sequence length [default: ${params.ess.min_seq_len}]
                --ess.max_seq_len           Maximum sequence segment length [default: ${params.ess.max_seq_len}]
                --ess.train_classifier      Train classifier from output [default: ${params.ess.train_classifier}]

            NCBI Parameters (when --ess.source ncbi):
                --ncbi.query                 NCBI Entrez query string [default: '']
                --ncbi.ranks                 List of taxonomic ranks for building NCBI taxonomy [default: ${params.ncbi?.ranks ?: 'kingdom phylum class order family genus species'}]
                --ncbi.rank_propagation      Enable rank propagation [default: ${params.ncbi?.rank_propagation ?: true}]

            UNITE Parameters (when --ess.source unite):
                --unite.version         UNITE version [default: ${params.unite?.version ?: '2025-02-19'}]
                --unite.taxon_group     Taxon group: fungi, eukaryotes [default: ${params.unite?.taxon_group ?: 'eukaryotes'}]
                --unite.cluster_id      Cluster ID threshold [default: ${params.unite?.cluster_id ?: '99'}]
                --unite.singletons      Include singletons [default: ${params.unite?.singletons ?: false}]

            MIDORI2 Parameters (when --ess.source midori2):
                --ess.midori2_target_gene   Target gene (COI, 12S, 16S, etc.) [default: ${params.ess.midori2_target_gene}]
                --ess.midori2_version       MIDORI2 version [default: ${params.ess.midori2_version ?: 'latest'}]

            PR2 Parameters (when --ess.source pr2):
                --pr2.version           PR2 version [default: ${params.pr2?.version ?: '5.1.1'}]
                --pr2.ranks             List of taxonomic ranks for building PR2 taxonomy database [default: ${params.pr2?.ranks ?: 'domain supergroup division subdivision class order family genus species'}]
            
            SILVA Parameters (when --ess.source silva):
               --silva.version              SILVA version [default: ${params.silva?.version ?: '144'}]
               --silva.target               SILVA target [default: ${params.silva?.target ?: 'SSURef_NR99'}]
               --silva.ranks                Taxonomy ranks [default: ${params.silva?.ranks ?: 'domain phylum class order family genus'}]
               --silva.rank_propagation     Enable rank propagation [default: ${params.silva?.rank_propagation ?: true}]
               --silva.download_sequences   Download type [default: ${params.silva?.download_sequences ?: 'unaligned'}]
            
            GTDB Parameters (when --ess.source gtdb):
               --gtdb.version          GTDB version [default: ${params.gtdb?.version ?: '232.0'}]
               --gtdb.domain           Domain [default: ${params.gtdb?.domain ?: 'Both'}]
               --gtdb.dbtype           DB type [default: ${params.gtdb?.dbtype ?: 'SpeciesReps'}]
            
            RDP Parameters (when --ess.source rdp):
                --rdp.version           RDP training set version [default: ${params.rdp?.version ?: '19'}]
                --rdp.dirname           RDP directory name [default: ${params.rdp?.dirname ?: 'N/A'}]
                --rdp.url               Download URL [default: SourceForge]

            Examples:
                # Run ESS pipeline with custom input files:
                    nextflow run main.nf --pipeline_type ess \\
                        --ess.source custom \\
                        --ess.seqs data/test_trnL_seqs.qza \\
                        --ess.taxa data/test_trnL_taxa.qza \\
                        --ess.seqsegs data/test_trnL_seeds.qza \\
                        --ess.db trnL \\
                        --ess.amp_seg trnLgh \\
                        --ess.iteration_schedule "[(0.7, 2)]" \\
                        --qiime_conda_env /path/to/rachis-qiime2-2026.10 \\
                        -profile local,conda

                # Run ESS pipeline with NCBI source and primer-based segment extraction:
                    nextflow run main.nf --pipeline_type ess \\
                        --ess.source ncbi \\
                        --ncbi.query 'trnL[Gene] AND Viridiplantae[Organism]' \\
                        --ess.fwd_primer 'GGGCAATCCTGAGCCAA' \\
                        --ess.rev_primer 'CCATTGAGTCTCTGCACCTATC' \\
                        --ess.db trnL \\
                        --ess.amp_seg trnLgh \\
                        --ess.iteration_schedule "[(0.7, 2)]" \\
                        --qiime_conda_env /path/to/rachis-qiime2-2026.10 \\
                        -profile local,conda

                # Run ESS pipeline with UNITE as source:
                    nextflow run main.nf --pipeline_type ess \\
                        --ess.source unite \\
                        --unite.version '2025-02-19' \\
                        --unite.taxon_group fungi \\
                        --unite.cluster_id dynamic \\
                        --unite.singletons false \\
                        --ess.fwd_primer CTTGGTCATTTAGAGGAAGTAA \\
                        --ess.rev_primer GCTGCGTTCTTCATCGATGC \\
                        --ess.extract_min_length 10 \\
                        --ess.extract_max_length 600 \\
                        --ess.iteration_schedule "[(0.7, 2)]" \\
                        --ess.train_classifier true \\
                        --qiime_conda_env /path/to/rachis-qiime2-2026.10 \\
                        -profile local,conda
                
                # Run ESS pipeline with SILVA as source:
                    nextflow run main.nf --pipeline_type ess \\
                        --ess.source silva \\
                        --ess.fwd_primer GTGYCAGCMGCCGCGGTAA \\
                        --ess.rev_primer GGACTACNVGGGTWTCTAAT \\
                        --ess.db silva \\
                        --ess.amp_seg 515F806R \\
                        --ess.iteration_schedule "[(0.7, 2), (0.8, 1)]" \\
                        --qiime_conda_env /path/to/rachis-qiime2-2026.10 \\
                        -profile local,conda
            ===================================================================
            """.stripIndent()
        exit 0
        }

        // --help (general)
        log.info """
        ===================================================================
        nf-refdb-amplicon v${workflow.manifest.version}
        Nextflow pipeline for generating reference databases
        for amplicon sequences using RESCRIPt 🧬
        ===================================================================

        Usage:
            nextflow run main.nf --pipeline_type <ssu|ess> -profile <local,conda|cluster,conda>

        Required:
            --pipeline_type         Pipeline to run: 'ssu' or 'ess'

        Conda (required with conda profile):
            --qiime_conda_env       Path to QIIME 2 conda environment or YAML file [default: ${params.qiime_conda_env ?: 'null'}]

        Output:
            --outdir                Output directory [default: ${params.outdir}]

        Dereplication/Culling Settings:
            --derep.mode            Dereplication mode: 'uniq' or 'abund' [default: ${params.derep.mode}]
            --cull.degen            Cull degenerate sequences [default: ${params.cull.degen}]
            --cull.hpoly            Cull homopolymer sequences [default: ${params.cull.hpoly}]

        Resource limits:
            --max_memory            Max memory per process [default: ${params.max_memory}]
            --max_cpus              Max CPUs per process [default: ${params.max_cpus}]
            --max_time              Max time per process [default: ${params.max_time}]

        Profiles (combine executor + engine):
            -profile local,docker       Run locally with Docker (recommended for macOS)
            -profile local,conda        Run locally with Conda
            -profile cluster,conda      Submit to SLURM HPC with Conda

        Workflow-specific help:
            --help ssu              Show SSU pipeline parameters
            --help ess              Show ESS pipeline parameters

        Other:
            --help                  Show this help message
            -resume                 Resume previous run from cache

        Examples:
            nextflow run main.nf --pipeline_type ssu -profile local,conda
            nextflow run main.nf --pipeline_type ess -profile cluster,conda

        Documentation:
            https://github.com/mikerobeson/nf-refdb-amplicon
        ===================================================================
        """.stripIndent()
    exit 0
    }

    // Validate pipeline type parameter
    if (!params.pipeline_type) {
        error '''
            ==========================================================
            ERROR: --pipeline_type is required.
            Valid options: "ssu" or "ess"

            Usage:
              nextflow run main.nf --pipeline_type ssu -profile local,conda
              nextflow run main.nf --pipeline_type ess -profile local,conda

            For help:
              nextflow run main.nf --help
              nextflow run main.nf --help ssu
              nextflow run main.nf --help ess
            ==========================================================
        '''.stripIndent()
    }

    // Run selected pipeline
    if (params.pipeline_type == 'ssu') {
        SSU()
    } else if (params.pipeline_type == 'ess') {
        ESS()
    } else {
        error """
            ==========================================================
            ERROR: --pipeline_type must be 'ssu' or 'ess'.
            Got: '${params.pipeline_type}'
            ==========================================================
        """.stripIndent()
    }
}

/*
========================================================================================
    THE END
========================================================================================
*/