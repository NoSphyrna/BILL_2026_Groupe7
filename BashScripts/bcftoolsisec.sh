#!/bin/bash

# ========= Defaults variables =========
# To make sure it gets files in lexicogrpahic order :
LC_ALL=C
IFS=' '
# ========= Help function ===========
usage() {
	echo "Usage: $0 INPUT_DIRECTORY INPUT_DIRECTORY OUTPUT_DIRECTORY extension"
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

if [ "$#" -ne 4 ] || ! [ -d "$1" ] || ! [ -d "$2" ]; then

	echo "Remaining args:" "$@"
	usage
fi

INPUT_DIR="$1"
INPUT_DIR2="$2"
OUTPUT_DIR="$3"
EXTENSION="$4"
# create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
# get files but we want to be sure it's sorted the same way (with the sort option)  :
mapfile -t FILES < <(printf '%s\n' "$INPUT_DIR"*"$EXTENSION" | sort) # mapfile does the same thing as readarray (put input lines in array)
mapfile -t FILES2 < <(printf '%s\n' "$INPUT_DIR2"*"$EXTENSION" | sort)

# Function to get the number of the sample if it exists:
get_num() {
	local f
	f=$(basename "$1")
	[[ "$f" =~ ^P[0-9]+-([0-9]+) ]] && echo "${BASH_REMATCH[1]}" || echo ""
}

if [[ ${#FILES[@]} -ne ${#FILES2[@]} ]]; then
	echo "[Error] Not the same amout of in input files : ${#FILES[@]} and ${#FILES2[@]}"
	exit 1
fi

for file in "${FILES[@]}"; do
	echo "Calling \"bgzip\" over $file to produce $file.gz"
	bgzip -c "$file" >"$file".gz
	echo "Done"
	echo "Calling \"bcftools index\" over $file.gz to produce $file.gz.csi"
	bcftools index "$file".gz
	echo "Done"
done
for file in "${FILES2[@]}"; do
	echo "Calling \"bgzip\" over $file to produce $file.gz"
	bgzip -c "$file" >"$file".gz
	echo "Done"
	echo "Calling \"bcftools index\" over $file.gz to produce $file.gz.csi"
	bcftools index "$file".gz
	echo "Done"
done

for i in "${!FILES[@]}"; do
	f1="${FILES[$i]}"
	f2="${FILES2[$i]}"
	num1=$(get_num "${FILES[$i]}")
	num2=$(get_num "${FILES2[$i]}")

	if [ "$num1" -ne "$num2" ]; then
		echo "[Error] Different number of files : $num1 and $num2"
		exit 1
	fi

	output="$OUTPUT_DIR$num1/"

	mkdir -p "$output"

	echo "Calling \"bcftools isec\" over $f1.gz and $f2.gz to produce intersection files in $output"
	bcftools isec -p "$output" "$f1.gz" "$f2.gz"
	echo "Renaming output files"
	mv "$output""0000.vcf" "$output""$(basename "$f1" ".vcf")"".uniq.vcf"
	mv "$output""0001.vcf" "$output""$(basename "$f2" ".vcf")"".uniq.vcf"
	mv "$output""0002.vcf" "$output""$(basename "$f1" ".vcf")"".shared.vcf"
	mv "$output""0003.vcf" "$output""$(basename "$f2" ".vcf")"".shared.vcf"
	echo "Done"

done

for file in "${FILES[@]}"; do
	echo "Removing $file.gz"
	rm "$file".gz
	echo "Done"
	echo "removing $file.gz.csi"
	rm "$file".gz.csi
	echo "Done"
done
for file in "${FILES2[@]}"; do
	echo "Removing $file.gz"
	rm "$file".gz
	echo "Done"
	echo "removing $file.gz.csi"
	rm "$file".gz.csi
	echo "Done"
done
