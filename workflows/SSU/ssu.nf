include {MAKE_SILVA_CLASSIFIERS} from './silva.nf'
include {MAKE_GTDB_CLASSIFIERS} from './gtdb.nf'
include {MAKE_RDP_CLASSIFIERS} from './rdp.nf'

workflow SSU {
    MAKE_SILVA_CLASSIFIERS()
    MAKE_GTDB_CLASSIFIERS()
    MAKE_RDP_CLASSIFIERS()
}