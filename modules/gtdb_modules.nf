process GET_GTDB {

    conda "${params.qiime_conda_env}"
 
    tag 'Downloading GTDB data.'
    
    publishDir params.outdir, mode: 'copy'
 
    cpus 1

    output:        
       tuple val('full'), path('gtdb_seqs.qza'), emit: gtdb_seqs
       tuple val('full'), path('gtdb_taxa.qza'), emit: gtdb_taxa
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


process GTDB_DEREP {

    conda "${params.qiime_conda_env}"
    
    tag 'Dereplicating GTDB data.'
    
    publishDir params.outdir, mode: 'copy'
    
    cpus "${params.derep.threads}"

    input:
        tuple val(amp_reg), path(gtdb_seqs) 
        tuple val(amp_reg_tax), path(gtdb_taxa)
        /*
        * We assign `amp_reg_tax` as this can be different to `amp_reg`,
        * when we need the full taxonomy for dereplication the amplicon seqs.
        * That is `amp_reg` and `amp_reg_tax` will not be the same in this case.
        * Also meaning if we use `amp_reg` for both the latter will overwrite the
        * variable messing up the outfile names and the pipeline.
        */

    output:
        tuple val(amp_reg), path("gtdb_${amp_reg}_derep_seqs.qza"), emit: derep_seqs
        tuple val(amp_reg), path("gtdb_${amp_reg}_derep_taxa.qza"), emit: derep_taxa
    
    script:
        """
        qiime rescript dereplicate \
            --i-sequences ${gtdb_seqs} \
            --i-taxa ${gtdb_taxa} \
            --p-mode ${params.derep.mode} \
            --p-threads ${params.derep.threads} \
            --o-dereplicated-sequences 'gtdb_${amp_reg}_derep_seqs.qza' \
            --o-dereplicated-taxa 'gtdb_${amp_reg}_derep_taxa.qza'
    """
}



process GTDB_AMP_REG_EXTRACT {

/*
* Note: we return the taxonomy as part of "output" so that we can easily pass the
* extracted sequences to 'GTDB_DEREP', which requires a taxonomy file.
*/

    conda "${params.qiime_conda_env}"
    
    tag 'Extracting amplicon region from GTDB data.'
    
    publishDir params.outdir, mode: 'copy'

    cpus "${params.amp_extract.jobs}"

    input:
        tuple val(full_amp), path(gtdb_seqs)
        tuple val(amp_region), val(fw_primer), val(rev_primer)
    
    output:
        tuple val(amp_region), path("gtdb_${amp_region}_seqs.qza"), emit: extract_amp
    
    script:
        """
        qiime feature-classifier extract-reads \
            --i-sequences ${gtdb_seqs} \
            --p-f-primer ${fw_primer} \
            --p-r-primer ${rev_primer} \
            --p-n-jobs ${params.amp_extract.jobs} \
            --p-read-orientation 'forward' \
            --o-reads 'gtdb_${amp_region}_seqs.qza'
        """
}

process GTDB_TRAIN {
   conda "${params.qiime_conda_env}"
    
    tag 'Train GTDB classifier.'
    
    publishDir params.outdir, mode: 'copy'

    cpus 1

    input:
        tuple val(amp_reg), path(gtdb_seqs)
        tuple val(amp_reg), path(gtdb_taxa)
        
    output:
        tuple val(amp_reg), path("gtdb_${amp_reg}_classifier.qza"), emit: classifier
        
    script:
        """
        qiime feature-classifier fit-classifier-naive-bayes \
            --i-reference-reads '${gtdb_seqs}' \
            --i-reference-taxonomy '${gtdb_taxa}' \
            --o-classifier 'gtdb_${amp_reg}_classifier.qza'
        """

}