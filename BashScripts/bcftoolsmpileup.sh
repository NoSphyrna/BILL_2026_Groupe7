#!/bin/sh
if [ "$#" -ne 3 ] || ! [ -d "$1" ] || ! [ -d "$2" ] || ! [ -f "$3" ]; then
	echo "Usage: $0 INPUT_DIRECTORY OUTPUT_DIRECTORY reference_file" >&2
	exit 1
fi

for i in $(find "$1" -name '*.snp.vcf' -execdir basename '{}' .snp.vcf ';'); do
	# echo "$1"
	# echo "$2"
	# echo "$3"
	# echo "$i" >"$2""$i".bcf.vcf
	bcftools mpileup -o "$2""$i".bcf.vcf -f "$3" -a AD,DP -T "$1""$i".snp.vcf "$1""$i".aligned.sorted.bam
done
