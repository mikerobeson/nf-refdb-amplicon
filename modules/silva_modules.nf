process GET_SILVA {

    conda "${params.qiime_conda_env}"
 
    tag 'Downloading SILVA data.'
    
    publishDir params.outdir, mode: 'copy'
 
    cpus 1

    output:        
       tuple val('silva'), val('full'), path('silva_seqs.qza'), emit: silva_seqs
       tuple val('silva'), val('full'), path('silva_taxa.qza'), emit: silva_taxa

    script:
        """
        qiime rescript get-silva-data \
            --p-version ${params.get_silva.version} \
            --p-target ${params.get_silva.target} \
            --p-ranks ${params.get_silva.ranks} \
            --p-rank-propagation \
            --o-silva-sequences silva_rna_seqs.qza \
            --o-silva-taxonomy silva_taxa.qza

        qiime rescript reverse-transcribe \
            --i-rna-sequences silva_rna_seqs.qza \
            --o-dna-sequences  silva_seqs.qza
        """
}

