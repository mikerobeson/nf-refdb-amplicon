nextflow.enable.dsl = 2

// set up if statment to run SSU or ESS
include { ESS } from './workflows/ESS/ess.nf'
include { SSU } from './workflows/SSU/ssu.nf'

workflow {
    if (!(params.pipeline_type)) {
        exit 1, 'pipeline_type parameter \"ssu\" or \"ess\" is required!'
        }
    if ( params.pipeline_type == 'ssu' ) {
        SSU()
    } else if ( params.pipeline_type == 'ess' ) {
        ESS()
    } else {
        exit 1, 'pipeline_type parameter values can only be \"ssu\" or \"ess\"!'
    }
}