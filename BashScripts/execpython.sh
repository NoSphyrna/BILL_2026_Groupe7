#!/bin/sh
if [ "$#" -ne 4 ] || ! [ -d "$2" ] || ! [ -d "$3" ] || ! [ -d "$4" ]; then
	echo "Usage: $0 python_script INPUT_SNP_DIRECTORY INPUT_BCF_DIRECTORY OUTPUT_DIRECTORY" >&2
	exit 1
fi

for i in $(find "$2" -name '*.snp.vcf' -execdir basename '{}' .snp.vcf ';'); do
	echo "Calling python $1 over $2$i.snp.vcf and $3$i.bcf.vcf to produce $4$i.snp.depth.vcf"
	python "$1" "$2""$i".snp.vcf "$3""$i".bcf.vcf "$4""$i".snp.depth.vcf
	echo "Done"
done
