nextflow.preview.recursion=true

// include {MAKE_ESS_CLASSIFIER} from './extract_seqsegs.nf'
include {
    RECURSE as RECURSE_1;
    // RECURSE as RECURSE_2;
    // RECURSE as RECURSE_3;
} from './extract_seqsegs.nf'

// workflow ESS {
//     MAKE_ESS_CLASSIFIER()
// }
workflow ESS {
    RECURSE_1(params.seqsegs, params.id1)
    // RECURSE_2(RECURSE_1.out, params.id2)
    // RECURSE_3(RECURSE_2.out, params.id3)
    ESS_TRAIN_CLASSIFIER(RECURSE_1.out, params.taxa)
}