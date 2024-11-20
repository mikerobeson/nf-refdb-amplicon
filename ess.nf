nextflow.preview.recursion=true

include {MAKE_ESS_CLASSIFIER} from './workflows/ESS/extract_seqsegs.nf'

workflow {
    MAKE_ESS_CLASSIFIER()
}