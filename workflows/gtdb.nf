include { 
    GET_GTDB;
    GTDB_DEREP as FULL_DEREP;
    GTDB_DEREP as AMP_DEREP;
    GTDB_AMP_REG_EXTRACT;
    GTDB_TRAIN as FULL_TRAIN;
    GTDB_TRAIN as AMP_TRAIN;
 } from '../modules/gtdb_modules.nf'

primer_pair_tuples = Channel.fromList(params.primer_pairs)

workflow MAKE_GTDB_CLASSIFIERS {
    gtdb_db_ch = GET_GTDB()
    gtdb_derep_ch = FULL_DEREP(gtdb_db_ch)
    gtdb_amp_reg_extract_ch = GTDB_AMP_REG_EXTRACT(gtdb_derep_ch, primer_pair_tuples)
    gtdb_amp_reg_derep_ch = AMP_DEREP(gtdb_amp_reg_extract_ch)
    gtdb_full_train_ch = FULL_TRAIN(gtdb_derep_ch)
    gtdb_amp_train_ch = AMP_TRAIN(gtdb_amp_reg_derep_ch)
}
