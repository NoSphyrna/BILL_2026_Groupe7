# Bash commands for analysis

# Merge and concatvcf 
## .snp.vcf files 
### Preparation :

First compress all files with bgzip :

```bash
bgzip -c <file>.snp.vcf > <file>.snp.vcf.gz
```
To execute on all files in one command :

```bash
for i in $(find . -name '*.snp.vcf'); do bgzip -c $i > $i.gz; done
```
*Example of execution applied in the ngstc (from "inputs_all" directory)*
```bash
for i in $(find . -name '*.snp.vcf' -execdir basename '{}' ';'); do bgzip -c $i > /students/BILL/2026-BILL/Groupe7/Analyses/P25/$i.gz; done
```

Then index files for bcftools :
```bash
bcftools index <file>.snp.vcf.gz
```
To execute on all files in one command :

*(used directly as the following in the "Groupe7/Analyses/P25" or "P27" directory)*
```bash
for i in $(find . -name '*.snp.vcf.gz'); do bcftools index $i; done
```

### Merge
The following command will merge files creating multiple sample columns according to the order of the input files like "SAMPLE 2:SAMPLE 3:SAMPLE" (beacause od the --force-samples option)

In the result file, the different variants of the inputs file at the same position are merged and the number in the "heterozygote/homzygote" allows to tell which variant correspond to which sample
```bash
bcftools merge -o <output_file>.merged.snp.vcf --force-samples <file1>.snp.vcf.gz <file2>.snp.vcf.gz <file3>.snp.vcf.gz
```
*Example of execution in the "Analyses/P25" directory*
```bash
bcftools merge -o P25.trimed1000.merged.snp.vcf --force-samples P25-1.trimed1000.snp.vcf.gz P25-2.trimed1000.snp.vcf.gz P25-3.trimed1000.snp.vcf.gz P25-4.trimed1000.snp.vcf.gz P25-5.trimed1000.snp.vcf.gz P25-6.trimed1000.snp.vcf.gz P25-7.trimed1000.snp.vcf.gz P25-8.trimed1000.snp.vcf.gz P25-9.trimed1000.snp.vcf.gz P25-10.trimed1000.snp.vcf.gz
```

#### Automatisation :

A bash script that performs all the preparation steps and merges the files in a given input folder according to their prefix (e.g., "P25-," "P27-"), their extension (e.g., ".vcf"), and by default from 1 to 10.
The -f option allows you to choose the file numbers to merge, the -r option allows to remove files from chosen or preselected files. The --cold and --hot options allows to preselect files 1-5 and 6-10 respectively.

```bash
./merge.sh [-f "<indexes>" -r "<indexes>" --cold --hot] INPUT_DIRECTORY OUTPUT_DIRECTORY prefix extension
```

### Concatenation
This will concatenate files by giving a sorted concatenation of all records of vcf in input (it's possible beacause the -a option allows the begining of an input file to be lesser than the end of the previous input file).
```bash
bcftools concat -o <output_file>.concat.snp.vcf -a <input_file1>.snp.vcf.gz <input_file2>.snp.vcf.gz <input_file3>.snp.vcf.gz
```
*Example of execution in the "Analyses/P27" directory*
```bash
bcftools concat -o P27-6-10.trimed1000.concat.snp.vcf -a P27-6.trimed1000.snp.vcf.gz P27-7.trimed1000.snp.vcf.gz P27-8.trimed1000.snp.vcf.gz P27-9.trimed1000.snp.vcf.gz P27-10.trimed1000.snp.vcf.gz
```
# Add depth to .snp.vcf files
## bcftools

First we want a new raw vcf from "bcftools mpileup" directed by the ".snp.vcf" files to get the variant called only at the positions of the ".snp.vcf" file

To do that we need the bam files (with the .bam.bai index file)

We use the -T option to pass the .snp.vcf file and the -a AD,DP to make sure we get the DP and AD columns in the raw vcf and -I option to avoid call of INDELs.
Option -d is the max depth per position but we don't want to cap it so we put 100000 as max to avoid it (by default 250)

```bash 
bcftools mpileup -I -d 100000 -o <output_file>.bcf.vcf -f <reference>.fasta -a AD,DP -T <input_file>.snp.vcf <input_file>.aligned.sorted.bam
```
To execute it on all file directly (on cluster with srun):
```bash
srun ./bcftoolsmpileup.sh <Input_Directory> <Output_Direcory> <reference>.fasta
```
*example*
```bash
srun ./scripts/BILL_2026_Groupe7/BashScripts/bcftoolsmpileup.sh inputs_all/P25/ Analyses/P25/ References/KHV-U_trunc.fasta
```

## Python script

Then with the .snp.vcf and the .bcf.vcf files as input the python script "add_variant_depth.py" it will return a .snp.depth.vcf file as output with DP and AD columns in the SAMPLE column

```bash
python add_variant_depth.py <input_file>.snp.vcf <input_file>.bcf.vcf <optional_output_file>
```

To execute it on all files :
```bash
./execpython.sh <path/to/pythonscript/>add_variant_depth.py <Input_Directory_snp.vcf> <Input_Directory_bcf.vcf> <Output_Directory>
```

# Apply filters to snp vcf files

## Apply filters on depth and quality

A python scripts that takes an input file, an output directory and filters on minimum 
depth, minimum quality and values of depth and quality where the affine filter cross 
axis (affine function that passes through [0, affine_depth] and [affine_qual, 0] and 
it returns the filtered vcf file input with 
".filtered<affine_depth>_<affine_qual>_<min_depth>_<min_qual>.vcf" 
replacing the .vcf at the end of the input file.

```bash
python affine_depth_qual_filter.py -f affine_depth affine_qual min_depth min_qual <input_file> <OUTPUT_DIRECTORY>
```

## Apply filters on allelic depth and variant allelic frequence

A python scripts that takes an input file, an output directory and filters on minimum variant allelic frequence and minimum allelic depth. It returns the filtered vcf file input with ".af<min_vaf>_<min_ad>.vcf" replacing the .vcf at the end of the input file.

```bash
python allelic_depth.py -a min_vaf min_ad <input_file> <OUTPUT_DIRECTORY>
```

## Apply on all files

A bash script to apply wether depth and quality filters or allelic filters on all files in input directoty selected with extension

For depth and quality filters :

```bash
./apply_filter.sh -f affine_depth affine_qual min_depth min_qual affine_depth_qual_filter.py INPUT_DIRECTORY OUTPUT_DIRECTORY extension"
```

For allelic filters :

```bash
./apply_filter.sh -a min_vaf min_ad allelic_depth.py INPUT_DIRECTORY OUTPUT_DIRECTORY extension"
```


# Plots on depths on snp vcf files

A python scripts "plot_depth.py" allow to saves dpeths plot with or without filter visible on depths_qual (-f option) or ad_af (-a option) and saves it in th provided output folder.

```bash
python plot_depth.py [-f affine_depth affine_qual min_depth min_qual -a min_vaf min_ad] <input_file> <OUTPUT_DIRECTORY>"
```
To run it on all files in input folder (selected with extension)
```bash
./plotpython.sh [-f affine_depth affine_qual min_depth min_qual -a min_vaf min_ad] plot_depth.py <INPUT_DIRECTORY> <OUTPUT_DIRECTORY> <extension>"
```
*Example :*
```bash
./scripts/BILL_2026_Groupe7/BashScripts/plotpython.sh -f 1000 30 50 10 -a 0.1 50 scripts/BILL_2026_Groupe7/PythonScripts/plot_depth.py Analyses/P25_filtered/ Figures/P25_filtered/ .vcf
```


# SURVIVOR
## Merge sniffles.vcf files - for structural variants (indels, dupplication)

First make a list of all *.sniffles.vcf files which you need to merge

```bash
ls *sniffles.vcf > name_list.txt
```
*example*

```bash
ls *.sv_sniffles.vcf > sv_sniffles.vcf_P25_list.txt
```
When execute a command with SURVIVOR (with the parameters to merge the shared and unique variants)

```bash
SURVIVOR merge name_list.txt 1000 1 1 1 0 0 merged_name_sniffles_samples.vcf
```
*example*

```bash
SURVIVOR merge sv_sniffles.vcf_P27_list.txt 1000 1 1 1 0 0 merged_P27_sniffles_samples.vcf
```

