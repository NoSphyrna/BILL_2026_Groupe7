
mkdir -p filtered_vcf


for f in *.sv_sniffles.vcf; do
    echo "Filtering $f..."
    
    bcftools filter -i 'VAF > 0.2' "$f" -o "filtered_vcf/filtered_0.2_${f}"
done

echo "Done! All files are in the 'filtered_vcf' directory."
