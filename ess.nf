nextflow.preview.recursion=true

include {MAKE_ESS_CLASSIFIER} from './workflows/extract_seqsegs.nf'

workflow {
    MAKE_ESS_CLASSIFIER()
}