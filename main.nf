#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
user="$USER"
date=new Date().format( 'yyMMdd' )


// Preset (default) parameters:
params.rundir                   ="${launchDir.baseName}"            // get basename of dir where script is started
params.outdir                   ='Demultiplexing_results'           // Default output folder.
params.genome                   ="hg38"                             // Default assembly
params.server                   =null                            // Default server

// Unset parameters: 
params.help                     =false
params.runfolder                =null   // required
params.samplesheet              =null   // required
params.DNA                      =null   // required
params.RNA                      =null   
params.skipAlign                =null
params.localStorage             =null
params.hg38v1                   =null
params.hg38v2                   =null
params.useBasesMask             =null
params.alignRNA                 =null
params.gatk                     =null
params.nomail             			=null
params.keepwork 	            	=null

// Variables:
runID="${date}.${user}.demultiV1"
runtype="demultiAndPreprocessV1"

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

def helpMessage() {
    log.info"""
    General info:
    This scripts requires at least 3 options: Path to runfolder, path to a samplesheet, and at least --DNA or --RNA parameter.
    There is no need to manually edit the samplesheet: The script will automatically separate DNA from RNA samples, and demultiplex them in parallel, if both --DNA and --RNA are set.
    
    PLEASE NOTE: The script will automatically perform preprocesssing and alignment of DNA samples (except ctDNA samples, as they rely on UMI data preprocessing and alignment). 
    Fastq and aligned CRAM files will automatically be transferred to the long term storage location. This means no Fastq or aligned CRAM files will be found where the script is executed - only in the long term storage (dataArchive) location.
    
    The resulting CRAM files will be available from the data archive location from each server as read-only locations:
    ../dataArchive/lnx02/alignedData/{genomeversion}/novaRuns/runfolder
    
    The resulting FastQ files will be available from the data archive location from each server as read-only locations:
    ../dataArchive/lnx02/fastq_storage/novaRuns/runfolder

    Data can be stored locally in the folder where the script is started instead, by using the --localStorage option

    By default, hg38 (v3) is used for alignment! 
    
    NOTE:
    For NovaSeq runs, the index read lengths may vary, depending on the type of samples (DNA and/or RNA) being sequenced. 
    For DNA-only runs, the index read lengths are normally: I1 = 17bp, and I2 = 8 bp.
    For mixed runs (DNA and RNA samples), the index read lengths are normally: I1= 19bp, and I2 = 10bp.


    Usage:

    Main options:
      --help                print this help message
   
      --runfolder           Path to runfolder (required)

      --samplesheet         Path to samplesheet (required)

      --localStorage        If set, all output data (fastq and CRAM) will be stored locally in output folder where the script is started.
                                Default: Not set. Data are by default stored at the archive (see description above)
                            
      --DNA                 Demultiplex DNA samples

      --RNA                 Demultiplex RNA samples

      --skipAlign           Do not perform preprocessing and alignment (i.e. only demultiplexing)
                                Default: Not set (i.e. run preprocessing and alignment)

      --server              Choose server to run script from (lnx01, lnx02, rgi01 or rgi02)
                                Default: unset - use only if running from lnx01

      --genome               hg19 or hg38
                                Default: hg38v3

      --keepwork            keep the workfolder generated by the nextflow script.
                                Default: not set - removes the Work folder generated by nextflow

      --nomail              Does not send a mail-message when completing a script
                                Default: not set - sends mail message if the user is mmaj or raspau and only if the script has been running longer than 20 minutes.

    """.stripIndent()
}
if (params.help) exit 0, helpMessage()


channel
    .fromPath(params.runfolder)
    .map { it -> tuple (it.simpleName, it)}
    .set { runfolder_ch } 

channel
    .fromPath(params.runfolder)
    .map { it -> it.simpleName}
    .set {runfolder_simplename } 



log.info """\
===============================================
Clinical Genetics Vejle: Demultiplexing v2
Last updated: feb. 2025
===============================================
Genome       : $params.genome
Genome FASTA : $genome_fasta
"""

channel
  .fromPath("${params.runfolder}/RunInfo.xml")
  .set {xml_ch}


channel.fromPath(params.samplesheet)
    .map { tuple(it.baseName,it) }
    .set {original_samplesheet}



include {      
         // Preprocess tools:
         prepare_DNA_samplesheet;
         bclConvert_DNA;
         fastq_to_ubam_umi;
         fastq_to_ubam;
         prepare_RNA_samplesheet; 
         bclConvert_RNA;
         markAdapters;
         align;
         markDup_cram;
         } from "./modules/demulti_modules.nf" 


workflow DEMULTIPLEX {
    take:
    original_samplesheet
    xml_ch
    main:
    if (params.DNA) {
        prepare_DNA_samplesheet(original_samplesheet)
        bclConvert_DNA(runfolder_ch, prepare_DNA_samplesheet.out.umi, xml_ch)
    }
    if (params.RNA) {
        prepare_RNA_samplesheet(original_samplesheet)
        bclConvert_RNA(runfolder_ch, prepare_RNA_samplesheet.out.umi, xml_ch)
    }
    emit: 
    dna_fastq=bclConvert_DNA.out.dna_fastq
}

workflow PREPROCESS {

    take:
    readsInputReMerged
    
    main:
    fastq_to_ubam(readsInputReMerged)
    markAdapters(fastq_to_ubam.out.ubam)
    align(markAdapters.out)
    markDup_cram(align.out)
    emit:
    finalAln=markDup_cram.out
}

workflow {

    DEMULTIPLEX(original_samplesheet, xml_ch)

    if (params.DNA && !params.skipAlign){

        DEMULTIPLEX.out.dna_fastq.flatten()
        | filter {it =~/_R1_/}
        | map { tuple (it.baseName.tokenize("-").get(0), it) }
    // |view
        | set {r1}    

        DEMULTIPLEX.out.dna_fastq.flatten()
        | filter {it =~/_R2_/}
        | map { tuple (it.baseName.tokenize("-").get(0), it) }
        //|view
        | set {r2}
       
        r1.join(r2).combine(runfolder_simplename)
        | map {npn, r1, r2,runfolder ->
            superpanel=r1.baseName.tokenize("-").get(1)
            (panel,subpanel)=superpanel.tokenize("_")
            meta = [npn:npn,id:npn+"_"+superpanel, superpanel:superpanel, panel:panel, subpanel:subpanel,runfolder:runfolder]
            tuple(meta, [r1, r2])
        }  
        | branch {meta, reads ->
                WES: (meta.panel=~/EV8/||meta.panel=~/EV7/)
                    return [meta + [datatype:"targeted",roi:"$WES_ROI"] ,reads]
                CTDNA: (meta.superpanel==/_CTDNA/)
                    return [meta + [datatype:"targeted",roi:"$AV1_ROI"] ,reads]
                MV1: (meta.superpanel==/MV1/)
                    return [meta + [datatype:"targeted",roi:"$MV1_ROI"] ,reads]
                WGS: (meta.superpanel=~/WG4/||meta.superpanel=~/WGS/)
                    return [meta + [datatype:"WGS",roi:"$WES_ROI"] ,reads]
                undetermined: true
                    return [meta + [datatype:"targeted",roi:"$AV1_ROI"] ,reads]      
        }

        | set {readsInputBranched}
        
        readsInputBranched.undetermined.concat(readsInputBranched.MV1).concat(readsInputBranched.WES).concat(readsInputBranched.WGS)
        | set {readsInputReMerged}  // Re-merge the data for the undetermined (i.e. AV1), MV1, WES, and WGS samples - i.e. only leave out plasma (CTDNA) samples.

    PREPROCESS(readsInputReMerged)  // standard preprocessing for all but CTDNA
    //fastq_to_ubam_umi(readsInputBranched.CTDNA) // preprocessing for CTDNA
    }
}

if (params.server=="lnx02") {
    workflow.onComplete {

        // Extract the first six digits from the samplesheet name
        def samplesheetName = new File(params.samplesheet).getName()
        def samplesheetDate = samplesheetName.find(/\d{6}/)

        // Only send email if --nomail is not specified, duration is longer than 20 minutes, the script executed succesfully, and if the user is mmaj or raspau.
        if (!params.nomail && workflow.duration > 1200000 && workflow.success) {
            if (System.getenv("USER") in ["raspau", "mmaj"]) {
                
                def workDirMessage = params.keepwork ? "WorkDir             : ${workflow.workDir}" : "WorkDir             : Deleted"
                
                def body = """\
                Pipeline execution summary
                ---------------------------
                Demultiplexing of sequencing run: ${samplesheetDate}
                Duration            : ${workflow.duration}
                Success             : ${workflow.success}
                ${workDirMessage}
                OutputDir           : ${params.outdir ?: 'Not specified'}
                Exit status         : ${workflow.exitStatus}
                """.stripIndent()


                // Send email using the built-in sendMail function
                sendMail(to: 'Mads.Jorgensen@rsyd.dk,Rasmus.Hojrup.Pausgaard@rsyd.dk', subject: 'Demultiplexing pipeline Update', body: body)
            }
        }

        // Handle deletion of WorkDir based on --keepwork parameter
        if (!params.keepwork && workflow.duration > 1200000 && workflow.success) {
            println("Deleting work directory: ${workflow.workDir}")
            "rm -rf ${workflow.workDir}".execute()
        }
    }
}
