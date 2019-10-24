#!/bin/bash
set -euo pipefail

version=0.0.1
sampleDir=$1

. *.variables

# make output dir for results
mkdir -p /staging/data/results/$seqId/$panel/$sampleId

dragen \
    -r /staging/human/reference/hg19/ \
    --output-directory /staging/data/results/$seqId/$panel/$sampleId \
    --output-file-prefix "$seqId"_"$sampleId" \
    --output-format BAM \
    -1 "$sampleId"_S*_L001_R1_*.fastq.gz \
    -2 "$sampleId"_S*_L001_R2_*.fastq.gz \
    --combine-samples-by-name true \
    --enable-duplicate-marking true \
    --enable-variant-caller true \
    --vc-sample-name "$sampleId" \
    --vc-target-bed /data/pipelines/$pipelineName/"$pipelineName"-"$pipelineVersion"/$panel/*.bed \
    --vc-emit-ref-confidence BP_RESOLUTION \
    --qc-coverage-region-1 /data/pipelines/$pipelineName/"$pipelineName"-"$pipelineVersion"/$panel/*.bed \
    --qc-coverage-reports-1 cov_report \
    --strict-mode true

if [ -e /staging/data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".gvcf.gz ] && [ "$sampleId" != "NTC" ]; then
    echo /staging/data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".gvcf.gz >> /staging/data/results/$seqId/$panel/gVCFList.txt
fi

# if all samples have been processed for the panel perform joint genotyping
# expected number
expGVCF=$(ls -d /staging/data/fastq/$seqId/Data/$panel/*/ | grep -v "NTC" | wc -l)

# observed number
obsGVCF=$(wc -l < /staging/data/results/$seqId/$panel/gVCFList.txt)

if [ $expGVCF == $obsGVCF ]; then
    echo "$sampleId is the last sample"
    echo "performing joint genotyping"

    dragen \
        -r  /staging/human/reference/hg19/ \
        --output-directory /staging/data/results/$seqId/$panel \
        --output-file-prefix "$seqId" \
        --enable-joint-genotyping true \
        --variant-list /staging/data/results/$seqId/$panel/gVCFList.txt \
        --strict-mode true
else
    echo "$sampleId is not the last sample"

fi
