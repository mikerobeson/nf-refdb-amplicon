/*
----------------------------------------------------------------------------------------
    ESS_EXTRACT_READS

    Extracts initial sequence segments via primer search
 ----------------------------------------------------------------------------------------
 */

process ESS_EXTRACT_READS {

    tag "Extracting initial sequence segments via primer search"
    label 'ess_extseqsegs'

    publishDir "${params.outdir}/ess/initial_segments", mode: params.publish_dir_mode

    input:
    path seqs

    output:
    path "initial_seq_segments.qza", emit: seqsegs
    path "versions.yml",            emit: versions

    script:
    def max_len_param = params.ess.extract_max_length ? "--p-max-length ${params.ess.extract_max_length}" : ''
    """
    # Check QIIME 2 version to determine if --o-read-extraction-stats is needed
    QIIME_VERSION=\$(qiime --version | head -1 | sed 's/q2cli version //')
    MAJOR=\$(echo \$QIIME_VERSION | cut -d'.' -f1)
    MINOR=\$(echo \$QIIME_VERSION | cut -d'.' -f2)

    if [ "\$MAJOR" -gt 2026 ] || { [ "\$MAJOR" -eq 2026 ] && [ "\$MINOR" -ge 7 ]; }; then
        STATS_FLAG="--o-read-extraction-stats read_extraction_stats.qza"
    else
        STATS_FLAG=""
    fi

    qiime feature-classifier extract-reads \
        --i-sequences ${seqs} \
        --p-f-primer ${params.ess.fwd_primer} \
        --p-r-primer ${params.ess.rev_primer} \
        --p-min-length ${params.ess.extract_min_length} \
        ${max_len_param} \
        --p-n-jobs ${task.cpus} \
        --p-read-orientation 'both' \
        --o-reads initial_seq_segments.qza \
        --o-read-extraction-stats initial_seq_segments_stats.qza \
        \$STATS_FLAG \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "ESS:ESS_EXTRACT_READS":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        q2-feature-classifier: \$(pip show q2-feature-classifier 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}