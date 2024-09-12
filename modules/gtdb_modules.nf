process GET_GTDB {

    conda "${params.qiime_conda_env}"
 
    tag 'Downloading GTDB data.'
 
    cpus 1
    memory "${params.get_gtdb.memory}"


    output:        
       tuple val('gtdb'), val('full'), path('gtdb_seqs.qza'), emit: gtdb_seqs
       tuple val('gtdb'), val('full'), path('gtdb_taxa.qza'), emit: gtdb_taxa
       
    script:
        """
        qiime rescript  get-gtdb-data \
            --p-version ${params.get_gtdb.version} \
            --p-domain ${params.get_gtdb.domain} \
            --p-db-type ${params.get_gtdb.dbtype} \
            --o-gtdb-sequences 'gtdb_seqs.qza' \
            --o-gtdb-taxonomy 'gtdb_taxa.qza'
        """
}
