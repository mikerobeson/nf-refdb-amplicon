/*
----------------------------------------------------------------------------------------
    ESS_GET_UNITE_DATA

    Downloads UNITE fungal ITS reference sequences and taxonomy data
 ----------------------------------------------------------------------------------------
 */

process ESS_GET_UNITE_DATA {

    tag "Downloading UNITE ${params.unite?.version ?: '2025-02-19'}"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    output:
    path "unite_sequences.qza", emit: seqs
    path "unite_taxonomy.qza",  emit: taxa
    path "versions.yml",        emit: versions

    script:
    def version        = params.unite.version       ?: '2025-02-19'
    def taxon_group    = params.unite.taxon_group   ?: 'eukaryotes'
    def cluster_id     = params.unite.cluster_id    ?: '99'
    def singleton_flag = (params.unite.singletons ?: false).toString().toBoolean() ? '--p-singletons' : '--p-no-singletons'
    """
    qiime rescript get-unite-data \\
        --p-version '${version}' \\
        --p-taxon-group '${taxon_group}' \\
        --p-cluster-id '${cluster_id}' \\
        ${singleton_flag} \\
        --o-sequences unite_sequences.qza \\
        --o-taxonomy unite_taxonomy.qza \\
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    """
    touch unite_sequences.qza
    touch unite_taxonomy.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: "stub"
        rescript: "stub"
    END_VERSIONS
    """
}