#!/bin/bash

VCFPATH=$1
TMPPATH=$2
FAMFILE=$3
CHROM=$4

# Set up output files
rm -f ${TMPPATH}/locus_stats_${CHROM}.tab
touch ${TMPPATH}/locus_stats_${CHROM}.tab
rm -f ${TMPPATH}/sample_stats_${CHROM}.tab
touch ${TMPPATH}/sample_stats_${CHROM}.tab
rm -f ${TMPPATH}/het_stats_${CHROM}.tab
touch ${TMPPATH}/het_stats_${CHROM}.tab
rm -f ${TMPPATH}/mend_stats_${CHROM}.tab
touch ${TMPPATH}/mend_stats_${CHROM}.tab

samples=$(cat ${FAMFILE}  | cut -f 2)
families=$(cat ${FAMFILE} | cut -d'.' -f 1 | uniq)

vcf=${VCFPATH}/chr${chrom}/hipstr.chr${chrom}.with.1kg.filtered.vcf.gz

# Get locus stats
bcftools query -f "%CHROM\t%INFO/START\t%INFO/END\t%INFO/AN\t%INFO/PERIOD\t%INFO/INFRAME_PGEOM\t%INFO/INFRAME_UP\t%INFO/INFRAME_DOWN\t%INFO/BPDIFFS\t%INFO/AC\n" ${vcf} \
    >> ${TMPPATH}/locus_stats_${CHROM}.tab

# Get sample stats
bcftools query -f "[%SAMPLE\t%GT\n]" ${vcf} | grep -v "\." | cut -f 1 | \
    sort | uniq -c >> ${TMPPATH}/sample_stats_${CHROM}.tab

# Get heterozygosity
~/workspace/mgymrek-utils/vcf_het_by_length.py --vcf ${vcf} >> ${TMPPATH}/het_stats_${CHROM}.tab

# Get Mendelian inheritance
for fam in $families
do
    child=$(cat ${FAMFILE} | grep "$fam\.s1" | cut -f 2)
    mother=$(cat ${FAMFILE} | grep "$fam\.mo" | cut -f 2)
    father=$(cat ${FAMFILE} | grep "$fam\.fa" | cut -f 2)
    echo ${child},${mother},${father}
    bcftools query -s ${child},${mother},${father} \
	-f "%CHROM\t%INFO/START[\t%SAMPLE\t%GB\t%Q\t%DP]\n" ${vcf} | \
	./get_mend.py >> ${TMPPATH}/mend_stats_${CHROM}.tab
done