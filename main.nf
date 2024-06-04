#!/usr/bin/env nextflow

include { validateParameters; paramsHelp; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

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

include {PRIMARY} from './modules/subworkflows/primary/main.nf'

workflow {

  inputDir = Channel.fromPath(params.input_dir, type: 'dir')

  Channel.fromPath(params.kraken2_db, type: "dir")
  | collect
  | set {dbPathKraken2}

  PRIMARY(
    inputDir,
    dbPathKraken2
  )

}
