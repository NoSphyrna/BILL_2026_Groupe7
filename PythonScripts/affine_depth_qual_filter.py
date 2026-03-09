import argparse
import os
import sys

import pysam as ps


# A function to get the length of an object that is either a Sized object or None
def pass_affine_filter(
    depth: int,
    qual: float,
    depth_affine: int,
    qual_affine: float,
    min_depth: int,
    min_qual: float,
) -> bool:
    treshold = depth_affine * qual_affine
    return (
        depth > min_depth
        and qual > min_qual
        and depth * qual_affine + depth_affine * qual > treshold
    )


# ========================== Parsing of arguments ============================== #
parser = argparse.ArgumentParser(
    description="Filter input vcf over quality and depth with minimum and affine filter"
)
parser.add_argument("input_file", help="Input VCF file")
parser.add_argument("output_directory", help="Output directory")
parser.add_argument(
    "-f",
    "--filters",
    nargs=4,
    required=True,
    type=float,
    metavar=("AFFINE_DEPTH", "AFFINE_QUAL", "MIN_DEPTH", "MIN_QUAL"),
    help="Diplay the filter applied: affine_depth, affine_quality, min_depth, min_quality",
)
parser.add_argument(
    "-o",
    "--output-file",
    nargs=1,
    type=str,
    metavar=("OUTPUT_FILE"),
    help="Output file name",
)

args = parser.parse_args()


# Check if the inputs files are provided and has a .vcf extension
if not sys.argv[1].lower().endswith(".vcf"):
    print("\n[python] Error: Input file must have .vcf extension.")
    sys.exit(1)

# We add a depth in the name of the output file to differenciate it
input_file = args.input_file
output_directory = args.output_directory
depth_affine, qual_affine, min_depth, min_qual = args.filters
if args.output_file:
    output_file = args.output_file
else:
    output_file = os.path.basename(input_file).replace(
        ".vcf", f".filtered{depth_affine}_{qual_affine}_{min_depth}_{min_qual}.vcf"
    )
# If the direcory does not exist, we create it
os.makedirs(output_directory, exist_ok=True)

# We use the pysam.VariantFile to manipulate vcf input files
vcf_in = ps.VariantFile(input_file)

# We open the output file in writing mode with the header being header of the first input file with the decription of DP and AD added
vcf_out = ps.VariantFile(output_directory + output_file, "w", header=vcf_in.header)

# We iterate through the each line (record) of both vcf (assumed to be both with the same position beacause the mpileup used the first input vcf as refernce but in case it's not the case, it throws a runtimeerror)
nb_removed = 0
nb_var = 0
for rec in vcf_in.fetch():
    nb_var += 1
    key = (rec.chrom, rec.pos)
    # Here, the file is supposed to have only one sample (not merged)
    if len(rec.samples.keys()) > 1:
        raise RuntimeError("Too many samples in first input file(", input_file, ")")
    if len(rec.samples.keys()) == 0:
        raise RuntimeError("No samples in first input file(", input_file, ")")

    # Get the depth (DP) and allelic depth (AD) from second file input (raw vcf from bcftool mpileup)
    sample_name = rec.samples.keys()[0]
    if rec.qual is not None and rec.samples[sample_name]["DP"] is not None:
        qual = float(rec.qual)
        depth = int(rec.samples[sample_name]["DP"])
        if pass_affine_filter(
            depth, qual, depth_affine, qual_affine, min_depth, min_qual
        ):
            _ = vcf_out.write(rec)
        else:
            nb_removed += 1
    else:
        nb_removed += 1

print(f"[python] Number of variant removed in {input_file} : {nb_removed}/{nb_var}")
vcf_out.close()
