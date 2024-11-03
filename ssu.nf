include {MAKE_SILVA_CLASSIFIERS} from './workflows/silva.nf'
include {MAKE_GTDB_CLASSIFIERS} from './workflows/gtdb.nf'
include {MAKE_RDP_CLASSIFIERS} from './workflows/rdp.nf'

workflow {
    MAKE_SILVA_CLASSIFIERS()
    MAKE_GTDB_CLASSIFIERS()
    MAKE_RDP_CLASSIFIERS()
}