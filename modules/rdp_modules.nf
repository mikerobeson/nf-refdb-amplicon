process GET_RDP {
    conda "${params.qiime_conda_env}"
 
    tag 'Downloading RDP data.'
 
    cpus 1
    memory "${params.get_rdp.memory}"

    output:        
       path('RDPClassifier_16S_trainsetNo19_QiimeFormat/RefOTUs.fa'), emit: rdp_fasta
       path('RDPClassifier_16S_trainsetNo19_QiimeFormat/Ref_taxonomy.txt'), emit: rdp_tax_tsv
    
    script:
        """
        wget https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/RDPClassifier_16S_trainsetNo19_QiimeFormat.zip
        
        unzip RDPClassifier_16S_trainsetNo19_QiimeFormat.zip
        """    
}

process IMPORT_RDP {
    conda "${params.qiime_conda_env}"
 
    tag 'Importing RDP data.'

    cpus 1
    memory '1 GB'
    
    input:
        path(rdp_fasta)
        path(rdp_tax_tsv)

    output:
        tuple val('rdp'), val('full'), path('rdp_seqs.qza'), emit: rdp_seqs
        tuple val('rdp'), val('full'), path('rdp_taxa.qza'), emit: rdp_taxa

    script:
        """
        qiime tools import \
            --input-path '${rdp_fasta}' \
            --type 'FeatureData[Sequence]' \
            --input-format 'MixedCaseDNAFASTAFormat' \
            --output-path 'rdp_seqs.qza'

        qiime tools import \
            --input-path '${rdp_tax_tsv}' \
            --type 'FeatureData[Taxonomy]' \
            --input-format 'HeaderlessTSVTaxonomyFormat' \
            --output-path 'rdp_taxa.qza'
        """
}