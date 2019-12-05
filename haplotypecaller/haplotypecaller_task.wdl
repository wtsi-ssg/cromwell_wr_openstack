task HaplotypeCaller {
  String input_bam
  String input_bam_index
  String ref_fasta
  String ref_fasta_index
  String ref_dict
  String sampleName
  
  String gatk_jar
  String java_oracle 
  String output_vcf_path
  
  String wr_cwd
  String wr_cloud_script
  String wr_cloud_os
  String wr_cloud_flavor
  
  command <<<
    set -eu

    ${java_oracle} -Xmx5625m -Xms5625m -XX:+UseSerialGC \
     -Dsamjdk.use_async_io_read_samtools=true \
     -Dsamjdk.use_async_io_write_samtools=true \
     -Dsamjdk.use_async_io_write_tribble=false-jar ${gatk_jar} \
     HaplotypeCaller \
      -R ${ref_fasta} \
      -ERC GVCF \
      -I ${input_bam} \
      --variant_index_type LINEAR \
      --variant_index_parameter 128000 \
      --max_alternate_alleles 6 \
      --pairHMM AVX_LOGLESS_CACHING_OMP \
      --native-pair-hmm-threads 8 \
      -O ${output_vcf_path}/${sampleName}.raw.g.vcf
  >>>

  runtime {
    wr_cwd:          "${wr_cwd}"
    wr_cloud_script: "${wr_cloud_script}"
    wr_cloud_os:     "${wr_cloud_os}"
    wr_cloud_flavor: "${wr_cloud_flavor}"
  }

  output {
    File rawGVCF = "${output_vcf_path}/${sampleName}.raw.g.vcf"
  }
}
