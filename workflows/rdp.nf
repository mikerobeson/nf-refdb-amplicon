include {
    GET_RDP;
    IMPORT_RDP;
} from '../modules/rdp_modules.nf'

include { 
    DEREP as FULL_DEREP_RDP;
    DEREP as AMP_DEREP_RDP;
    AMP_REG_EXTRACT as AMP_REG_EXTRACT_RDP;
    TRAIN_CLASSIFIER as FULL_TRAIN_RDP;
    TRAIN_CLASSIFIER as AMP_TRAIN_RDP;
 } from '../modules/base_modules.nf'

 primer_pair_tuples = Channel.fromList(params.primer_pairs)

 workflow MAKE_RDP_CLASSIFIERS {
    GET_RDP()
    IMPORT_RDP(GET_RDP.out.rdp_fasta, GET_RDP.out.rdp_tax_tsv)

    FULL_DEREP_RDP(IMPORT_RDP.out.rdp_seqs, IMPORT_RDP.out.rdp_taxa)
    FULL_TRAIN_RDP(FULL_DEREP_RDP.out.derep_seqs, FULL_DEREP_RDP.out.derep_taxa)

    AMP_REG_EXTRACT_RDP(FULL_DEREP_RDP.out.derep_seqs, primer_pair_tuples)
    AMP_DEREP_RDP(AMP_REG_EXTRACT_RDP.out.extract_amp, FULL_DEREP_RDP.out.derep_taxa)
    AMP_TRAIN_RDP(AMP_DEREP_RDP.out.derep_seqs, AMP_DEREP_RDP.out.derep_taxa)
}