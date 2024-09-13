#!/usr/bin/env nextflow
nextflow.preview.output = true
include { validateParameters; paramsHelp; paramsSummaryLog } from 'plugin/nf-validation'

log.info """
    |            #################################################
    |            #    _  _                             _         #
    |            #   | \\| |  ___  __ __  ___   _ __   (_)  __    #
    |            #   | .` | / -_) \\ \\ / / _ \\ | '  \\  | | (_-<   #
    |            #   |_|\\_| \\___| /_\\_\\ \\___/ |_|_|_| |_| /__/   #
    |            #                                               #
    |            #################################################
    |
    | primary: Perform primary analysis for NGS data
    |
    |""".stripMargin()

if (params.help) {
  log.info paramsHelp("nextflow run nexomis/primary --input_dir /path/to/fastq/dir --output_dir /path/to/out/dir")
  exit 0
}

validateParameters()
log.info paramsSummaryLog(workflow)

include {PRIMARY_FROM_DIR} from './modules/subworkflows/primary/from_dir/main.nf'

workflow {

  inputDir = Channel.fromPath(params.in_dir, type: 'dir')

  numReads = Channel.value(params.num_reads)

  Channel.fromPath(params.kraken2_db, type: "dir")
  | map {[["id": "kraken_db"], it]}
  | collect
  | set {dbPathKraken2}

  PRIMARY_FROM_DIR(
    inputDir,
    dbPathKraken2,
    numReads
  )

  publish:
  PRIMARY_FROM_DIR.out.trimmed >> 'fastp'
  PRIMARY_FROM_DIR.out.fastqc_trim_html >> 'fastqc_trim'
  PRIMARY_FROM_DIR.out.fastqc_raw_html >> 'fastqc_raw'
  PRIMARY_FROM_DIR.out.multiqc_html >> 'multiqc'

}

output {
    directory "${params.out_dir}"
    mode params.publish_dir_mode
    'fastp' {
        enabled params.save_fastp
    }
}
