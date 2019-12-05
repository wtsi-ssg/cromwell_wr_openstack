workflow JointCalling {
  # Inputs
  String referenceFASTA     # Reference FASTA file
  String referenceIndex     # Reference index
  String referenceDict      # Reference dictionary
  String sampleNameMap      # Sample name mapping
  String dbsnpVCF           # dbSNP VCF
  String dbsnpVCFIndex      # dbSNP VCF index
  Int? vcfCount             # Optional: Scatter count
  String input_intervals    # Intervals from combining step
  String gatk_jar           # GATK Path
  String java_oracle        # Oracle Java
  String genomicsdb_path    # S3 mount path where genomicsdb.tar will be copied

  # WR related inputs
  String wr_cwd             # WR Working directory
  String wr_cloud_script    # WR Cloud Script to run beforehand eg. to set up mount
  String wr_cloud_os        # WR Cloud OS name
  String wr_cloud_flavor    # WR Cloud Flavor 
 
  Array[String] unpadded_intervals = read_lines(input_intervals)

  scatter (idx in range(length(unpadded_intervals))) {
    call ImportGVCFs {
      input:
        sampleNameMap       = sampleNameMap,
        interval            = unpadded_intervals[idx],
        batch_size          = 50,
        gatk_jar            = gatk_jar,
        java_oracle         = java_oracle,
        iname               = sub(unpadded_intervals[idx], ":", "-"),
        genomicsdb_path     = genomicsdb_path,

        wr_cwd              = wr_cwd,
        wr_cloud_script     = wr_cloud_script,
        wr_cloud_os         = wr_cloud_os,
        wr_cloud_flavor     = wr_cloud_flavor
    }

    call GenotypeGVCFs {
      input:
        referenceFASTA      = referenceFASTA,
        referenceIndex      = referenceIndex,
        referenceDict       = referenceDict,
        dbsnpVCF            = dbsnpVCF,
        dbsnpVCFIndex       = dbsnpVCFIndex,
        workspace_tar       = ImportGVCFs.output_genomicsdb,
        interval            = unpadded_intervals[idx],
        output_vcf_filename = "output.vcf.gz",
        gatk_jar            = gatk_jar,
        java_oracle         = java_oracle,
        iname               = sub(unpadded_intervals[idx], ":", "-"),

        wr_cwd              = wr_cwd,
        wr_cloud_script     = wr_cloud_script,
        wr_cloud_os         = wr_cloud_os,
        wr_cloud_flavor     = wr_cloud_flavor
    }
  }

  output {
    # TODO Gathered output from scatter
  }
}


task ImportGVCFs {
  String sampleNameMap
  String interval
  Int    batch_size
  String gatk_jar
  String iname
  String java_oracle 
  String genomicsdb_path

  String wr_cwd
  String wr_cloud_script
  String wr_cloud_os
  String wr_cloud_flavor
  
  command <<<
    set -eu

    declare WORKSPACE="$(TMPDIR="/tmp" mktemp -du)"
    trap 'rm -rf "$WORKSPACE"' EXIT

    ${java_oracle} -Xms7g -Xmx7g -XX:+UseSerialGC -jar ${gatk_jar} \
      GenomicsDBImport \
      --genomicsdb-workspace-path "$WORKSPACE" \
      --batch-size ${batch_size} \
      -L ${interval} \
      --merge-input-intervals \
      --sample-name-map ${sampleNameMap} \
      --reader-threads 5 \
      -ip 500 

    tar cf "${genomicsdb_path}/${iname}.genomicsdb.tar" -C "$WORKSPACE" .
  >>>

  runtime {
    wr_cwd:          "${wr_cwd}"
    wr_cloud_script: "${wr_cloud_script}"
    wr_cloud_os:     "${wr_cloud_os}"
    wr_cloud_flavor: "${wr_cloud_flavor}"
  }

  output {
    File output_genomicsdb = "${genomicsdb_path}/${iname}.genomicsdb.tar"
  }
}

task GenotypeGVCFs {
  String referenceFASTA
  String referenceIndex
  String referenceDict
  String dbsnpVCF
  String dbsnpVCFIndex
  String workspace_tar
  String interval
  String output_vcf_filename
  String gatk_jar
  String iname 
  String java_oracle

  String wr_cwd
  String wr_cloud_script
  String wr_cloud_os
  String wr_cloud_flavor

  command <<<
    set -eu

    declare WORKSPACE="$(TMPDIR="/tmp" mktemp -d)"
    trap 'rm -rf "$WORKSPACE"' EXIT
    tar xf "${workspace_tar}" -C "$WORKSPACE"

    ${java_oracle} -Xms7g -Xmx7g -XX:+UseSerialGC -jar ${gatk_jar} \
      GenotypeGVCFs \
      -R "${referenceFASTA}" \
      -O "${iname}.${output_vcf_filename}" \
      -D "${dbsnpVCF}" \
      -G StandardAnnotation -G AS_StandardAnnotation \
      --only-output-calls-starting-in-intervals \
      --use-new-qual-calculator \
      -V "gendb://$WORKSPACE" \
      -L "${interval}"
  >>>

  runtime {
    wr_cwd:          "${wr_cwd}"
    wr_cloud_script: "${wr_cloud_script}"
    wr_cloud_os:     "${wr_cloud_os}"
    wr_cloud_flavor: "${wr_cloud_flavor}"
  }

  output {
    File output_vcf = "${iname}.${output_vcf_filename}"
    File output_vcf_index = "${iname}.${output_vcf_filename}.tbi"
  }
}
