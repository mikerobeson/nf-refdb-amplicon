include { 
    GET_GTDB;
 } from '../../modules/SSU/gtdb_modules.nf'

include { 
    DEREP as FULL_DEREP_GTDB;
    DEREP as AMP_DEREP_GTDB;
    AMP_REG_EXTRACT as AMP_REG_EXTRACT_GTDB;
    TRAIN_CLASSIFIER as FULL_TRAIN_GTDB;
    TRAIN_CLASSIFIER as AMP_TRAIN_GTDB;
 } from '../../modules/base_modules.nf'
 
primer_pair_tuples = Channel.fromList(params.primer_pairs)


workflow MAKE_GTDB_CLASSIFIERS {
    GET_GTDB()

    FULL_DEREP_GTDB(GET_GTDB.out.gtdb_seqs, GET_GTDB.out.gtdb_taxa)
    FULL_TRAIN_GTDB(FULL_DEREP_GTDB.out.derep_seqs, FULL_DEREP_GTDB.out.derep_taxa)

    AMP_REG_EXTRACT_GTDB(FULL_DEREP_GTDB.out.derep_seqs, primer_pair_tuples)
    AMP_DEREP_GTDB(AMP_REG_EXTRACT_GTDB.out.extract_amp, FULL_DEREP_GTDB.out.derep_taxa)
    AMP_TRAIN_GTDB(AMP_DEREP_GTDB.out.derep_seqs, AMP_DEREP_GTDB.out.derep_taxa)
}
