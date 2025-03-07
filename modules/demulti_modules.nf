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
/*
switch ($user) {
    case 'mmaj':
        permissions="full";
    break;
    
    case 'raspau':
        permissions="full";
    break;
    
    default:
        permissions="reduced";
    break;

}
*/
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
        genome_version="hg38v1"
        cnvkit_germline_reference_PON="/data/shared/genomes/hg38/inhouse_DBs/hg38v1_primary/cnvkit/wgs_germline_PON/jgmr_45samples.reference.cnn"
        cnvkit_inhouse_cnn_dir="/data/shared/genomes/hg38/inhouse_DBs/hg38v1_primary/cnvkit/wgs_persample_cnn/"
        inhouse_SV="/data/shared/genomes/hg38/inhouse_DBs/hg38v1_primary/"
        }
        
        if (params.hg38v2){
        genome_fasta = "/data/shared/genomes/hg38/ucsc.hg38.NGS.analysisSet.fa"
        genome_fasta_fai = "/data/shared/genomes/hg38/ucsc.hg38.NGS.analysisSet.fa.fai"
        genome_fasta_dict = "/data/shared/genomes/hg38/ucsc.hg38.NGS.analysisSet.dict"
        genome_version="hg38v2"
        }
        // Current hg38 version (v3): NGC with masks and decoys.
        if (!params.hg38v2 && !params.hg38v1){
        genome_fasta = "/data/shared/genomes/hg38/GRCh38_masked_v2_decoy_exclude.fa"
        genome_fasta_fai = "/data/shared/genomes/hg38/GRCh38_masked_v2_decoy_exclude.fa.fai"
        genome_fasta_dict = "/data/shared/genomes/hg38/GRCh38_masked_v2_decoy_exclude.dict"
        genome_version="hg38v3"
        cnvkit_germline_reference_PON="/data/shared/genomes/hg38/inhouse_DBs/hg38v3_primary/cnvkit/hg38v3_109samples.cnvkit.reference.cnn"
        cnvkit_inhouse_cnn_dir="/data/shared/genomes/hg38/inhouse_DBs/hg38v3_primary/cnvkit/wgs_persample_cnn/"
        inhouse_SV="/data/shared//genomes/hg38/inhouse_DBs/hg38v3_primary/"
        }


        AV1_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/av1.hg38.ROI.v2.bed"
        CV1_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/cv3.hg38.ROI.bed"
        CV2_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/cv3.hg38.ROI.bed"
        CV3_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/cv3.hg38.ROI.bed"
        CV4_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/cv4.hg38.ROI.bed"
        CV5_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/cv5.hg38.ROI.bed"
        GV3_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/gv3.hg38.ROI.v2.bed"
        NV1_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/nv1.hg38.ROI.bed"
        WES_ROI="/data/shared/genomes/hg38/interval.files/exome.ROIs/211130.hg38.refseq.gencode.fullexons.50bp.SM.bed"
        MV1_ROI="/data/shared/genomes/${params.genome}/interval.files/panels/muc1.hg38.coordinates.bed"
 
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


if (params.localStorage ) {
aln_output_dir="${params.outdir}/"
fastq_dir="${params.outdir}/"
qc_dir="${params.outdir}/QC/"
}

if (!params.localStorage) {
aln_output_dir="${dataStorage}/alignedData/${params.genome}/novaRuns/2025/"
fastq_dir="${dataStorage}/fastqStorage/novaRuns/"
qc_dir="${dataStorage}/fastqStorage/demultiQC/"
}


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

process bclConvert_DNA {
    tag "$runfolder_simplename"
    errorStrategy 'ignore'

    publishDir "${fastq_dir}/${runfolder_simplename}_umi", mode: 'copy', pattern:"*.fastq.gz"
    publishDir "${qc_dir}/", mode: 'copy', pattern:"*.DNA.html"

    input:
    tuple val(runfolder_simplename), path(runfolder)// from runfolder_ch2
    path(dnaSS) // from dnaSS1
    path(runinfo) // from xml_ch

    output:
    path("*.fastq.gz"), emit: dna_fastq// into (dna_fq_out,dna_fq_out2)
    path("*.Multiqc.DNA.html")
    script:
    """
    bcl-convert \
    --sample-sheet ${dnaSS} \
    --bcl-input-directory ${runfolder} \
    --output-directory ${runfolder_simplename}_umi/
    
    singularity run -B ${s_bind} ${simgpath}/multiqc.sif \
    -c ${multiqc_config} \
    -f -q ${runfolder_simplename}_umi/ \
    -n ${runfolder_simplename}.DemultiplexRunStats.Multiqc.DNA.html
    
    mv ${runfolder_simplename}_umi/*.fastq.gz .
    rm -rf Undetermined*
    """
}

process bclConvert_RNA {
    tag "$runfolder_simplename"
    errorStrategy 'ignore'

    publishDir "${fastq_dir}/${runfolder_simplename}_umi/", mode: 'copy', pattern:"*.fastq.gz"
    publishDir "${qc_dir}/", mode: 'copy', pattern:"*.RNA.html"

    input:
    tuple val(runfolder_simplename), path(runfolder)// from runfolder_ch2
    path(rnaSS) // from dnaSS1
    path(runinfo) // from xml_ch

    output:

    path("*.fastq.gz"), emit: rna_fastq// into (dna_fq_out,dna_fq_out2)
    path("*.Multiqc.RNA.html")

    script:
    """
    bcl-convert \
    --sample-sheet ${rnaSS} \
    --bcl-input-directory ${runfolder} \
    --output-directory ${runfolder_simplename}_umi/
    
    singularity run -B ${s_bind} ${simgpath}/multiqc.sif \
    -c ${multiqc_config} \
    -f -q ${runfolder_simplename}_umi/ \
    -n ${runfolder_simplename}.DemultiplexRunStats.Multiqc.RNA.html

    mv ${runfolder_simplename}_umi/*.fastq.gz .
    rm -rf Undetermined*
    """
}


///////////////////////////////// PREPROCESS MODULES - STANDARD //////////////////////// 


process fastq_to_ubam {
    errorStrategy 'ignore'
    tag "$meta.id"
    //publishDir "${params.outdir}/unmappedBAM/", mode: 'copy',pattern: '*.{bam,bai}'
    //publishDir "${params.outdir}/${runfolder_basename}/fastq_symlinks/", mode: 'link', pattern:'*.{fastq,fq}.gz'
    cpus 2
    maxForks 30

    input:
    tuple val(meta), path(data) // Meta [npn,id(npn_superpanel),superpanel,panel,subpanel,runfolder], data: [r1,r2]

    output:
    tuple val(meta), path("${meta.id}.unmapped.from.fq.bam"),emit:ubam// into (ubam_out1, ubam_out2)
    
    script:
    """
    ${gatk_exec} FastqToSam \
    -F1 ${data[0]} \
    -F2 ${data[1]} \
    -SM ${meta.id} \
    -PL illumina \
    -PU KGA_PU \
    -RG KGA_RG \
    -O ${meta.id}.unmapped.from.fq.bam
    """
}

process markAdapters {
    tag "$meta.id"
    errorStrategy 'ignore'

    input:
    tuple val(meta), path(uBAM)

    output:
    tuple val(meta), path("${meta.id}.ubamXT.bam"), path("${meta.id}.markAdapterMetrics.txt")// into (ubamXT_out,ubamXT_out2)

    script:
    """
    ${gatk_exec} MarkIlluminaAdapters \
    -I ${uBAM} \
    -O ${meta.id}.ubamXT.bam \
    --TMP_DIR ${tmpDIR} \
    -M ${meta.id}.markAdapterMetrics.txt
    """
}


process align {
    tag "$meta.id"

    maxForks 10
    errorStrategy 'ignore'
    cpus 60

    input:
    tuple val(meta), path(uBAMXT), path(metrics)//  from ubamXT_out

    output:
    tuple val(meta), path("${meta.id}.${genome_version}.QNsort.BWA.clean.bam")
    
    script:
    """
    ${gatk_exec} SamToFastq \
    -I ${uBAMXT} \
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
    -UNMAPPED ${uBAMXT} \
    -ALIGNED /dev/stdin \
    -MAX_GAPS -1 \
    -ORIENTATIONS FR \
    -SO queryname \
    -O ${meta.id}.${genome_version}.QNsort.BWA.clean.bam
    """
}


process markDup_cram {
    errorStrategy 'ignore'
    maxForks 16
    tag "$meta.id"
    publishDir "${aln_output_dir}/${meta.runfolder}_umi/", mode: 'copy', pattern: "*.cra*"
    conda '/lnx01_data3/shared/programmer/miniconda3/envs/samblasterSambamba/'
    input:
    tuple val(meta), path(bam)
    
    output:
    tuple val(meta), path("${meta.id}.${genome_version}.cram"), path("${meta.id}.${genome_version}*crai")
    
    script:
    """
    samtools view -h ${bam} \
    | samblaster | sambamba view -t 8 -S -f bam /dev/stdin | sambamba sort -t 8 --tmpdir=${tmpDIR} -o /dev/stdout /dev/stdin \
    |  samtools view \
    -T ${genome_fasta} \
    -C \
    -o ${meta.id}.${genome_version}.cram -

    samtools index ${meta.id}.${genome_version}.cram
    """
}


///////////////////////////////// PREPROCESS MODULES - UMI samples //////////////////////// 

process fastq_to_ubam_umi {
    errorStrategy 'ignore'
    tag "$sampleID"
    //publishDir "${params.outdir}/unmappedBAM/", mode: 'copy',pattern: '*.{bam,bai}'
    //publishDir "${params.outdir}/${runfolder_basename}/fastq_symlinks/", mode: 'link', pattern:'*.{fastq,fq}.gz'
    cpus 2
    maxForks 30
    conda '/lnx01_data3/shared/programmer/miniconda3/envs/fgbio/'

    input:
    tuple val(meta), path(data)
    
    output:
    tuple val(meta), path("${meta.id}.unmapped.umi.from.fq.bam"),   emit: unmappedBam
    tuple val(meta), path(data),                                    emit: fastq       

    
    script:
    """
    fgbio FastqToBam \
    -i ${data} \
    -n \
    --sample ${meta.id} \
    --library ${meta.npn} \
    --read-group-id KGA_RG \
    -O ${meta.id}.unmapped.umi.from.fq.bam
    """
}

