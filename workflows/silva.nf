include {
    GET_SILVA;
} from '../modules/silva_modules.nf'

include { 
    DEREP as FULL_DEREP_SILVA;
    DEREP as AMP_DEREP_SILVA;
    AMP_REG_EXTRACT as AMP_REG_EXTRACT_SILVA;
    TRAIN_CLASSIFIER as FULL_TRAIN_SILVA;
    TRAIN_CLASSIFIER as AMP_TRAIN_SILVA;
 } from '../modules/base_modules.nf'

 primer_pair_tuples = Channel.fromList(params.primer_pairs)

 workflow MAKE_SILVA_CLASSIFIERS {
    GET_SILVA()

    FULL_DEREP_SILVA(GET_SILVA.out.silva_seqs, GET_SILVA.out.silva_taxa)
    FULL_TRAIN_SILVA(FULL_DEREP_SILVA.out.derep_seqs, FULL_DEREP_SILVA.out.derep_taxa)

    AMP_REG_EXTRACT_SILVA(FULL_DEREP_SILVA.out.derep_seqs, primer_pair_tuples)
    AMP_DEREP_SILVA(AMP_REG_EXTRACT_SILVA.out.extract_amp, FULL_DEREP_SILVA.out.derep_taxa)
    AMP_TRAIN_SILVA(AMP_DEREP_SILVA.out.derep_seqs, AMP_DEREP_SILVA.out.derep_taxa)
}