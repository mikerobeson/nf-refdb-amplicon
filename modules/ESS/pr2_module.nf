/*
----------------------------------------------------------------------------------------
    ESS_GET_PR2_DATA

    Downloads Protist Ribosomal reference sequences and taxonomy data
 ----------------------------------------------------------------------------------------
 */

process ESS_GET_PR2_DATA {

    tag "Downloading PR2 ${params.pr2?.version ?: '5.1.1'}"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    output:
    path "pr2_sequences.qza", emit: seqs
    path "pr2_taxonomy.qza",  emit: taxa
    path "versions.yml",      emit: versions

    script:
    def version = params.pr2.version ?: '5.1.1'
    def ranks   = params.pr2.ranks   ?: 'domain supergroup division subdivision class order family genus species'
    """
    qiime rescript get-pr2-data \\
        --p-version '${version}' \\
        --p-ranks ${ranks} \\
        --o-pr2-sequences pr2_sequences.qza \\
        --o-pr2-taxonomy pr2_taxonomy.qza \\
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    """
    touch pr2_sequences.qza
    touch pr2_taxonomy.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: "stub"
        rescript: "stub"
    END_VERSIONS
    """
}