echo "Sample,POS,QUAL,DP,VAF" > vaf_dp_qual_data.csv

for f in *.sv_sniffles.vcf; do
    # Extract the sample name from the filename
    sample_name=$(basename "$f" .sv_sniffles.vcf) # not filtered vcf 
    
    awk -F'\t' -v s="$sample_name" '
        !/^#/ {
            pos = $2;   # Position (2nd column)
            qual = $6;  # Quality (6th column)
            info = $8;  # INFO field (8th column)
            
            dp = 0; 
            vaf = 0;
            
            # Split the INFO string to extract data for each position
            n = split(info, tags, ";");
            
            for (i=1; i<=n; i++) {
                # Extract the depth value
                if (tags[i] ~ /^COVERAGE=/) {
                    split(tags[i], c_part, "=");
                    split(c_part[2], nums, ",");
                    dp = nums[3];
                }
                # Extract the allelic frequency
                if (tags[i] ~ /^VAF=/) {
                    split(tags[i], v_part, "=");
                    vaf = v_part[2];
                }
            }
            
            # Output the sample name, position, quality, VAF and depth to the existing file "vaf_dp_qual_data.csv"
            print s "," pos "," qual "," dp "," vaf
        }' "$f" >> vaf_dp_qual_data.csv
done