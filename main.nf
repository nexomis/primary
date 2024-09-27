#!/usr/bin/env nextflow
nextflow.preview.output = true
include { validateParameters; paramsHelp; paramsSummaryLog; fromSamplesheet } from 'plugin/nf-validation'
include { showSchemaHelp; extractType } from './modules/config/schema_helper.nf'

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
  log.info paramsHelp("nextflow run nexomis/primary --input /path/to/fastq/dir --out_dir /path/to/out/dir")
  log.info showSchemaHelp("assets/input.json")
  exit 0
}

validateParameters()
log.info paramsSummaryLog(workflow)

include {PRIMARY} from './modules/subworkflows/primary/main.nf'
include {PARSE_SEQ_DIR_UNSPRING} from './modules/subworkflows/parse_seq_dir_unspring/main.nf'

workflow {

  if (params.in_dir) {
    inputDir = Channel.fromPath(params.in_dir, type: 'dir')
    reads = PARSE_SEQ_DIR_UNSPRING(inputDir)
  } else {
    reads = Channel.fromSamplesheet("input").map {
      def type = "SR"
      def files = [file(it[1])]
      if (it[2] && !it[2].isEmpty() ) {
        files << file(it[2])
        type = "PE"
      } else {
        if (it[1].toString().toLowerCase().endsWith("spring")) {
          type = "spring"
        }
      }
      meta = [
        "id": it[0],
        "read_type": type,
      ]
      return [meta, files]
    }
  }

  numReads = Channel.value(params.num_reads)

  Channel.fromPath(params.kraken2_db, type: "dir")
  | map {[["id": "kraken_db"], it]}
  | collect
  | set {dbPathKraken2}

  taxDir = Channel.fromPath(params.tax_dir, type: 'dir')

  PRIMARY(reads, dbPathKraken2, taxDir, numReads)

  publish:
  PRIMARY.out.trimmed >> 'trimmed_and_filtered'
  PRIMARY.out.fastqc_trim_html >> 'fastqc_for_trimmed'
  PRIMARY.out.fastqc_raw_html >> 'fastqc_for_raw'
  PRIMARY.out.multiqc_html >> 'multiqc'
  PRIMARY.out.kraken2_report >> 'classification'
  PRIMARY.out.kraken2_output >> 'classification'
  PRIMARY.out.class_report >> 'classification'

}

output {
    directory "${params.out_dir}"
    mode params.publish_dir_mode
    'fastp' {
        enabled params.save_fastp
    }
}
