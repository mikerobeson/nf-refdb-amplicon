nextflow.preview.recursion=true

include {MAKE_ESS_CLASSIFIER} from './extract_seqsegs.nf'

workflow ESS {
    MAKE_ESS_CLASSIFIER()
}