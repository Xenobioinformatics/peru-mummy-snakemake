rule trim_adapters:
    input:
        fastq1="data/{sample}_1.fastq.gz",
        fastq2="data/{sample}_2.fastq.gz"
    output:
        trimmed_fastq1="trimmed_data/{sample}_1_trimmed.fastq.gz",
        trimmed_fastq2="trimmed_data/{sample}_2_trimmed.fastq.gz"
    threads: 64
    params:
        adapter=config["trimmomatic"]["adapter_file"],
        leading=config["trimmomatic"]["leading"],
        trailing=config["trimmomatic"]["trailing"],
        slidingwindow=config["trimmomatic"]["slidingwindow"],
        minlen=config["trimmomatic"]["minlen"]
    container:
        "biocontainers/trimmomatic"
    shell:
        "trimmomatic PE -threads {threads} {input.fastq1} {input.fastq2} {output.trimmed_fastq1} {output.trimmed_fastq2} ILLUMINACLIP:{params.adapter}:2:30:10 LEADING:{params.leading} TRAILING:{params.trailing} SLIDINGWINDOW:{params.slidingwindow} MINLEN:{params.minlen}"

rule align_with_bowtie2:
    input:
        trimmed_fastq1="trimmed_data/{sample}_1_trimmed.fastq.gz",
        trimmed_fastq2="trimmed_data/{sample}_2_trimmed.fastq.gz"
    output:
        bam="aligned_data/{sample}_aligned.bam"
    threads: 64
    params:
        index=config["bowtie2"]["index"]
    container:
        "biocontainers/bowtie2"
    shell:
        "bowtie2 --threads {threads} -x {params.index} -1 {input.trimmed_fastq1} -2 {input.trimmed_fastq2} | samtools view -bS - > {output.bam}"

# Rule for marking duplicates with Picard
rule mark_duplicates:
    input:
        bam="aligned_data/{sample}_aligned.bam"
    output:
        marked_bam="marked_duplicates/{sample}_marked.bam",
        metrics="marked_duplicates/{sample}_metrics.txt"
    params:
        remove_duplicates=config["picard"]["remove_duplicates"]
        jvm_opts=config["picard"]["jvm_opts"]
    container:
        "biocontainers/picard"
    shell:
        "picard MarkDuplicates I={input.bam} O={output.marked_bam} M={output.metrics} REMOVE_DUPLICATES={params.remove_duplicates} {params.jvm_opts}"

