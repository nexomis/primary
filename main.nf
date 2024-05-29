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

  fastpParameters = Channel.value([
    params.trim_poly_g,
    params.cut_right_window_size,
    params.cut_right_mean_qual,
    params.cut_tail_window_size,
    params.cut_tail_mean_qual,
    params.min_avg_qual,
    params.trim_poly_x,
    params.min_len
  ])

  PRIMARY(
    inputDir,
    fastpParameters
  )

}
