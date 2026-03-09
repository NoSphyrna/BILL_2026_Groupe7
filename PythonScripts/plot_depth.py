import argparse
import os
import sys
from typing import Sized

import matplotlib.pyplot as plt
import pysam as ps


# A function to get the length of an object that is either a Sized object or None
def safe_len(obj: Sized | None) -> int:
    return len(obj) if obj is not None else 0


# ========================== Parsing of arguments ============================== #
parser = argparse.ArgumentParser(
    description="Plot figures of depth and quality from snp vcf with depth files"
)
parser.add_argument("input_file", help="Input VCF file")
parser.add_argument("output_directory", help="Output directory for figures")
parser.add_argument(
    "-f",
    "--filters",
    nargs=4,
    type=float,
    metavar=("AFFINE_DEPTH", "AFFINE_QUAL", "MIN_DEPTH", "MIN_QUAL"),
    help="Diplay the filter applied: affine_depth, affine_quality, min_depth, min_quality",
)
parser.add_argument(
    "-a",
    "--allelic-filters",
    nargs=2,
    type=float,
    metavar=("MIN_VAF", "MIN_AD"),
    help="Diplay the filter on allelic depth applied: min_variant_allelic_frequency, min_allelic_depth",
)

args = parser.parse_args()

# Check if the inputs files are provided and has a .vcf extension
if not args.input_file.lower().endswith(".vcf"):
    print("\n[python] Error: Input file must have .vcf extension.")
    sys.exit(1)

input_file = args.input_file
output_file = os.path.basename(input_file)
output_directory = args.output_directory

# If the direcory does not exist, we create it
os.makedirs(output_directory, exist_ok=True)

# We use the pysam.VariantFile to manipulate vcf input files
vcf_in = ps.VariantFile(input_file)

pos = []
allelic_pos = []
depths = []
depths_alts = []

alts = []
ads = []
vaf = []

qual = []
qual_alts = []

for rec in vcf_in.fetch():
    pos.append(rec.pos)
    if rec.alts is None:
        alts = []
    else:
        alts = list(rec.alts)
    qual.append(rec.qual)
    sample_name = rec.samples.keys()[0]
    dp = rec.samples[sample_name]["DP"]
    depths.append(dp)
    ad = list(rec.samples[sample_name]["AD"])
    for i in range(1, len(ad)):
        allelic_pos.append(pos)
        ads.append(ad[i])
        vaf.append(ad[i] / dp)
        depths_alts.append(dp)
        qual_alts.append(qual)


fig, ax1 = plt.subplots(figsize=(20, 10))

color1 = "tab:green"
ax1.plot(pos, depths, "-", color=color1, label="Depth")
ax1.set_xlabel("Variant position")
ax1.set_ylabel("Depth (DP)", color=color1)
ax1.tick_params(axis="y", labelcolor=color1)

ax2 = ax1.twinx()
color2 = "tab:blue"
ax2.set_ylabel("Phred Quality", color=color2)
ax2.plot(pos, qual, "-", color=color2, label="Quality")
ax2.tick_params(axis="y", labelcolor=color2)

plt.title("Depth and Quality according to variants position")
# plt.legend()
fig.tight_layout()
plt.savefig(output_directory + output_file + ".pos_depth_qual.png", format="png")
plt.close()


plt.figure(figsize=(10, 10))
plt.hist(depths, bins=30, edgecolor="black")
plt.title("Histogram of depths")

plt.savefig(output_directory + output_file + ".hist_depth.png", format="png")
plt.close()


plt.figure(figsize=(10, 10))
plt.scatter(qual, depths, alpha=0.6)
plt.xlabel("Quality")
plt.ylabel("Depth")
plt.title("Depth according to Quality")
plt.xlim(left=0)
plt.ylim(bottom=0)
if args.filters:
    d_aff, q_aff, min_d, min_q = args.filters
    a = -d_aff / q_aff
    b = d_aff
    d_intersect = a * min_q + b
    q_intersect = (min_d - b) / a
    plt.vlines(x=min_q, ymin=d_intersect, ymax=max(depths), colors="red")
    plt.hlines(y=min_d, xmin=q_intersect, xmax=max(qual), colors="red")
    plt.plot(
        [min_q, q_intersect],
        [d_intersect, min_d],
        color="red",
        linestyle="-",
        label="Filters applied",
    )
    plt.legend()
plt.savefig(output_directory + output_file + ".depth_qual.png", format="png")
plt.close()

plt.figure(figsize=(10, 10))
plt.scatter(ads, vaf, alpha=0.6)
plt.xlabel("Allelic depth")
plt.ylabel("Variant allelic frequency")
plt.title("VAF according to AD")
plt.xlim(left=0)
plt.ylim(bottom=0)
if args.allelic_filters:
    min_vaf, min_ad = args.allelic_filters
    plt.vlines(x=min_ad, ymin=min_vaf, ymax=max(vaf), colors="red")
    plt.hlines(
        y=min_vaf, xmin=min_ad, xmax=max(ads), colors="red", label="Filters applied"
    )
    plt.legend()
plt.savefig(output_directory + output_file + ".vaf_ad.png", format="png")
plt.close()
