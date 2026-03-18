#!/bin/bash

usage() {
	echo "Usage: $0 INPUT_DIRECTORY BAM_INPUT_DIRECTORY OUTPUT_DIRECTORY reference_file prefix"
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
if [ "$#" -ne 5 ] || ! [ -d "$1" ] || ! [ -d "$2" ] || ! [ -f "$4" ]; then
	usage
fi

INPUT_DIR="$1"
INPUT_DIR_BAM="$2"
OUTPUT_DIR="$3"
REFERENCE="$4"
PREFIX="$5"
# create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to get the number of the sample if it exists:
get_num() {
	local f
	f=$(basename "$1")
	[[ "$f" =~ ^P[0-9]+-([0-9]+) ]] && echo "${BASH_REMATCH[1]}" || echo ""
}
# Extended option for glob in order to do the +[0-9] and the ?(_merged) regex-like match
# nullglob allow the glob to return an empty array instead of an array containging the regex in case of no match
shopt -s extglob nullglob

# Get the vcf files like P15-1.trimed.snp.vcf or P90-10_merged.trimed.vcf
FILES=("$INPUT_DIR$PREFIX"-+([0-9])?(_merged).trimed1000.snp.vcf)

for file in "${FILES[@]}"; do
	num_file=$(get_num "$file")
	base_name=$(basename "$file" ".snp.vcf")
	output_file="$base_name.bcf.vcf"
	bams=("$INPUT_DIR_BAM$PREFIX-$num_file"[_.]*.bam)
	mapfile -t floris < <(printf '%s\n' "${bams[@]}" | grep "Floris")
	mapfile -t floris_nor < <(printf '%s\n' "${floris[@]}" | grep "NotInRecord")

	# Here we look at the corresponding bam files if there are multpile bam 
	# files, we look after the one with Floris in it and if there are still
	# more than one bam file we take the one with NotInRecord in it because 
	# it is the bigger one
	if [[ ${#bams[@]} -eq 0 ]]; then
	    echo "[ERROR] No bam found for $file" >&2
	    continue
	elif [[ ${#bams[@]} -eq 1 ]]; then
	    bam_file="${bams[0]}"
	elif [[ ${#floris[@]} -eq 1 ]]; then
	    bam_file="${floris[0]}"
	elif [[ ${#floris_nor[@]} -eq 1 ]]; then
	    bam_file="${floris_nor[0]}"
	elif [[ ${#floris_nor[@]} -gt 1 ]]; then
	    echo "[ERROR] Too many bam files found for $file" >&2
	    continue
	else
	    echo "[ERROR] No 'Floris' bam files found for $file" >&2
	    continue
	fi 

	echo "Calling bcftools mpileup without INDEL over $file with $bam_file to produce $OUTPUT_DIR$output_file"
	bcftools mpileup -I -d 100000 -o "$OUTPUT_DIR$output_file" -f "$REFERENCE" -a AD,DP -T "$file" "$bam_file"
	echo "Done"
done
