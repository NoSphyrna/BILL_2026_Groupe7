import argparse
import os
import sys

import pysam as ps


# A function to get the length of an object that is either a Sized object or None
def pass_allelic_filter(
    vaf: float,
    ad: int,
    min_vaf: float,
    min_ad: int,
) -> bool:
    return vaf > min_vaf and ad > min_ad


# ========================== Parsing of arguments ============================== #
parser = argparse.ArgumentParser(
    description="Filter input vcf over quality and depth with minimum and affine filter"
)
parser.add_argument("input_file", help="Input VCF file")
parser.add_argument("output_directory", help="Output directory")
parser.add_argument(
    "-a",
    "--allelic-filters",
    nargs=2,
    type=float,
    required=True,
    metavar=("MIN_VAF", "MIN_AD"),
    help="Diplay the filter on allelic depth applied: min_variant_allelic_frequency, min_allelic_depth",
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


input_file = args.input_file
# Check if the inputs files are provided and has a .vcf extension
if not input_file.lower().endswith(".vcf"):
    print("\n[python] Error: Input file must have .vcf extension.")
    sys.exit(1)

# We add a depth in the name of the output file to differenciate it
output_directory = args.output_directory
min_vaf, min_ad = args.allelic_filters
if args.output_file:
    output_file = args.output_file
else:
    output_file = os.path.basename(input_file).replace(
        ".vcf", f".af{min_vaf}_{min_ad}.vcf"
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
nb_rec = 0
for rec in vcf_in.fetch():
    nb_rec += 1
    key = (rec.chrom, rec.pos)
    # Here, the file is supposed to have only one sample (not merged)
    if len(rec.samples.keys()) > 1:
        raise RuntimeError("Too many samples in first input file(", input_file, ")")
    if len(rec.samples.keys()) == 0:
        raise RuntimeError("No samples in first input file(", input_file, ")")

    sample_name = rec.samples.keys()[0]

    if (
        rec.samples[sample_name]["DP"] is not None
        and rec.samples[sample_name]["AD"] is not None
        and rec.alleles is not None
        and rec.alts is not None
    ):
        ads = list(rec.samples[sample_name]["AD"])
        depth = int(rec.samples[sample_name]["DP"])
        alleles = list(rec.alleles)
        alts = list(rec.alts)
        for i in range(len(ads) - 1, 0, -1):
            nb_var += 1
            ad = ads[i]
            vaf = ad / depth
            if not pass_allelic_filter(vaf, ad, min_vaf, min_ad):
                nb_removed += 1
                _ = ads.pop(i)
                _ = alleles.pop(i)
                _ = alts.pop(i - 1)
            if len(alts) != 0:
                _ = vcf_out.write(rec)
    else:
        nb_removed += 1

print(
    f"[python] Number of variant removed in {input_file} : {nb_removed}/{nb_var} on {nb_rec} position"
)
vcf_out.close()
