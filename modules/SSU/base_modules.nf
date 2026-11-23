/*
----------------------------------------------------------------------------------------
    BASE MODULES

    Main processes for SSU pipeline - Dereplication, Culling, Extraction, Training
----------------------------------------------------------------------------------------
*/

/*
----------------------------------------------------------------------------------------
    DEREPLICATE

    Dereplicate sequences with matching taxonomies.
    Removes redundant sequences based on the specified mode.

    Note: We use separate `amp_reg` and `amp_reg_tax` variables because
    the taxonomy source can differ from the sequence source. For example,
    when dereplicating amplicon-extracted sequences, we still use the
    full-length taxonomy. Using the same variable name for both would
    cause the latter to overwrite the former, breaking output filenames.
----------------------------------------------------------------------------------------
*/

process DEREP {

    tag "${db} ${amp_reg}"
    label 'derep'

    input:
    tuple val(db), val(amp_reg), path(seqs)
    tuple val(db_tax), val(amp_reg_tax), path(taxa)

    output:
    tuple val(db), val(amp_reg), path("${db}_${amp_reg}_derep_seqs.qza"), emit: derep_seqs
    tuple val(db), val(amp_reg), path("${db}_${amp_reg}_derep_taxa.qza"), emit: derep_taxa
    path "versions.yml", emit: versions

    script:
    """
    qiime rescript dereplicate \
        --i-sequences ${seqs} \
        --i-taxa ${taxa} \
        --p-mode ${params.derep.mode} \
        --p-threads ${task.cpus} \
        --o-dereplicated-sequences '${db}_${amp_reg}_derep_seqs.qza' \
        --o-dereplicated-taxa '${db}_${amp_reg}_derep_taxa.qza'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}



/*
----------------------------------------------------------------------------------------
    AMPLICON REGION EXTRACTION

    Extract amplicon region from full-length sequences using primer pairs.
    Uses in-silico PCR to identify and extract the target region.
----------------------------------------------------------------------------------------
*/

process AMP_REG_EXTRACT {

    tag "${db} ${amp_reg}"
    label 'amp_reg_extract'

    input:
    tuple val(db), val(full_amp), path(seqs)
    tuple val(amp_reg), val(fw_primer), val(rev_primer)

    output:
    tuple val(db), val(amp_reg), path("${db}_${amp_reg}_seqs.qza"), emit: extract_amp
    path "versions.yml", emit: versions

    script:
    """
    qiime feature-classifier extract-reads \
        --i-sequences ${seqs} \
        --p-f-primer ${fw_primer} \
        --p-r-primer ${rev_primer} \
        --p-n-jobs ${task.cpus} \
        --p-read-orientation 'forward' \
        --o-reads '${db}_${amp_reg}_seqs.qza' \
        --o-read-extraction-stats '${db}_${amp_reg}_extract_stats.qza'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        q2-feature-classifier: \$(pip show q2-feature-classifier 2>/dev/null | grep -i version | sed 's/Version: //')
    END_VERSIONS
    """
}




/*
----------------------------------------------------------------------------------------
    CULL SEQUENCES

    Remove sequences that contain excessive degenerate bases or
    homopolymer runs. Helps clean up problematic reference sequences.
----------------------------------------------------------------------------------------
*/

process CULL {

    tag "${db} ${amp_reg}"
    label 'cull'

    input:
    tuple val(db), val(amp_reg), path(seqs)

    output:
    tuple val(db), val(amp_reg), path("${db}_${amp_reg}_culled_seqs.qza"), emit: culled_seqs
    path "versions.yml", emit: versions

    script:
    """
    qiime rescript cull-seqs \
        --i-sequences ${seqs} \
        --p-n-jobs ${task.cpus} \
        --p-num-degenerates ${params.cull.degen} \
        --p-homopolymer-length ${params.cull.hpoly} \
        --o-clean-sequences '${db}_${amp_reg}_culled_seqs.qza' \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}



/*
----------------------------------------------------------------------------------------
    TRAIN CLASSIFIER

    Train a Naive Bayes classifier for taxonomic classification.
    Produces a classifier artifact that can be used with
    q2-feature-classifier for assigning taxonomy to query sequences.
----------------------------------------------------------------------------------------
*/

process TRAIN_CLASSIFIER {

    tag "${db} ${amp_reg}"
    label 'train_classifier'

    input:
    tuple val(db), val(amp_reg), path(seqs)
    tuple val(db_tax), val(amp_reg_tax), path(taxa)

    output:
    tuple val(db), val(amp_reg), path("${db}_${amp_reg}_classifier.qza"), emit: classifier
    path "versions.yml", emit: versions

    script:
    """
    qiime feature-classifier fit-classifier-naive-bayes \
        --i-reference-reads ${seqs} \
        --i-reference-taxonomy ${taxa} \
        --o-classifier '${db}_${amp_reg}_classifier.qza'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        q2-feature-classifier: \$(pip show q2-feature-classifier 2>/dev/null | grep -i version | sed 's/Version: //')
    END_VERSIONS
    """
}
