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

We use the -T option to pass the .snp.vcf file and the -a AD,DP to make sure we get the DP and AD columns in the raw vcf

```bash 
bcftools mpileup -o <output_file>.bcf.vcf -f <reference>.fasta -a AD,DP -T <input_file>.snp.vcf <input_file>.aligned.sorted.bam
```
## Python script

Then with the .snp.vcf and the .bcf.vcf files as input the python script "add_variant_depth.py" it will return a .snp.depth.vcf file as output with DP and AD columns in the SAMPLE column

```bash
python add_variant_depth.py <input_file>.snp.vcf <input_file>.bcf.vcf
```
