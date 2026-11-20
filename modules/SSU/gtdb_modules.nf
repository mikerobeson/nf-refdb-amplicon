/*
----------------------------------------------------------------------------------------
    GTDB DATABASE MODULE

    Download and prepare GTDB SSU rRNA gene reference database
----------------------------------------------------------------------------------------
*/

process GET_GTDB {

    tag "Downloading GTDB ${params.gtdb?.version ?: '232.0'}"
    label 'get_gtdb'

    output:
    tuple val('gtdb'), val('full'), path('gtdb_seqs.qza'), emit: gtdb_seqs
    tuple val('gtdb'), val('full'), path('gtdb_taxa.qza'), emit: gtdb_taxa
    path "versions.yml",                                    emit: versions

    script:
    def version = params.gtdb.version ?: '232.0'
    def domain  = params.gtdb.domain  ?: 'Both'
    def dbtype  = params.gtdb.dbtype  ?: 'SpeciesReps'
    """
    qiime rescript get-gtdb-data \\
        --p-version '${version}' \\
        --p-domain '${domain}' \\
        --p-db-type '${dbtype}' \\
        --o-gtdb-sequences gtdb_seqs.qza \\
        --o-gtdb-taxonomy gtdb_taxa.qza \\
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    """
    touch gtdb_seqs.qza
    touch gtdb_taxa.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: "stub"
        rescript: "stub"
    END_VERSIONS
    """
}