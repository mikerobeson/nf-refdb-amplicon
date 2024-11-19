include {MAKE_SILVA_CLASSIFIERS} from './workflows/SSU/silva.nf'
include {MAKE_GTDB_CLASSIFIERS} from './workflows/SSU/gtdb.nf'
include {MAKE_RDP_CLASSIFIERS} from './workflows/SSU/rdp.nf'

workflow {
    MAKE_SILVA_CLASSIFIERS()
    MAKE_GTDB_CLASSIFIERS()
    MAKE_RDP_CLASSIFIERS()
}