process CNVKIT_GENEMETRICS {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::cnvkit=0.9.9 bioconda::samtools=1.16.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cnvkit:0.9.9--pyhdfd78af_0':
        'quay.io/biocontainers/cnvkit:0.9.9--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(cnr)
    tuple val (meta), path(cns)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    //tuple val(meta), path("*.cnn"), emit: cnn
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: cnr.BaseName
    def segments = cns ? "--segment ${cns[2]}" : ""

    """
    cnvkit.py \\
        genemetrics \\
        $cnr \\
        $segments \\
        --output ${prefix}.genemetrics.tsv \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cnvkit: \$(cnvkit.py version | sed -e "s/cnvkit v//g")
    END_VERSIONS
    """
}