/*
----------------------------------------------------------------------------------------
    RDP DATABASE MODULE

    Download RDP (Ribosomal Database Project) reference database
----------------------------------------------------------------------------------------
*/

process GET_RDP {

    tag "Downloading RDP trainset ${params.rdp?.version ?: '19'}"
    label 'get_rdp'

    output:
    path("${params.rdp?.dirname ?: 'RDPClassifier_16S_trainsetNo19_QiimeFormat'}/RefOTUs.fa"),       emit: rdp_fasta
    path("${params.rdp?.dirname ?: 'RDPClassifier_16S_trainsetNo19_QiimeFormat'}/Ref_taxonomy.txt"), emit: rdp_tax_tsv
    path "versions.yml",                                                                                  emit: versions

    script:
    def version = params.rdp.version ?: '19'
    def dirname = params.rdp.dirname ?: 'RDPClassifier_16S_trainsetNo19_QiimeFormat'
    def url     = params.rdp.url     ?: 'https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/RDPClassifier_16S_trainsetNo19_QiimeFormat.zip'
    """
    wget '${url}'

    python3 -c "
import zipfile
import os

with zipfile.ZipFile('${dirname}.zip', 'r') as zf:
    for member in zf.infolist():
        # Fix Windows backslash paths
        member.filename = member.filename.replace('\\\\\\\\', '/')
        zf.extract(member, '.')
"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(wget --version 2>&1 | head -1 | sed 's/GNU Wget //' | sed 's/ .*//')
        python: \$(python3 --version | sed 's/Python //')
        rdp_trainset: ${version}
    END_VERSIONS
    """

    stub:
    def dirname = params.get_rdp?.dirname ?: 'RDPClassifier_16S_trainsetNo19_QiimeFormat'
    """
    mkdir -p '${dirname}'
    touch '${dirname}/RefOTUs.fa'
    touch '${dirname}/Ref_taxonomy.txt'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    wget: "stub"
    python: "stub"
    rdp_trainset: "stub"
    END_VERSIONS
    """
}



/*
----------------------------------------------------------------------------------------
    IMPORT RDP

    Imports RDP (Ribosomal Database Project) reference data
----------------------------------------------------------------------------------------
*/

process IMPORT_RDP {

    tag "Importing RDP trainset ${params.rdp?.version ?: 'N/A'}"
    label 'get_rdp'

    input:
    path(rdp_fasta)
    path(rdp_tax_tsv)

    output:
    tuple val('rdp'), val('full'), path('rdp_seqs.qza'), emit: rdp_seqs
    tuple val('rdp'), val('full'), path('rdp_taxa.qza'), emit: rdp_taxa
    path "versions.yml",                                 emit: versions

    script:
    def version = params.rdp.version ?: '19'
    """
    qiime tools import \\
        --input-path '${rdp_fasta}' \\
        --type 'FeatureData[Sequence]' \\
        --input-format 'MixedCaseDNAFASTAFormat' \\
        --output-path rdp_seqs.qza

    qiime tools import \\
        --input-path '${rdp_tax_tsv}' \\
        --type 'FeatureData[Taxonomy]' \\
        --input-format 'HeaderlessTSVTaxonomyFormat' \\
        --output-path rdp_taxa.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rdp_trainset: ${version}
    END_VERSIONS
    """

    stub:
    """
    touch rdp_seqs.qza
    touch rdp_taxa.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: "stub"
        rdp_trainset: "stub"
    END_VERSIONS
    """
}