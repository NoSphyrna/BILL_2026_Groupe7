#!/bin/sh
if [ "$#" -ne 3 ] || ! [ -d "$2" ] || ! [ -d "$3" ]; then
	echo "Usage: $0 python_script INPUT_DIRECTORY OUTPUT_fig_DIRECTORY" >&2
	exit 1
fi

for i in $(find "$2" -name '*.snp.depth.vcf' -execdir basename '{}' .snp.depth.vcf ';'); do
	echo "Calling python $1 over $2$i.snp.depth.vcf to produce $3$i.snp.depth.vcf.*.png"
	python "$1" "$2""$i".snp.depth.vcf "$3"
	echo "Done"
done
