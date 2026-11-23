/*
========================================================================================
    SSU SUBWORKFLOW
========================================================================================
    Build Naive Bayes classifiers from SSU rRNA gene reference databases.

    Supports three databases:
        - SILVA  : Comprehensive ribosomal RNA database
        - GTDB   : Genome Taxonomy Database SSU sequences
        - RDP    : Ribosomal Database Project training set

    Users select which databases to build via params.ssu_databases.
    For each selected database, the pipeline:
        1. Downloads/imports the reference data
        2. Dereplicates and culls sequences
        3. Optionally trains a full-length classifier
        4. Optionally extracts amplicon regions and trains region-specific classifiers

    Configuration: conf/ssu.config
----------------------------------------------------------------------------------------
*/

include { GET_SILVA            } from '../../modules/SSU/silva_modules.nf'
include { GET_GTDB             } from '../../modules/SSU/gtdb_modules.nf'
include { GET_RDP; IMPORT_RDP  } from '../../modules/SSU/rdp_modules.nf'

include { CURATE_AND_TRAIN as CURATE_AND_TRAIN_SILVA } from './curate_and_train.nf'
include { CURATE_AND_TRAIN as CURATE_AND_TRAIN_GTDB  } from './curate_and_train.nf'
include { CURATE_AND_TRAIN as CURATE_AND_TRAIN_RDP   } from './curate_and_train.nf'

/*
----------------------------------------------------------------------------------------
    WORKFLOW
----------------------------------------------------------------------------------------
*/

workflow SSU {

    main:

    // ==========================================================
    // SILVA
    // ==========================================================

    if (params.ssu.databases.toString().contains('silva')) {
        GET_SILVA()
        CURATE_AND_TRAIN_SILVA(
            GET_SILVA.out.silva_seqs,
            GET_SILVA.out.silva_taxa,
            channel.fromList(params.primer_pairs)
        )
    }

    // ==========================================================
    // GTDB
    // ==========================================================

    if (params.ssu.databases.toString().contains('gtdb')) {
        GET_GTDB()
        CURATE_AND_TRAIN_GTDB(
            GET_GTDB.out.gtdb_seqs,
            GET_GTDB.out.gtdb_taxa,
            channel.fromList(params.primer_pairs)
        )
    }

    // ==========================================================
    // RDP
    // ==========================================================

    if (params.ssu.databases.toString().contains('rdp')) {
        GET_RDP()
        IMPORT_RDP(GET_RDP.out.rdp_fasta, GET_RDP.out.rdp_tax_tsv)
        CURATE_AND_TRAIN_RDP(
            IMPORT_RDP.out.rdp_seqs,
            IMPORT_RDP.out.rdp_taxa,
            channel.fromList(params.primer_pairs)
        )
    }
}

/*
========================================================================================
    THE END
========================================================================================
*/