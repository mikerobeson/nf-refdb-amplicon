

// add `$task.index` to the ouput and script commands.
// see: https://github.com/nextflow-io/nextflow/discussions/2521
// https://github.com/nextflow-io/nextflow/discussions/5297
// https://nextflow-io.github.io/patterns/feedback-loop/

process ESS_EXTRACTSEQSEGS {

    tag 'Extracting sequence segments'

    label 'ess_extseqsegs'

    input:
        tuple val(db), val(amp_reg), path(seqs)
        tuple val(db), val(amp_seg), path(refseqsegs)
        val(id)
        // tuple val(amp_region), val(fw_primer), val(rev_primer)
        // change amp_reg to amp_seg for output?

    output:
        tuple val(db), val(amp_reg), path("${db}_${amp_seg}_matched_extseqsegs_seqs_*.qza"), emit: matched_extracted_seqs
        tuple val(db), val(amp_reg), path("${db}_${amp_seg}_unmatched_extseqsegs_seqs_*.qza"), emit: unmatched_extracted_seqs

    script:
        """
        echo "Running iteration: ${task.index} ..."

        qiime rescript extract-seq-segments \
            --i-input-sequences ${seqs} \
            --i-reference-segment-sequences ${refseqsegs} \
            --p-perc-identity ${id} \
            --p-min-seq-len 20 \
            --p-threads ${task.cpus} \
            --o-extracted-sequence-segments '${db}_${amp_seg}_matched_extseqsegs_seqs_${task.index}.qza' \
            --o-unmatched-sequences '${db}_${amp_seg}_unmatched_extseqsegs_seqs_${task.index}.qza' \
            --verbose
        """
}

process ESS_DEREP {
  
    tag 'Dereplicating data.'
    
    label 'derep'
    label 'ess_derep'

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
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_derep_seqs_*.qza"), emit: derep_seqs
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_derep_taxa_*.qza"), emit: derep_taxa
    
    script:
        """
        qiime rescript dereplicate \
            --i-sequences ${seqs} \
            --i-taxa ${taxa} \
            --p-mode uniq \
            --p-threads ${task.cpus} \
            --o-dereplicated-sequences '${db}_${amp_reg}_derep_seqs_${task.index}.qza' \
            --o-dereplicated-taxa '${db}_${amp_reg}_derep_taxa_${task.index}.qza'
        """
}

process ESS_CULL {

    tag 'Culling sequences.'
    
    label 'cull'
    label 'ess_cull'
    
    input:
        tuple val(db), val(amp_reg), path(seqs)
    
    output:
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_culled_seqs_*.qza"), emit: culled_seqs

    script:
        """
        qiime rescript cull-seqs \
            --i-sequences ${seqs}  \
            --p-n-jobs ${task.cpus} \
            --p-num-degenerates ${params.cull.degen} \
            --p-homopolymer-length ${params.cull.hpoly} \
            --o-clean-sequences '${db}_${amp_reg}_culled_seqs_${task.index}.qza' \
            --verbose
        """

}

process ESS_TABSEQS {

    tag 'Tabulating sequences.'

    label 'tabseqs'
    label 'ess_tabseqs'

    input:
        tuple val(db), val(amp_reg), path(seqs)

    output:
        tuple val(db), val(amp_reg), path("${db}_${amp_reg}_culled_seqs_*.qzv"), emit: tab_seqs

    script:
        """
        qiime feature-table tabulate-seqs \
          --i-data ${seqs} \
          --o-visualization '${db}_${amp_reg}_culled_seqs_${task.index}.qzv'
        """

}

process ESS_TRAIN_CLASSIFIER {
    
    tag 'Train classifier.'

    label 'train_classifier'
    label 'ess_train_classifier'

    input:
        tuple val(db), val(amp_reg), path(seqs)
        tuple val(db), val(amp_reg), path(taxa)
        // val (params.iter)

        
    output:
        tuple val(amp_reg), path("${db}_${amp_reg}_classifier_*.qza"), emit: classifier
        
    script:
        """
        qiime feature-classifier fit-classifier-naive-bayes \
            --i-reference-reads ${seqs} \
            --i-reference-taxonomy ${taxa} \
            --o-classifier '${db}_${amp_reg}_classifier_${params.iter}.qza'
        """

}