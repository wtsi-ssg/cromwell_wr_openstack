import "haplotypecaller_task.wdl" as HC

workflow HaplotypeCallerGvcfWF {
    # Inputs
    String ref_fasta        # Reference FASTA file
    String ref_fasta_index  # Reference index
    String ref_dict         # Reference dictionary
    
    String gatk_jar         # GATK jar Path
    String java_oracle      # Oracle Java
    String output_vcf_path  # Output path where vcf will be saved
      
    String input_bam_list    # Intervals from combining step

    
    # WR related inputs
    String wr_cwd             # WR Working directory
    String wr_cloud_script    # WR Cloud Script to run beforehand eg. to set up mount
    String wr_cloud_os        # WR Cloud OS name
    String wr_cloud_flavor    # WR Cloud Flavor 
 
    Array[String] input_bam_array = read_lines(input_bam_list)

    scatter (idx in range(length(input_bam_array))) {
        call HC.HaplotypeCaller {
            input:
                input_bam       = input_bam_array[idx],
                input_bam_index = basename(input_bam_array[idx]).bai
                ref_fasta       = ref_fasta,
                ref_fasta_index = ref_fasta_index,
                ref_dict        = ref_dict,
                sampleName      = basename(input_bam_array[idx]),
                gatk_jar        = gatk_jar,
                java_oracle     = java_oracle,
                output_vcf_path = output_vcf_path,
                
                wr_cwd          = wr_cwd,
                wr_cloud_script = wr_cloud_script,
                wr_cloud_os     = wr_cloud_os,
                wr_cloud_flavor = wr_cloud_flavor
        }
    }

    output {
    # TODO Gathered output from scatter
  }
}
