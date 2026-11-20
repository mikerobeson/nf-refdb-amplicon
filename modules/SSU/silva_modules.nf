/*
----------------------------------------------------------------------------------------
    SILVA DATABASE MODULE

    Download and prepare SILVA SSU rRNA gene reference database
----------------------------------------------------------------------------------------
*/

process GET_SILVA {

    tag "Downloading SILVA ${params.silva?.version ?: '144'}"
    label 'get_silva'

    output:
    tuple val('silva'), val('full'), path('silva_seqs.qza'),             emit: silva_seqs
    tuple val('silva'), val('full'), path('silva_taxa.qza'),             emit: silva_taxa
    tuple val('silva'), val('full'), path('silva_aligned_seqs.qza'),     emit: silva_aligned_seqs, optional: true
    path "versions.yml",                                                 emit: versions

    script:
    def version          = params.silva.version            ?: '144'
    def target           = params.silva.target             ?: 'SSURef_NR99'
    def ranks            = params.silva.ranks              ?: 'domain phylum class order family genus'
    def rank_propagation = params.silva.rank_propagation   ? '' : '--p-no-rank-propagation'
    def seq_format       = params.silva.download_sequences ?: 'unaligned'
    """
    qiime rescript get-silva-data \\
        --p-version '${version}' \\
        --p-target '${target}' \\
        --p-ranks ${ranks} \\
        --p-seq-format '${seq_format}' \\
        ${rank_propagation} \\
        --o-silva-sequences silva_rna_seqs.qza \\
        --o-silva-taxonomy silva_taxa.qza \\
        --o-silva-sequences-aligned silva_aligned_seqs_raw.qza \\
        --verbose

    qiime rescript reverse-transcribe \\
        --i-rna-sequences silva_rna_seqs.qza \\
        --o-dna-sequences silva_seqs.qza

    # Check if the aligned sequences file is empty (0 sequences).
    # If empty, remove it so Nextflow's optional:true causes the
    # channel to emit nothing rather than passing an empty artifact.
    python3 -c "
import zipfile, sys
try:
    with zipfile.ZipFile('silva_aligned_seqs_raw.qza') as z:
        fasta_files = [f for f in z.namelist() if f.endswith('dna-sequences.fasta') or f.endswith('aligned-dna-sequences.fasta')]
        if fasta_files:
            content = z.read(fasta_files[0]).decode().strip()
            if content:
                sys.exit(0)
        sys.exit(1)
except:
    sys.exit(1)
" && mv silva_aligned_seqs_raw.qza silva_aligned_seqs.qza || rm -f silva_aligned_seqs_raw.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    """
    touch silva_seqs.qza
    touch silva_taxa.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: "stub"
        rescript: "stub"
    END_VERSIONS
    """
}