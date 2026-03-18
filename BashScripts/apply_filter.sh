#!/bin/bash

# ========= Defaults variables =========

FILTERS=()
ALLELIC_FILTERS=()
OUTPUT_EXTENSION=""

# ========= Help function ===========
usage() {
	echo "Usage: $0 [option] python_script INPUT_DIRECTORY OUTPUT_DIRECTORY extension"
	echo "	-f affine_depth affine_qual min_depth min_qual : Apply affine filters on depth and quality"
	echo "	-a min_vaf min_ad : Apply filters on vaf and ad"
	exit 1
}

while getopts "f:a:h" opt; do
	case $opt in
	f)
		FILTERS=("-f" "$OPTARG" "${@:$OPTIND:3}")
		OPTIND=$((OPTIND + 3))
		OUTPUT_EXTENSION=".filtered{depth_affine}_{qual_affine}_{min_depth}_{min_qual}.vcf"
		# echo "${FILTERS[@]}"
		;;
	a)
		ALLELIC_FILTERS=("-a" "$OPTARG" "${@:$OPTIND:1}")
		OPTIND=$((OPTIND + 1))
		OUTPUT_EXTENSION=".af{min_vaf}_{min_ad}.vcf"
		# echo "${ALLELIC_FILTERS[@]}"
		;;
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

if [ "$#" -ne 4 ] || ! [ -d "$2" ]; then
	usage
fi

PYTHON_SCRIPT="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"
EXTENSION="$4"

mkdir -p "$OUTPUT_DIR"
# get files
FILES=("$INPUT_DIR"*"$EXTENSION")

# execute python script over all files
for file in "${FILES[@]}"; do
	filename=$(basename "$file" "$EXTENSION")
	echo "Calling python $PYTHON_SCRIPT over $file to filter it and produce $OUTPUT_DIR$filename$OUTPUT_EXTENSION"
	python "$PYTHON_SCRIPT" "${FILTERS[@]}" "${ALLELIC_FILTERS[@]}" "$file" "$OUTPUT_DIR"
	echo "Done"
done
