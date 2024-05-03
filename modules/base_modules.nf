

process DEREP {

    conda "${params.qiime_conda_env}"
    
    tag 'Dereplicating data.'
    
    publishDir params.outdir, mode: 'copy'
    
    cpus "${params.derep.threads}"

    input:
        tuple val(db), val(amp_reg), path(gtdb_seqs) 
        tuple val(db), val(amp_reg_tax), path(gtdb_taxa)
        /*
        * We assign `amp_reg_tax` as this can be different to `amp_reg`,
        * when we need the full taxonomy for dereplication the amplicon seqs.
        * That is `amp_reg` and `amp_reg_tax` will not be the same in this case.
        * Also meaning if we use `amp_reg` for both the latter will overwrite the
        * variable messing up the outfile names and the pipeline.
        */

    output:
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_derep_seqs.qza"), emit: derep_seqs
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_derep_taxa.qza"), emit: derep_taxa
    
    script:
        """
        qiime rescript dereplicate \
            --i-sequences ${gtdb_seqs} \
            --i-taxa ${gtdb_taxa} \
            --p-mode ${params.derep.mode} \
            --p-threads ${params.derep.threads} \
            --o-dereplicated-sequences '${db}_${amp_reg}_derep_seqs.qza' \
            --o-dereplicated-taxa '${db}_${amp_reg}_derep_taxa.qza'
    """
}



process AMP_REG_EXTRACT {

    conda "${params.qiime_conda_env}"
    
    tag 'Extracting amplicon region with primers.'
    
    publishDir params.outdir, mode: 'copy'

    cpus "${params.amp_extract.jobs}"

    input:
        tuple val(db), val(full_amp), path(gtdb_seqs)
        tuple val(amp_region), val(fw_primer), val(rev_primer)
    
    output:
        tuple val(db), val(amp_region), path("${db}_${amp_region}_seqs.qza"), emit: extract_amp
    
    script:
        """
        qiime feature-classifier extract-reads \
            --i-sequences ${gtdb_seqs} \
            --p-f-primer ${fw_primer} \
            --p-r-primer ${rev_primer} \
            --p-n-jobs ${params.amp_extract.jobs} \
            --p-read-orientation 'forward' \
            --o-reads '${db}_${amp_region}_seqs.qza'
        """
}

process TRAIN_CLASSIFIER {
   conda "${params.qiime_conda_env}"
    
    tag 'Train classifier.'
    
    publishDir params.outdir, mode: 'copy'

    cpus 1

    input:
        tuple val(db), val(amp_reg), path(gtdb_seqs)
        tuple val(db), val(amp_reg), path(gtdb_taxa)
        
    output:
        tuple val(amp_reg), path("${db}_${amp_reg}_classifier.qza"), emit: classifier
        
    script:
        """
        qiime feature-classifier fit-classifier-naive-bayes \
            --i-reference-reads '${gtdb_seqs}' \
            --i-reference-taxonomy '${gtdb_taxa}' \
            --o-classifier '${db}_${amp_reg}_classifier.qza'
        """

}