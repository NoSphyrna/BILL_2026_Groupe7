#!/bin/sh
if [ "$#" -ne 4 ] || ! [ -d "$2" ] || ! [ -d "$3" ] || ! [ -d "$4" ]; then
	echo "Usage: $0 python_script INPUT_SNP_DIRECTORY INPUT_BCF_DIRECTORY OUTPUT_DIRECTORY" >&2
	exit 1
fi

for i in $(find "$1" -name '*.snp.vcf' -execdir basename '{}' .snp.vcf ';'); do
	python "$1" "$2""$i".snp.vcf "$3""$i".bcf.vcf "$4""$i".snp.depth.vcf
done
