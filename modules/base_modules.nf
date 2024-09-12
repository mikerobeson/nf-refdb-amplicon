

process DEREP {

    conda "${params.qiime_conda_env}"
    
    tag 'Dereplicating data.'
    
    cpus "${params.derep.threads}"
    memory "${params.derep.memory}"

    input:
        tuple val(db), val(amp_reg), path(seqs) 
        tuple val(db), val(amp_reg_tax), path(taxa)
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
            --i-sequences ${seqs} \
            --i-taxa ${taxa} \
            --p-mode ${params.derep.mode} \
            --p-threads ${params.derep.threads} \
            --o-dereplicated-sequences '${db}_${amp_reg}_derep_seqs.qza' \
            --o-dereplicated-taxa '${db}_${amp_reg}_derep_taxa.qza'
        """
}



process AMP_REG_EXTRACT {

    conda "${params.qiime_conda_env}"
    
    tag 'Extracting amplicon region with primers.'

    cpus "${params.amp_extract.jobs}"
    memory "${params.amp_extract.memory}"

    input:
        tuple val(db), val(full_amp), path(seqs)
        tuple val(amp_region), val(fw_primer), val(rev_primer)
    
    output:
        tuple val(db), val(amp_region), path("${db}_${amp_region}_seqs.qza"), emit: extract_amp
    
    script:
        """
        qiime feature-classifier extract-reads \
            --i-sequences ${seqs} \
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

    cpus "${params.train.cpus}"
    memory "${params.train.memory}"

    input:
        tuple val(db), val(amp_reg), path(seqs)
        tuple val(db), val(amp_reg), path(taxa)
        
    output:
        tuple val(amp_reg), path("${db}_${amp_reg}_classifier.qza"), emit: classifier
        
    script:
        """
        qiime feature-classifier fit-classifier-naive-bayes \
            --i-reference-reads '${seqs}' \
            --i-reference-taxonomy '${taxa}' \
            --o-classifier '${db}_${amp_reg}_classifier.qza'
        """

}