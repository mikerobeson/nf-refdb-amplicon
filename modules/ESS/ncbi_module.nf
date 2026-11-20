/*
----------------------------------------------------------------------------------------
    ESS_GET_NCBI_DATA

    Downloads NCBI reference sequences and taxonomy data
 ----------------------------------------------------------------------------------------
 */

process ESS_GET_NCBI_DATA {

    tag "Downloading from NCBI"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    output:
    path "ncbi_sequences.qza", emit: seqs
    path "ncbi_taxonomy.qza",  emit: taxa
    path "versions.yml",       emit: versions

    script:
    def query            = params.ncbi.query
    def ranks            = params.ncbi.ranks            ?: 'kingdom phylum class order family genus species'
    def rank_propagation = (params.ncbi.rank_propagation != false) ? '' : '--p-no-rank-propagation'
    def n_jobs           = task.cpus
    """
    qiime rescript get-ncbi-data \\
        --p-query '${query}' \\
        --p-ranks ${ranks} \\
        ${rank_propagation} \\
        --p-n-jobs ${n_jobs} \\
        --o-sequences ncbi_sequences.qza \\
        --o-taxonomy ncbi_taxonomy.qza \\
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    """
    touch ncbi_sequences.qza
    touch ncbi_taxonomy.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: "stub"
        rescript: "stub"
    END_VERSIONS
    """
}