include {
    GET_RDP;
    IMPORT_RDP;
} from '../modules/rdp_modules.nf'

include { 
    DEREP as FULL_DEREP;
    DEREP as AMP_DEREP;
    AMP_REG_EXTRACT;
    TRAIN_CLASSIFIER as FULL_TRAIN;
    TRAIN_CLASSIFIER as AMP_TRAIN;
 } from '../modules/base_modules.nf'

 primer_pair_tuples = Channel.fromList(params.primer_pairs)

 workflow MAKE_RDP_CLASSIFIERS {
    GET_RDP()
    IMPORT_RDP(GET_RDP.out.rdp_fasta, GET_RDP.out.rdp_tax_tsv)

    FULL_DEREP(IMPORT_RDP.out.rdp_seqs, IMPORT_RDP.out.rdp_taxa)
    FULL_TRAIN(FULL_DEREP.out.derep_seqs, FULL_DEREP.out.derep_taxa)

    AMP_REG_EXTRACT(FULL_DEREP.out.derep_seqs, primer_pair_tuples)
    AMP_DEREP(AMP_REG_EXTRACT.out.extract_amp, FULL_DEREP.out.derep_taxa)
    AMP_TRAIN(AMP_DEREP.out.derep_seqs, AMP_DEREP.out.derep_taxa)
}