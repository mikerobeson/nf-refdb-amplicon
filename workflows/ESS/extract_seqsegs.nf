nextflow.preview.recursion=true

// Recusion notes: 
// https://github.com/nextflow-io/nextflow/discussions/2521
// https://github.com/nextflow-io/nextflow/discussions/5297
// https://nextflow-io.github.io/patterns/feedback-loop/

include {

    ESS_EXTRACTSEQSEGS;
    ESS_DEREP;
    ESS_CULL;
    ESS_TABSEQS;
    ESS_TRAIN_CLASSIFIER;

} from '../../modules/ESS/extract_seqsegs_modules.nf'


workflow EXTRACT_ITER {

  take: 
    segseqs
    
  main:
    ESS_EXTRACTSEQSEGS(params.seqs, segseqs)
    ESS_DEREP(ESS_EXTRACTSEQSEGS.out.matched_extracted_seqs, params.taxa)
    ESS_CULL(ESS_DEREP.out.derep_seqs)
    ESS_TABSEQS(ESS_CULL.out.culled_seqs)

  emit:
    ESS_CULL.out.culled_seqs

}


workflow RECURSE {

    EXTRACT_ITER
        .recurse(params.segseqs)
        .times(params.iter)
    
    emit:
        EXTRACT_ITER
          .out.last()
          .view()

}


workflow MAKE_ESS_CLASSIFIER {

    RECURSE()
    ESS_TRAIN_CLASSIFIER(RECURSE.out, params.taxa)

}