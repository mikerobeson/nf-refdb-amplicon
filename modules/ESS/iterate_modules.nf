/*
----------------------------------------------------------------------------------------
    ESS_SETUP

    Initializes the ESS iteration state with seed data
 ----------------------------------------------------------------------------------------
 */

process ESS_SETUP {

    tag "Seeding ESS iteration"
    label 'ess_setup'

    input:
    path seqsegs
    path ref_seqs
    path ref_taxa

    output:
    path "state.json", topic: 'ess_iteration'

    script:
    """
    python3 -c "
import json, os
state = {
    'step': 0,
    'seqsegs_path': os.path.abspath('${seqsegs}'),
    'ref_seqs': os.path.abspath('${ref_seqs}'),
    'ref_taxa': os.path.abspath('${ref_taxa}')
}
with open('state.json', 'w') as f:
    json.dump(state, f)
"
    """
}



/*
----------------------------------------------------------------------------------------
    ESS_ITERATE

    Performs iterative sequence extraction, dereplication, and culling
 ----------------------------------------------------------------------------------------
 */

process ESS_ITERATE {

    tag "ESS iteration ${task.index}"
    label 'ess_iterate'

    publishDir "${params.outdir}/ess/", mode: params.publish_dir_mode

    input:
    path state_json
    val limiter
    val perc_identity_schedule   // comma-separated string, one perc-identity per iteration, e.g. '0.7,0.7,0.8,0.8,0.9'

    output:
    path "state.json", topic: 'ess_iteration'
    path "iter_*/*_culled_seqs.qza", emit: culled_seqs
    path "iter_*/*_derep_taxa.qza", emit: derep_taxa
    path "versions.yml", emit: versions

    script:
    """
    #!/usr/bin/env python3
    import json
    import subprocess
    import os
    import sys

    with open('${state_json}') as f:
        state = json.load(f)

    current_step = state['step']
    step = current_step + 1
    seqsegs_path = state['seqsegs_path']
    ref_seqs = state['ref_seqs']
    ref_taxa = state['ref_taxa']
    db = '${params.ess.db}'
    amp_seg = '${params.ess.amp_seg}'

    # Per-iteration percent identity (schedule is expanded to one value per iteration)
    perc_schedule = '${perc_identity_schedule}'.split(',')
    if step > len(perc_schedule):
        sys.exit(f'ERROR: iteration {step} exceeds length of perc-identity schedule ({len(perc_schedule)})')
    perc_identity = perc_schedule[step - 1].strip()

    # Create iteration subdirectory
    iter_dir = f'iter_{step}'
    os.makedirs(iter_dir, exist_ok=True)

    print(f"=== ESS Iteration {step} (perc-identity {perc_identity}) ===", flush=True)

    # Step 1: Extract sequence segments
    print("Step 1: Extracting sequence segments...", flush=True)
    subprocess.run([
        'qiime', 'rescript', 'extract-seq-segments',
        '--i-input-sequences', ref_seqs,
        '--i-reference-segment-sequences', seqsegs_path,
        '--p-perc-identity', perc_identity,
        '--p-min-seq-len', '${params.ess.min_seq_len}',
        '--p-max-seq-len', '${params.ess.max_seq_len}',
        '--p-threads', '${task.cpus}',
        '--o-extracted-sequence-segments', f'{iter_dir}/{db}_{amp_seg}_matched_seqs.qza',
        '--o-unmatched-sequences', f'{iter_dir}/{db}_{amp_seg}_unmatched_seqs.qza',
        '--verbose'
    ], check=True)

    # Step 2: Dereplicate
    print("Step 2: Dereplicating...", flush=True)
    subprocess.run([
        'qiime', 'rescript', 'dereplicate',
        '--i-sequences', f'{iter_dir}/{db}_{amp_seg}_matched_seqs.qza',
        '--i-taxa', ref_taxa,
        '--p-mode', '${params.derep.mode}',
        '--p-threads', '${task.cpus}',
        '--o-dereplicated-sequences', f'{iter_dir}/{db}_{amp_seg}_derep_seqs.qza',
        '--o-dereplicated-taxa', f'{iter_dir}/{db}_{amp_seg}_derep_taxa.qza'
    ], check=True)

    # Step 3: Cull
    print("Step 3: Culling sequences...", flush=True)
    subprocess.run([
        'qiime', 'rescript', 'cull-seqs',
        '--i-sequences', f'{iter_dir}/{db}_{amp_seg}_derep_seqs.qza',
        '--p-n-jobs', '${task.cpus}',
        '--p-num-degenerates', '${params.cull.degen}',
        '--p-homopolymer-length', '${params.cull.hpoly}',
        '--o-clean-sequences', f'{iter_dir}/{db}_{amp_seg}_culled_seqs.qza',
        '--verbose'
    ], check=True)

    # Update state - point seqsegs_path to THIS iteration's culled seqs
    new_state = {
        'step': step,
        'seqsegs_path': os.path.abspath(f'{iter_dir}/{db}_{amp_seg}_culled_seqs.qza'),
        'ref_seqs': ref_seqs,
        'ref_taxa': ref_taxa,
        'perc_identity': perc_identity
    }

    print(f"Iteration {step} complete.", flush=True)

    with open('state.json', 'w') as f:
        json.dump(new_state, f)

    # Write versions
    qiime_version = subprocess.run(['qiime', '--version'], capture_output=True, text=True).stdout.strip().replace('q2cli version ', '')

    rescript_version = 'unknown'
    try:
        pip_output = subprocess.run(['pip', 'show', 'q2-rescript'], capture_output=True, text=True).stdout
        for line in pip_output.split('\\n'):
            if line.startswith('Version:'):
                rescript_version = line.replace('Version: ', '').strip()
                break
    except:
        pass

    with open('versions.yml', 'w') as f:
        f.write(f'"ESS_ITERATE":\\n')
        f.write(f'    qiime2: {qiime_version}\\n')
        f.write(f'    rescript: {rescript_version}\\n')
    """
}