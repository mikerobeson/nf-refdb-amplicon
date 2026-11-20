/*
========================================================================================
    ESS SUBWORKFLOW
========================================================================================
*/

include { ESS_GET_NCBI_DATA    } from '../../modules/ESS/ncbi_module.nf'
include { ESS_GET_UNITE_DATA   } from '../../modules/ESS/unite_module.nf'
include { ESS_GET_MIDORI2_DATA } from '../../modules/ESS/midor2_module.nf'
include { ESS_EXTRACT_FROM_COLLECTION } from '../../modules/ESS/extract_collect_module.nf'
include { ESS_GET_PR2_DATA     } from '../../modules/ESS/pr2_module.nf'
include { GET_SILVA as ESS_GET_SILVA_DATA           } from '../../modules/SSU/silva_modules.nf'
include { GET_GTDB  as ESS_GET_GTDB_DATA            } from '../../modules/SSU/gtdb_modules.nf'
include { GET_RDP   as ESS_GET_RDP_DATA; IMPORT_RDP as ESS_IMPORT_RDP } from '../../modules/SSU/rdp_modules.nf'
include { DEREP as ESS_DEREP   } from '../../modules/SSU/base_modules.nf'
include { ESS_EXTRACT_READS    } from '../../modules/ESS/extract_seqsegs_module.nf'
include { ESS_SETUP            } from '../../modules/ESS/iterate_modules.nf'
include { ESS_ITERATE          } from '../../modules/ESS/iterate_modules.nf'
include { ESS_TRAIN_CLASSIFIER } from '../../modules/ESS/train_classifier_module.nf'

/*
 * Build the per-iteration percent-identity schedule.
 *
 * `params.ess.iteration_schedule` may be:
 *   - a Groovy list (config)    -> [[0.7, 2], [0.8, 2], [0.9, 1]]
 *   - a string (command line)   -> "[(0.7, 2), (0.8, 2), (0.9, 1)]" or "0.7:2,0.8:2,0.9:1"
 *
 * Each pair is (percent identity, number of iterations at that identity).
 * Returns a flat list with one identity (as a string) per iteration,
 * e.g. ['0.7', '0.7', '0.8', '0.8', '0.9'].
 */
def buildIdentitySchedule(schedule) {
    if (!schedule) {
        error "ERROR: --ess.iteration_schedule is required, e.g. \"[(0.7, 2), (0.8, 2), (0.9, 1)]\""
    }

    // Works for both List and String input: pull out every number, then pair them up
    def nums = schedule.toString().findAll(/\d*\.?\d+/)
    if (nums.isEmpty() || nums.size() % 2 != 0) {
        error "ERROR: --ess.iteration_schedule must contain (identity, iterations) pairs. Got: '${schedule}'"
    }

    def pairs = nums.collate(2)
    pairs.each { pair ->
        def ident = pair[0] as BigDecimal
        def iters = pair[1]
        if (ident <= 0 || ident > 1) {
            error "ERROR: --ess.iteration_schedule identity must be in (0, 1]. Got ${pair[0]} in '${schedule}'"
        }
        if (!(iters ==~ /\d+/) || (iters as Integer) < 1) {
            error "ERROR: --ess.iteration_schedule iteration count must be a positive integer. Got ${iters} in '${schedule}'"
        }
    }

    return pairs.collectMany { pair ->
        (1..(pair[1] as Integer)).collect { _i -> pair[0] }
    }
}

workflow ESS {

    main:

    // ======================================================================
    // Obtain input data based on source
    // ======================================================================

    if (params.ess.source == 'custom') {
        // User provides their own files
        if (!params.ess.seqs || !params.ess.taxa) {
            error """
                ==========================================================
                ERROR: --ess.seqs and --ess.taxa are required when
                --ess.source is 'custom'.

                Usage:
                  nextflow run main.nf --pipeline_type ess \\
                      --ess.source custom \\
                      --ess.seqs /path/to/sequences.qza \\
                      --ess.taxa /path/to/taxonomy.qza \\
                      -profile local,docker

                For help:
                  nextflow run main.nf --help ess
                ==========================================================
            """.stripIndent()
        }
        ch_ref_seqs = channel.fromPath(params.ess.seqs, checkIfExists: true)
        ch_ref_taxa = channel.fromPath(params.ess.taxa, checkIfExists: true)

    } else if (params.ess.source == 'ncbi') {
        if (!params.ess.ncbi_query) {
            error """
                ==========================================================
                ERROR: --ess.ncbi_query is required when --ess.source is 'ncbi'.

                Example:
                  nextflow run main.nf --pipeline_type ess \\
                      --ess.source ncbi \\
                      --ess.ncbi_query '"txid35493"[ORGN] AND "trnL"[Gene]' \\
                      -profile local,conda
                ==========================================================
            """.stripIndent()
        }
        ESS_GET_NCBI_DATA()
        ch_ref_seqs = ESS_GET_NCBI_DATA.out.seqs
        ch_ref_taxa = ESS_GET_NCBI_DATA.out.taxa

    } else if (params.ess.source == 'unite') {
        ESS_GET_UNITE_DATA()
        ch_ref_seqs = ESS_GET_UNITE_DATA.out.seqs
        ch_ref_taxa = ESS_GET_UNITE_DATA.out.taxa

    } else if (params.ess.source == 'midori2') {
        ESS_GET_MIDORI2_DATA(params.ess.midori2_target_gene)

        ESS_EXTRACT_FROM_COLLECTION(
            ESS_GET_MIDORI2_DATA.out.sequences_collection,
            ESS_GET_MIDORI2_DATA.out.taxonomy_collection,
            params.ess.midori2_target_gene
        )

        ch_ref_seqs = ESS_EXTRACT_FROM_COLLECTION.out.sequences
        ch_ref_taxa = ESS_EXTRACT_FROM_COLLECTION.out.taxonomy

    } else if (params.ess.source == 'pr2') {
        ESS_GET_PR2_DATA()
        ch_ref_seqs = ESS_GET_PR2_DATA.out.seqs
        ch_ref_taxa = ESS_GET_PR2_DATA.out.taxa

    } else if (params.ess.source == 'silva') {
        ESS_GET_SILVA_DATA()
        // Unwrap tuple: GET_SILVA emits tuple(db, amp_reg, path)
        ch_ref_seqs = ESS_GET_SILVA_DATA.out.silva_seqs.map { _db, _amp_reg, seqs -> seqs }
        ch_ref_taxa = ESS_GET_SILVA_DATA.out.silva_taxa.map { _db, _amp_reg, taxa -> taxa }

    } else if (params.ess.source == 'gtdb') {
        ESS_GET_GTDB_DATA()
        // Unwrap tuple: GET_GTDB emits tuple(db, amp_reg, path)
        ch_ref_seqs = ESS_GET_GTDB_DATA.out.gtdb_seqs.map { _db, _amp_reg, seqs -> seqs }
        ch_ref_taxa = ESS_GET_GTDB_DATA.out.gtdb_taxa.map { _db, _amp_reg, taxa -> taxa }

    } else if (params.ess.source == 'rdp') {
        ESS_GET_RDP_DATA()
        ESS_IMPORT_RDP(ESS_GET_RDP_DATA.out.rdp_fasta, ESS_GET_RDP_DATA.out.rdp_tax_tsv)
        // Unwrap tuple: IMPORT_RDP emits tuple(db, amp_reg, path)
        ch_ref_seqs = ESS_IMPORT_RDP.out.rdp_seqs.map { _db, _amp_reg, seqs -> seqs }
        ch_ref_taxa = ESS_IMPORT_RDP.out.rdp_taxa.map { _db, _amp_reg, taxa -> taxa }

    } else {
        error """
            ==========================================================
            ERROR: --ess.source must be one of: custom, ncbi, unite,
            midori2, pr2, silva, gtdb, rdp
            Got: '${params.ess.source}'
            ==========================================================
        """.stripIndent()
    }

    // ======================================================================
    // Dereplicate acquired reference sequences
    // ======================================================================

    // Wrap flat ESS channels into the tuple format that DEREP expects: tuple(db, amp_reg, path)
    ch_derep_seqs_in = ch_ref_seqs.map { seqs ->
        tuple(params.ess.db, 'full', seqs)
    }

    ch_derep_taxa_in = ch_ref_taxa.map { taxa ->
        tuple(params.ess.db, 'full', taxa)
    }

    ESS_DEREP(ch_derep_seqs_in, ch_derep_taxa_in)

    // Unwrap the tupled DEREP outputs back to flat paths for downstream ESS processes that expect plain path channels.
    // This adaptor will be redesigned/changed once ESS processes are updated to accept tupled channels.
    ch_derep_seqs = ESS_DEREP.out.derep_seqs.map { _db, _amp_reg, seqs -> seqs }
    ch_derep_taxa = ESS_DEREP.out.derep_taxa.map { _db, _amp_reg, taxa -> taxa }

    // ======================================================================
    // Handle sequence segments
    // ======================================================================

    if (params.ess.seqsegs) {
        // User provided pre-existing segment sequences
        ch_seqsegs = channel.fromPath(params.ess.seqsegs, checkIfExists: true)

    } else if (params.ess.fwd_primer && params.ess.rev_primer) {
        // Generate initial segments via primer extraction from downloaded data
        ESS_EXTRACT_READS(ch_derep_seqs)
        ch_seqsegs = ESS_EXTRACT_READS.out.seqsegs

    } else {
        error """
            ==========================================================
            ERROR: Either --ess.seqsegs must be provided, OR both
            --ess.fwd_primer and --ess.rev_primer must be specified
            to generate initial segments via primer extraction.

            Usage:
              # Provide pre-existing segments:
              nextflow run main.nf --pipeline_type ess \\
                  --ess.seqsegs /path/to/segments.qza ...

              # Or provide primers for automatic extraction:
              nextflow run main.nf --pipeline_type ess \\
                  --ess.fwd_primer GGGCAATCCTGAGCCAA \\
                  --ess.rev_primer CCATTGAGTCTCTGCACCTATC ...
            ==========================================================
        """.stripIndent()
    }

    // ======================================================================
    // Seed the ESS iteration loop
    // ======================================================================

    ESS_SETUP(ch_seqsegs, ch_derep_seqs, ch_derep_taxa)

    // ======================================================================
    // Iterative ESS loop via topic channel
    // ======================================================================

    def parser = new groovy.json.JsonSlurper()

    // One percent-identity value per iteration; its length is the total iteration count
    def identity_schedule = buildIdentitySchedule(params.ess.iteration_schedule)
    def total_iters = identity_schedule.size()

    log.info "ESS: ${total_iters} iteration(s), perc-identity per iteration: ${identity_schedule.join(', ')}"

    updates = channel.topic('ess_iteration')
    limit = updates.until { path ->
        parser.parseText(path.text).step >= total_iters
    }

    ESS_ITERATE(updates, limit, channel.value(identity_schedule.join(',')))

    // ======================================================================
    // Train classifier on final output
    // ======================================================================

    if (params.ess.train_classifier.toString().toBoolean()) {
        ESS_TRAIN_CLASSIFIER(
            ESS_ITERATE.out.culled_seqs.last(),
            ESS_ITERATE.out.derep_taxa.last()
        )
    }

    emit:
    culled_seqs = ESS_ITERATE.out.culled_seqs
    derep_taxa  = ESS_ITERATE.out.derep_taxa
}