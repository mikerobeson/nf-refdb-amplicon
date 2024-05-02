process GET_GTDB {

    conda "${params.qiime_conda_env}"
 
    tag 'Downloading GTDB data.'
    
    publishDir params.outdir, mode: 'copy'
 
    output:        
        tuple val('full_gtdb'), path('gtdb_seqs.qza'), path('gtdb_tax.qza'), emit: gtdb_data
   
    script:
        """
        qiime rescript  get-gtdb-data \
            --p-version '214.1' \
            --p-domain 'Both' \
            --p-db-type 'SpeciesReps' \
            --o-gtdb-sequences 'gtdb_seqs.qza' \
            --o-gtdb-taxonomy 'gtdb_tax.qza'
        """
}


process GTDB_DEREP {

    conda "${params.qiime_conda_env}"
    
    tag 'Dereplicating GTDB data.'
    
    publishDir params.outdir, mode: 'copy'
    
    input:
        tuple val(amp_reg), path(gtdb_seqs), path(gtdb_taxa)
    
    output:
        tuple val(amp_reg), path("${amp_reg}_derep_seqs.qza"), path("${amp_reg}_derep_taxa.qza"), emit: derep
    
    script:
        """
        qiime rescript dereplicate \
            --i-sequences ${gtdb_seqs} \
            --i-taxa ${gtdb_taxa} \
            --p-mode 'uniq' \
            --p-threads 1 \
            --o-dereplicated-sequences '${amp_reg}_derep_seqs.qza' \
            --o-dereplicated-taxa '${amp_reg}_derep_taxa.qza'
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

   input:
        tuple val(full_amp), path(gtdb_seqs), path(gtdb_taxa)
        tuple val(amp_region), val(fw_primer), val(rev_primer)
    
    output:
        tuple val(amp_region), path("${amp_region}_seqs.qza"), path(gtdb_taxa), emit: extract_amp
    
    script:
        """
        qiime feature-classifier extract-reads \
            --i-sequences ${gtdb_seqs} \
            --p-f-primer ${fw_primer} \
            --p-r-primer ${rev_primer} \
            --p-n-jobs 1 \
            --p-read-orientation 'forward' \
            --o-reads '${amp_region}_seqs.qza'
        """
}

process GTDB_TRAIN {
   conda "${params.qiime_conda_env}"
    
    tag 'Train GTDB classifier.'
    
    publishDir params.outdir, mode: 'copy'

    input:
        tuple val(amp_reg), path(gtdb_seqs), path(gtdb_taxa)
        
    output:
        tuple val(amp_reg), path("${amp_reg}_classifier.qza"), emit: classifier
        
    script:
        """
        qiime feature-classifier fit-classifier-naive-bayes \
            --i-reference-reads '${gtdb_seqs}' \
            --i-reference-taxonomy '${gtdb_taxa}' \
            --o-classifier '${amp_reg}_classifier.qza'
        """

}