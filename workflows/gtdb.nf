include { 
    GET_GTDB;
 } from '../modules/gtdb_modules.nf'

include { 
    DEREP as FULL_DEREP;
    DEREP as AMP_DEREP;
    AMP_REG_EXTRACT;
    TRAIN_CLASSIFIER as FULL_TRAIN;
    TRAIN_CLASSIFIER as AMP_TRAIN;
 } from '../modules/base_modules.nf'
 
primer_pair_tuples = Channel.fromList(params.primer_pairs)


workflow MAKE_GTDB_CLASSIFIERS {
    GET_GTDB()

    FULL_DEREP(GET_GTDB.out.gtdb_seqs, GET_GTDB.out.gtdb_taxa)
    FULL_TRAIN(FULL_DEREP.out.derep_seqs, FULL_DEREP.out.derep_taxa)

    AMP_REG_EXTRACT(FULL_DEREP.out.derep_seqs, primer_pair_tuples)
    AMP_DEREP(AMP_REG_EXTRACT.out.extract_amp, FULL_DEREP.out.derep_taxa)
    AMP_TRAIN(AMP_DEREP.out.derep_seqs, AMP_DEREP.out.derep_taxa)
}
