# NGS demultiplex and preprocessing script, KG Vejle

## General info:
This scripts requires at least 3 options: Path to runfolder, path to a samplesheet, and at least --DNA or --RNA parameter.
There is no need to manually edit the samplesheet: The script will automatically separate DNA from RNA samples, and demultiplex them in parallel, if both --DNA and --RNA are set.

PLEASE NOTE: The script will automatically perform preprocesssing and alignment of most DNA samples. The only exceptiopn is ctDNA plasma samples, which requires alternative UMI-dependent preprocessing. Fastq and aligned CRAM files will automatically be transferred to the long term storage location. This means no Fastq or aligned CRAM files will be found where the script is executed - only in the long term storage (dataArchive) location.


The resulting CRAM files for all but plasma CTDNA samples will be available from the data archive location from each server as read-only locations:
../dataArchive/lnx02/alignedData/{genomeversion}/novaRuns/runfolder

The resulting FastQ files will be available from the data archive location from each server as read-only locations:
../dataArchive/lnx02/fastq_storage/novaRuns/runfolder


By default, hg38 (v3) is used for alignment!

Run the script with --help to see available options and default settings.
