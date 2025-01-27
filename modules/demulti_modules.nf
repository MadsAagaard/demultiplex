#!/usr/bin/env nextflow
nextflow.enable.dsl = 2


date=new Date().format( 'yyMMdd' )
user="$USER"
runID="${date}.${user}"


//////////////////////////// SWITCHES ///////////////////////////////// 

switch (params.gatk) {

    case 'danak':
    gatk_image="gatk419.sif";
    break;
    case 'new':
    gatk_image="gatk4400.sif";
    break;
    default:
    gatk_image="gatk4400.sif";
    break;
}




switch (params.server) {
    case 'lnx01':
        s_bind="/data/:/data/,/lnx01_data2/:/lnx01_data2/";
        simgpath="/data/shared/programmer/simg";
        params.intervals_list="/data/shared/genomes/hg38/interval.files/WGS_splitIntervals/wgs_splitinterval_BWI_subdivision3/*.interval_list";
        tmpDIR="/data/TMP/TMP.${user}/";
        gatk_exec="singularity run -B ${s_bind} ${simgpath}/${gatk_image} gatk";
        refFilesDir="/data/shared/genomes";
    break;
    default:
        s_bind="/data/:/data/,/lnx01_data2/:/lnx01_data2/,/fast/:/fast/,/lnx01_data3/:/lnx01_data3/,/lnx01_data4/:/lnx01_data4/";
        simgpath="/data/shared/programmer/simg";
        params.intervals_list="/data/shared/genomes/hg38/interval.files/WGS_splitIntervals/wgs_splitinterval_BWI_subdivision3/*.interval_list";
        tmpDIR="/fast/TMP/TMP.${user}/";
        gatk_exec="singularity run -B ${s_bind} ${simgpath}/${gatk_image} gatk";
        refFilesDir="/fast/shared/genomes";
    break;
}


switch (params.genome) {
    case 'hg19':
        assembly="hg19"
        // Genome assembly files:
        genome_fasta = "/data/shared/genomes/hg19/human_g1k_v37.fasta"
        genome_fasta_fai = "/data/shared/genomes/hg19/human_g1k_v37.fasta.fai"
        genome_fasta_dict = "/data/shared/genomes/hg19/human_g1k_v37.dict"
        genome_version="V1"
        break;


    case 'hg38':
        assembly="hg38"
        // Genome assembly files:
        if (params.hg38v1) {
        genome_fasta = "/data/shared/genomes/hg38/GRCh38.primary.fa"
        genome_fasta_fai = "/data/shared/genomes/hg38/GRCh38.primary.fa.fai"
        genome_fasta_dict = "/data/shared/genomes/hg38/GRCh38.primary.dict"
        genome_version="V1"
        cnvkit_germline_reference_PON="/data/shared/genomes/hg38/inhouse_DBs/hg38v1_primary/cnvkit/wgs_germline_PON/jgmr_45samples.reference.cnn"
        cnvkit_inhouse_cnn_dir="/data/shared/genomes/hg38/inhouse_DBs/hg38v1_primary/cnvkit/wgs_persample_cnn/"
        inhouse_SV="/data/shared/genomes/hg38/inhouse_DBs/hg38v1_primary/"
        }
        
        if (params.hg38v2){
        genome_fasta = "/data/shared/genomes/hg38/ucsc.hg38.NGS.analysisSet.fa"
        genome_fasta_fai = "/data/shared/genomes/hg38/ucsc.hg38.NGS.analysisSet.fa.fai"
        genome_fasta_dict = "/data/shared/genomes/hg38/ucsc.hg38.NGS.analysisSet.dict"
        genome_version="V2"
        }
        // Current hg38 version (v3): NGC with masks and decoys.
        if (!params.hg38v2 && !params.hg38v1){
        genome_fasta = "/data/shared/genomes/hg38/GRCh38_masked_v2_decoy_exclude.fa"
        genome_fasta_fai = "/data/shared/genomes/hg38/GRCh38_masked_v2_decoy_exclude.fa.fai"
        genome_fasta_dict = "/data/shared/genomes/hg38/GRCh38_masked_v2_decoy_exclude.dict"
        genome_version="V3"
        cnvkit_germline_reference_PON="/data/shared/genomes/hg38/inhouse_DBs/hg38v3_primary/cnvkit/hg38v3_109samples.cnvkit.reference.cnn"
        cnvkit_inhouse_cnn_dir="/data/shared/genomes/hg38/inhouse_DBs/hg38v3_primary/cnvkit/wgs_persample_cnn/"
        inhouse_SV="/data/shared//genomes/hg38/inhouse_DBs/hg38v3_primary/"
        }
        break;
}

dataStorage="/lnx01_data3/storage/"
multiqc_config="/data/shared/programmer/configfiles/multiqc_config_tumorBoard.yaml"
/*
if (!params.useBasesMask && !params.RNA) {
  dnaMask="Y*,I8nnnnnnnnn,I8,Y*"
}
if (!params.useBasesMask && params.RNA) {
  dnaMask="Y*,I8nnnnnnnnnnn,I8nn,Y*"
  rnaMask="Y*,I10nnnnnnnnn,I10,Y*"
}

if (params.useBasesMask) {
  dnaMask=params.useBasesMask
  params.DNA=true
}
*/

if (params.RNA) {
    umiConvertDNA="Y151;I8N2U9;I8N2;Y151"
    umiConvertRNA="Y151;I10U9;I10;Y151"
}

if (!params.RNA) {
    umiConvertDNA="Y151;I8U9;I8;Y151"

}

if (!params.DNA) {
    umiConvertDNA="Y151;I10U9;I10;Y151"

}




if (params.localStorage) {
aln_output_dir="${params.outdir}/"
fastq_dir="${params.outdir}/"
qc_dir="${params.outdir}/QC/"
}

if (!params.localStorage) {
aln_output_dir="${dataStorage}/alignedData/${params.genome}/novaRuns/2025/"
fastq_dir="${dataStorage}/fastqStorage/novaRuns/"
qc_dir="${dataStorage}/fastqStorage/demultiQC/"
}


log.info """\
===============================================
Clinical Genetics Vejle: Demultiplexing v2
Last updated: feb. 2025
Parameter information 
===============================================
Genome       : $params.genome
Genome FASTA : $genome_fasta
"""



/////////////////////////////////////////////////////////////////////////////
////////////////////////// DEMULTI PROCESSES: ///////////////////////////////
/////////////////////////////////////////////////////////////////////////////

process prepare_DNA_samplesheet {

    input:
    tuple val(samplesheet_basename), path(samplesheet)// from original_samplesheet1

    output:
    path("*.DNA_SAMPLES.csv"), emit: std
    path("*.UMI.csv"), emit: umi
    script:

    """
    cat ${samplesheet} | grep -v "RV1" > ${samplesheet_basename}.DNA_SAMPLES.csv

    sed 's/Settings]/&\\nOverrideCycles,${umiConvertDNA}\\nNoLaneSplitting,true\\nTrimUMI,0\\nCreateFastqIndexForReads,1/' ${samplesheet_basename}.DNA_SAMPLES.csv > ${samplesheet_basename}.DNA_SAMPLES.UMI.csv
    """
}
/*
process prepare_DNA_samplesheet {

    input:
    tuple val(samplesheet_basename), path(samplesheet)// from original_samplesheet1

    output:
    path("*.DNA_SAMPLES.csv"), emit: std
    path("*.UMI.csv"), emit: umi
    shell:
    '''
    cat !{samplesheet} | grep -v "RV1" > !{samplesheet_basename}.DNA_SAMPLES.csv
    sed 's/Settings]/&\nOverrideCycles,!{umiConvertDNA}\nNoLaneSplitting,true\nTrimUMI,0\nCreateFastqIndexForReads,1/' !{samplesheet_basename}.DNA_SAMPLES.csv > !{samplesheet_basename}.DNA_SAMPLES.UMI.csv
    '''
}
*/

process bclConvert_DNA {
    tag "$runfolder_simplename"
    errorStrategy 'ignore'

    publishDir "${fastq_dir}/${runfolder_simplename}_UMI/", mode: 'copy', pattern:"${runfolder_simplename}_umi/*.fastq.gz"
    publishDir "${qc_dir}/${runfolder_simplename}_UMI/", mode: 'copy', pattern:"*.DNA.html"

    input:
    tuple val(runfolder_simplename), path(runfolder)// from runfolder_ch2
    path(dnaSS) // from dnaSS1
    path(runinfo) // from xml_ch

    output:
    path("${runfolder_simplename}_umi/*.fastq.gz"), emit: dna_fastq// into (dna_fq_out,dna_fq_out2)
    path("${runfolder_simplename}.DemultiplexRunStats.Multiqc.DNA.html")
    script:
    """
    bcl-convert \
    --sample-sheet ${dnaSS} \
    --bcl-input-directory ${runfolder} \
    --output-directory ${runfolder_simplename}_umi/
    rm -rf Undetermined*
    
    singularity run -B ${s_bind} ${simgpath}/multiqc.sif \
    -c ${multiqc_config} \
    -f -q . \
    -n ${runfolder_simplename}.DemultiplexRunStats.Multiqc.DNA.html

    rm -rf Undetermined*


    """
}


process prepare_RNA_samplesheet {

    input:
    tuple val(samplesheet_basename), path(samplesheet)// from original_samplesheet2
    output:
    path("*.RNA_SAMPLES.csv"), emit: std
    path("*.UMI.csv"),emit: umi// into rnaSS1    

    script:
    """

    cat ${samplesheet} | grep "RV1" > ${samplesheet_basename}.RNAsamples.intermediate.txt
    sed -n '1,/Sample_ID/p' ${samplesheet} > ${samplesheet_basename}.HEADER.txt
    cat ${samplesheet_basename}.HEADER.txt ${samplesheet_basename}.RNAsamples.intermediate.txt > ${samplesheet_basename}.RNA_SAMPLES.csv 

    sed 's/Settings]/&\\nOverrideCycles,${umiConvertRNA}\\nNoLaneSplitting,true\\nTrimUMI,0\\nCreateFastqIndexForReads,1/' ${samplesheet_basename}.RNA_SAMPLES.csv > ${samplesheet_basename}.RNA_SAMPLES.UMI.csv
    """
}


process bclConvert_RNA {
    tag "$runfolder_simplename"
    errorStrategy 'ignore'

    publishDir "${fastq_dir}/${runfolder_simplename}_UMI/", mode: 'copy', pattern:"*.fastq.gz"
    publishDir "${qc_dir}/${runfolder_simplename}_UMI/", mode: 'copy', pattern:"*.RNA.html"

    input:
    tuple val(runfolder_simplename), path(runfolder)// from runfolder_ch2
    path(rnaSS) // from dnaSS1
    path(runinfo) // from xml_ch

    output:
    path("${runfolder_simplename}_umi/*.fastq.gz"), emit: rna_fastq// into (dna_fq_out,dna_fq_out2)
    path("${runfolder_simplename}.DemultiplexRunStats.Multiqc.RNA.html")
    script:
    """
    bcl-convert \
    --sample-sheet ${rnaSS} \
    --bcl-input-directory ${runfolder} \
    --output-directory ${runfolder_simplename}_umi/
    rm -rf Undetermined*
    
    singularity run -B ${s_bind} ${simgpath}/multiqc.sif \
    -c ${multiqc_config} \
    -f -q . \
    -n ${runfolder_simplename}.DemultiplexRunStats.Multiqc.RNA.html

    rm -rf Undetermined*
    """
}

/*
process bcl2fastq_RNA {
    tag "$runfolder_simplename"
    errorStrategy 'ignore'
    publishDir "${fastq_dir}/${runfolder_simplename}_UMI/", mode: 'copy'

    input:
    tuple val(runfolder_simplename), path(runfolder)// from runfolder_ch3
    path(rnaSS)// from rnaSS1
    path(runinfo)// from xml_ch2

    output:
    path("RNA_fastq/*.fastq.gz"), emit: rna_fastq// into (rna_fq_out,rna_fq_out2)

    script:
    """
    bcl2fastq \
    --sample-sheet ${rnaSS} \
    --runfolder-dir ${runfolder} \
    --use-bases-mask ${rnaMask} \
    --no-lane-splitting \
    -o RNA_fastq

    rm -rf RNA_fastq/Undetermined*
    """
}
*/

///////////////////////////////// PREPROCESS MODULES //////////////////////// 

process fastq_to_ubam_umi {
    errorStrategy 'ignore'
    tag "$sampleID"
    //publishDir "${params.outdir}/unmappedBAM/", mode: 'copy',pattern: '*.{bam,bai}'
    //publishDir "${params.outdir}/${runfolder_basename}/fastq_symlinks/", mode: 'link', pattern:'*.{fastq,fq}.gz'
    cpus 2
    maxForks 30
    conda '/lnx01_data3/shared/programmer/miniconda3/envs/fgbio/'

    input:
    tuple val(sampleID), path(r1),path(r2),val(runfolder_basename)// from sorted_input_ch1
    tuple val(meta), path(data)
    
    output:
    tuple val(sampleID), path("${sampleID}.unmapped.from.fq.bam"), val(runfolder_basename)// into (ubam_out1, ubam_out2)
    tuple val(meta), path(data),                                emit: fastq       
    tuple val(meta), path("${meta.id}.unmapped.from.fq.bam"),   emit: unmappedBam
    
    script:
    """
    fgbio FastqToBam \
    -i ${data} \
    -n \
    --sample ${meta.id} \
    --library ${meta.npn} \
    --read-group-id KGA_RG \
    -O ${meta.id}.unmapped.from.fq.bam
    """
}


process markAdapters {
    tag "$sampleID"
    errorStrategy 'ignore'

    input:
    tuple val(sampleID), path(uBAM),  val(runfolder_basename)//  from ubam_out1

    output:
    tuple val(sampleID), path("${sampleID}.ubamXT.bam"), val(runfolder_basename), path("${sampleID}.markAdapterMetrics.txt")// into (ubamXT_out,ubamXT_out2)

    script:
    """
    ${gatk_exec} MarkIlluminaAdapters \
    -I ${uBAM} \
    -O ${sampleID}.ubamXT.bam \
    --TMP_DIR ${tmpDIR} \
    -M ${sampleID}.markAdapterMetrics.txt
    """
}


process align {
    tag "$sampleID"

    maxForks 10
    errorStrategy 'ignore'
    cpus 60

    input:
    tuple val(sampleID), path(uBAM),  val(runfolder_basename), path(metrics)//  from ubamXT_out

    output:
    tuple val(sampleID), path("${sampleID}.${params.genome}.${genome_version}.QNsort.BWA.clean.bam"), val(runfolder_basename)// into (md_input1, md_input2, md_input3)
    
    script:
    """
    ${gatk_exec} SamToFastq \
    -I ${uBAM} \
    -INTER \
    -CLIP_ATTR XT \
    -CLIP_ACT 2 \
    -NON_PF \
    -F /dev/stdout \
    |  singularity run -B ${s_bind} ${simgpath}/bwa0717.sif bwa mem \
    -t ${task.cpus} \
    -p \
    ${genome_fasta} \
    /dev/stdin \
    | ${gatk_exec} MergeBamAlignment \
    -R ${genome_fasta} \
    -UNMAPPED ${uBAM} \
    -ALIGNED /dev/stdin \
    -MAX_GAPS -1 \
    -ORIENTATIONS FR \
    -SO queryname \
    -O ${sampleID}.${params.genome}.${genome_version}.QNsort.BWA.clean.bam
    """
}


process markDup_cram {
    errorStrategy 'ignore'
    maxForks 16
    tag "$sampleID"
    publishDir "${aln_output_dir}/${runfolder_basename}/", mode: 'copy', pattern: "*.BWA.MD.cr*"
    
    input:
    tuple val(sampleID), path(bam), val(runfolder_basename)// from md_input1
    
    output:
    tuple val(sampleID), path("${sampleID}.${params.genome}.${genome_version}.BWA.MD.cram"), path("${sampleID}.${params.genome}.${genome_version}.BWA.MD*crai")// into (cramout_1,cramout_2)
    
    script:
    """
    samtools view -h ${bam} \
    | samblaster | sambamba view -t 8 -S -f bam /dev/stdin | sambamba sort -t 8 --tmpdir=/data/TMP/TMP.${user}/ -o /dev/stdout /dev/stdin \
    |  samtools view \
    -T ${genome_fasta} \
    -C \
    -o ${sampleID}.${params.genome}.${genome_version}.BWA.MD.cram -

    samtools index ${sampleID}.${params.genome}.${genome_version}.BWA.MD.cram
    """
}



