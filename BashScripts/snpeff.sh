#!/bin/bash

# ========= Defaults variables =========
# To make sure it gets files in lexicogrpahic order :
LC_ALL=C
IFS=' '
# ========= Help function ===========
usage() {
	echo "Usage: $0 INPUT_DIRECTORY OUTPUT_DIRECTORY SNPEFF_DIR extension reference"
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

if [ "$#" -ne 5 ] || ! [ -d "$1" ] || ! [ -d "$3" ]; then
	echo "Remaining args:" "$@"
	usage
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
SNPEFF_DIR="$3"
EXTENSION="$4"
REFERENCE="$5"
# create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
# get files:
FILES=("$INPUT_DIR"*"$EXTENSION")

for file in "${FILES[@]}"; do
	output_file="$(basename "$file" ".vcf")"".ann.vcf"
	echo "Calling snpeff ann over $file to produce $OUTPUT_DIR/$output_file"
	snpEff ann -config "$SNPEFF_DIR"/snpEff.config -noStats "$REFERENCE" "$file" >"$OUTPUT_DIR/$output_file"
	echo "Done"
done
