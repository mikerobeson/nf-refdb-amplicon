

process DEREP {
  
    tag 'Dereplicating data.'
    
    label 'derep'

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
            --p-threads ${task.cpus} \
            --o-dereplicated-sequences '${db}_${amp_reg}_derep_seqs.qza' \
            --o-dereplicated-taxa '${db}_${amp_reg}_derep_taxa.qza'
        """
}

process AMP_REG_EXTRACT {
    
    tag 'Extracting amplicon region with primers.'

    label 'amp_reg_extract'

    input:
        tuple val(db), val(full_amp), path(seqs)
        tuple val(amp_reg), val(fw_primer), val(rev_primer)
    
    output:
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_seqs.qza"), emit: extract_amp
    
    script:
        """
        qiime feature-classifier extract-reads \
            --i-sequences ${seqs} \
            --p-f-primer ${fw_primer} \
            --p-r-primer ${rev_primer} \
            --p-n-jobs ${task.cpus} \
            --p-read-orientation 'forward' \
            --o-reads '${db}_${amp_reg}_seqs.qza'
        """
}

process CULL {

    tag 'Culling sequences.'
    
    label 'cull'
    
    input:
        tuple val(db), val(amp_reg), path(seqs)
    
    output:
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_culled_seqs.qza"), emit: culled_seqs

    script:
        """
        qiime rescript cull-seqs \
            --i-sequences ${seqs}  \
            --p-n-jobs ${task.cpus} \
            --p-num-degenerates ${params.cull.degen} \
            --p-homopolymer-length ${params.cull.hpoly} \
            --o-clean-sequences '${db}_${amp_reg}_culled_seqs.qza' \
            --verbose
        """

}

process TRAIN_CLASSIFIER {
    
    tag 'Train classifier.'

    label 'train_classifier'

    input:
        tuple val(db), val(amp_reg), path(seqs)
        tuple val(db), val(amp_reg), path(taxa)
        
    output:
        tuple val(amp_reg), path("${db}_${amp_reg}_classifier.qza"), emit: classifier
        
    script:
        """
        qiime feature-classifier fit-classifier-naive-bayes \
            --i-reference-reads ${seqs} \
            --i-reference-taxonomy ${taxa} \
            --o-classifier '${db}_${amp_reg}_classifier.qza'
        """

}