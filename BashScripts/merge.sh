#!/bin/bash

# ========= Defaults variables =========

FILE_NUMBERS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
DELETE=()
IFS=' '
# ========= Help function ===========
usage() {
	echo "Usage: $0 [-f \"<indexes>\" -r \"<indexes>\" --cold --hot] INPUT_DIRECTORY OUTPUT_DIRECTORY prefix extension"
	echo "	-f \"<indexes of files to add>\" : Choose files to merge by index (default is all files)"
	echo "	-r \"<indexes of file to remove>\" : Choose file to remove from default (all) or from presets --cold (1-5) or --hot (6-10)"
	echo "	--cold : Preselect files from 1-5 samples"
	echo "	--hot : Preselect files from 6-10 samples"
	exit 1
}

for arg in "$@"; do
	shift
	case "$arg" in
	'--cold') set -- "$@" '-d' ;;
	'--hot') set -- "$@" '-t' ;;
	*) set -- "$@" "$arg" ;;
	esac
done

while getopts "f:r:dth" opt; do
	case $opt in
	f)
		OPTARG=$(sort -n <<<"${OPTARG// /$'\n'}")
		OPTARG="${OPTARG//$'\n'/ }"
		read -ra FILE_NUMBERS <<<"$OPTARG"
		echo "Files to look for:" "${FILE_NUMBERS[@]}"
		;;
	r)
		OPTARG=$(sort -n <<<"${OPTARG// /$'\n'}")
		OPTARG="${OPTARG//$'\n'/ }"
		read -ra DELETE <<<"$OPTARG"
		echo "Files to remove:" "${DELETE[@]}"
		;;
	d)
		FILE_NUMBERS=("1" "2" "3" "4" "5")
		;;
	t)
		FILE_NUMBERS=("6" "7" "8" "9" "10")
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

if [ "$#" -ne 4 ] || ! [ -d "$1" ] || ! [ -d "$2" ]; then

	echo "Remaining args:" "$@"
	usage
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
PREFIX="$3"
EXTENSION="$4"
# get files
NUMBERS=()
FILES=()
GZ_FILES=()
for file_number in "${FILE_NUMBERS[@]}"; do
	remove=false
	for del in "${DELETE[@]}"; do
		if [ "$file_number" = "$del" ]; then
			remove=true
		fi
	done
	if [ -z "$MILIEU" ]; then
		temp="${PREFIX}${file_number}"
		full_name=$(basename "$INPUT_DIR$PREFIX$file_number".*"$EXTENSION" "$EXTENSION")
		MILIEU="${full_name#"$temp"}"
	fi
	if [ "$remove" = false ]; then
		file=("$INPUT_DIR$PREFIX$file_number."*"$EXTENSION")
		FILES+=("${file[0]}")
		GZ_FILES+=("${file[0]}.gz")
		NUMBERS+=("$file_number")

	fi
done

for file in "${FILES[@]}"; do
	echo "Calling \"bgzip\" over $file to produce $file.gz"
	bgzip -c "$file" >"$file".gz
	echo "Done"
	echo "Calling \"bcftools index\" over $file.gz to produce $file.gz.csi"
	bcftools index "$file".gz
	echo "Done"
done

join_array() {
	local IFS="$1"
	shift
	echo "$*"
}

OUTPUT_NUMBERS=$(join_array - "${NUMBERS[@]}")

OUTPUT_FILE="$PREFIX""merged""$OUTPUT_NUMBERS""$MILIEU""$EXTENSION"

echo "Calling \"bcftools merge\" to produce $OUTPUT_FILE"
bcftools merge -o "$OUTPUT_DIR""$OUTPUT_FILE" --force-samples "${GZ_FILES[@]}"

for file in "${FILES[@]}"; do
	echo "Removing $file.gz"
	rm "$file".gz
	echo "Done"
	echo "removing $file.gz.csi"
	rm "$file".gz.csi
	echo "Done"
done
