#!/bin/bash

# ========= Defaults variables =========

FILTERS=()
ALLELIC_FILTERS=()

# ========= Help function ===========
usage() {
	echo "Usage: $0 [-f affine_depth affine_qual min_depth min_qual -a min_vaf min_ad] python_script INPUT_DIRECTORY OUTPUT_DIRECTORY extension"
	echo "	-f affine_depth affine_qual min_depth min_qual : Print applied filters on plots"
	echo "	-a min_vaf min_ad : Print filters applied on vaf and ad"
	exit 1
}

while getopts "f:a:h" opt; do
	case $opt in
	f)
		FILTERS=("-f" "$OPTARG" "${@:$OPTIND:3}")
		OPTIND=$((OPTIND + 3))
		echo "${FILTERS[@]}"
		;;
	a)
		ALLELIC_FILTERS=("-a" "$OPTARG" "${@:$OPTIND:1}")
		OPTIND=$((OPTIND + 1))
		echo "${ALLELIC_FILTERS[@]}"
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

	echo "Remaining args:" "$@"
	usage
fi

PYTHON_SCRIPT="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"
EXTENSION="$4"

# create directory if it doesn't exists
mkdir -p "$OUTPUT_DIR"

# get files
FILES=("$INPUT_DIR"*"$EXTENSION")

# execute python script over all files
for file in "${FILES[@]}"; do
	filename=$(basename "$file" "$EXTENSION")
	echo "Calling python $PYTHON_SCRIPT over $file to produce $OUTPUT_DIR$filename*.png"
	python "$PYTHON_SCRIPT" "$file" "$OUTPUT_DIR" "${FILTERS[@]}" "${ALLELIC_FILTERS[@]}"
	echo "Done"
done
