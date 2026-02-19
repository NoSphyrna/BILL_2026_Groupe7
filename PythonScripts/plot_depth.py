import os
import sys
from typing import Sized

import matplotlib.pyplot as plt
import pysam as ps


# A function to get the length of an object that is either a Sized object or None
def safe_len(obj: Sized | None) -> int:
    return len(obj) if obj is not None else 0


# Check if the inputs files are provided and has a .vcf extension
if len(sys.argv) < 3 or not sys.argv[1].lower().endswith(".vcf"):
    print("\nUsage: python plot_depth.py <input_file.vcf> <output_directory_figures>")
    sys.exit(1)

# We add a depth in the name of the output file to differenciate it
input_file = sys.argv[1]
output_file = os.path.basename(input_file)
output_directory = sys.argv[2]

# We use the pysam.VariantFile to manipulate vcf input files
vcf_in = ps.VariantFile(input_file)

pos = []
depths = []

alts = []
alts_depth_ratio = []

qual = []

for rec in vcf_in.fetch():
    pos.append(rec.pos)
    # alts = tuple(rec.alts)
    qual.append(rec.qual)
    sample_name = rec.samples.keys()[0]
    depths.append(rec.samples[sample_name]["DP"])
    # ad = tuple(rec.samples[sample_name]["AD"])


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
plt.savefig(output_directory + output_file + ".pos_depth_qual.png")
plt.close()


plt.figure(figsize=(10, 10))
plt.hist(depths, bins=30, edgecolor="black")
plt.title("Histogram of depths")

plt.savefig(output_directory + output_file + ".hist_depth.png")
plt.close()


plt.figure(figsize=(10, 10))
plt.scatter(qual, depths, alpha=0.6)
plt.xlabel("Quality")
plt.ylabel("Depth")
plt.title("Depth according to Quality")
plt.savefig(output_directory + output_file + ".depth_qual.png")
plt.close()
# We add the description for depth and allelic depth
# snp_vcf_in.header.formats.add(
#     "DP", number=1, type="Integer", description="Number of high-quality bases"
# )
#
# snp_vcf_in.header.formats.add(
#     "AD", number="R", type="Integer", description="Allelic depths (high-quality bases)"
# )

# We open the output file in writing mode with the header being header of the first input file with the decription of DP and AD added
# vcf_out = ps.VariantFile(output_file, "w", header=snp_vcf_in.header)

# We iterate through the each line (record) of both vcf (assumed to be both with the same position beacause the mpileup used the first input vcf as refernce but in case it's not the case, it throws a runtimeerror)
# for rec_snp, rec_bcf in zip(snp_vcf_in.fetch(), bcf_vcf_in.fetch()):
#     key_snp = (rec_snp.chrom, rec_snp.pos)
#     key_bcf = (rec_bcf.chrom, rec_bcf.pos)
#     if key_snp != key_bcf:
#         raise RuntimeError(
#             f"Décalage entre deux lignes : snp :", key_snp, " bcf :", key_bcf
#         )
#     nb_var = safe_len(rec_snp.alleles)
#     if nb_var > safe_len(rec_bcf.alleles):
#         print(
#             "Warning : alts in first input files are greater than alts in second inut files :",
#             key_snp,
#         )
#
#     # Here, the file is supposed to have only one sample (not merged)
#     if len(rec_snp.samples.keys()) > 1:
#         raise RuntimeError("Too many samples in first input file")
#     if len(rec_bcf.samples.keys()) > 1:
#         raise RuntimeError("Too many samples in second input file")
#     if len(rec_snp.samples.keys()) == 0:
#         raise RuntimeError("No samples in first input file")
#     if len(rec_bcf.samples.keys()) == 0:
#         raise RuntimeError("No samples in second input file")
#
#     # Get the depth (DP) and allelic depth (AD) from second file input (raw vcf from bcftool mpileup)
#     bcf_sample_name = rec_bcf.samples.keys()[0]
#     dp = int(rec_bcf.samples[bcf_sample_name]["DP"])
#     ad = tuple(rec_bcf.samples[bcf_sample_name]["AD"])
#
#     # Keep only the longer alleles coresponding to the one present in the dirst input file (snp.vcf from medaka)
#     ad = tuple(ad[:nb_var])
#
#     # Add Depth and allelice depth to the record of the .snp.vcf file to write it in the outputfile
#     snp_sample_name = rec_snp.samples.keys()[0]
#     rec_snp.samples[snp_sample_name]["DP"] = dp
#     rec_snp.samples[snp_sample_name]["AD"] = ad
#
#     # Write the record(line) of the snp.vcf with the DP and AD added in the outputfile
#     _ = vcf_out.write(rec_snp)
#
# vcf_out.close()
