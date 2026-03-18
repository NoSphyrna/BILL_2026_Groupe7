#!/bin/bash

usage() {
	echo "Usage: $0 python_script INPUT_SNP_DIRECTORY INPUT_BCF_DIRECTORY OUTPUT_DIRECTORY prefix"
	exit 1
}

while getopts "h" opt; do
	case $opt in
	h)
		usage
		;;
	\?)
		echo "Invalid option" >&2
		usage
		;;
	esac
done

shift $((OPTIND - 1))
if [ "$#" -ne 5 ] || ! [ -d "$2" ] || ! [ -d "$3" ] || ! [ -f "$1" ]; then
	usage
fi

PYTHON_SCRIPT="$1"
SNP_INPUT_DIR="$2"
BCF_INPUT_DIR="$3"
OUTPUT_DIR="$4"
PREFIX="$5"
# create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Extended option for glob in order to do the +[0-9] and the ?(_merged) regex-like match
# nullglob allow the glob to return an empty array instead of an array containging the regex in case of no match
shopt -s extglob nullglob

# Get the vcf files like P15-1.trimed.snp.vcf or P90-10_merged.trimed.vcf
FILES=("$SNP_INPUT_DIR$PREFIX"-+([0-9])?(_merged).trimed1000.snp.vcf)

for snp_file in "${FILES[@]}"; do
	base_name=$(basename "$snp_file" ".snp.vcf")
	bcf_file="$BCF_INPUT_DIR$base_name.bcf.vcf"
	output_file="$OUTPUT_DIR$base_name.snp.depth.vcf"
	echo "Calling python $PYTHON_SCRIPT over $snp_file and $bcf_file to produce $output_file"
	python "$PYTHON_SCRIPT" "$snp_file" "$bcf_file" "$output_file"
	echo "Done"
done
