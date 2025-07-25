process ANTISMASH_ANTISMASHLITEDOWNLOADDATABASES {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/antismash-lite:7.1.0--pyhdfd78af_0'
        : 'biocontainers/antismash-lite:7.1.0--pyhdfd78af_0'}"

    /*
    These files are normally downloaded/created by download-antismash-databases itself, and must be retrieved for input by manually running the command with conda or a standalone installation of antiSMASH. Therefore we do not recommend using this module for production pipelines, but rather require users to specify their own local copy of the antiSMASH database in pipelines. This is solely for use for CI tests of the nf-core/module version of antiSMASH.
    Reason: Upon execution, the tool checks if certain database files are present within the container and if not, it tries to create them in /usr/local/bin, for which only root user has write permissions. Mounting those database files with this module prevents the tool from trying to create them.
    These files are also emitted as output channels in this module to enable the antismash-lite module to use them as mount volumes to the docker/singularity containers.
    */

    containerOptions {
        ['singularity', 'apptainer'].contains(workflow.containerEngine)
            ? "-B ${database_css}:/usr/local/lib/python3.10/site-packages/antismash/outputs/html/css,${database_detection}:/usr/local/lib/python3.10/site-packages/antismash/detection,${database_modules}:/usr/local/lib/python3.10/site-packages/antismash/modules"
            : workflow.containerEngine == 'docker'
                ? "-v \$PWD/${database_css}:/usr/local/lib/python3.10/site-packages/antismash/outputs/html/css -v \$PWD/${database_detection}:/usr/local/lib/python3.10/site-packages/antismash/detection -v \$PWD/${database_modules}:/usr/local/lib/python3.10/site-packages/antismash/modules"
                : ''
    }

    input:
    path database_css
    path database_detection
    path database_modules

    output:
    path ("antismash_db"), emit: database
    path ("antismash_dir"), emit: antismash_dir
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def deprecation_message = """
        WARNING: This module has been deprecated. Please use nf-core/modules/antismash/antismashdownaddatabases

        Reason:
        This module includes non-standard workarounds to allow for use with container engines, due to database caching systems with antiSMASH not being compatible with the biocontainers build system.
        The new module antismash/antismashdownloaddatabases uses a different nf-core hosted container that works around this issue, thus providing a much better developer and user experience.

    """

    assert false: deprecation_message
    def args = task.ext.args ?: ''
    cp_cmd = workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1 ?
        "cp -r \$(python -c 'import antismash;print(antismash.__file__.split(\"/__\")[0])') antismash_dir;" :
        "cp -r /usr/local/lib/python3.10/site-packages/antismash antismash_dir;"
    """
    download-antismash-databases \\
        --database-dir antismash_db \\
        ${args}

    ${cp_cmd}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        antismash-lite: \$(echo \$(antismash --version) | sed 's/antiSMASH //;s/-.*//g')
    END_VERSIONS
    """

    stub:
    def deprecation_message = """
        WARNING: This module has been deprecated. Please use nf-core/modules/antismash/antismash

        Reason:
        This module includes non-standard workarounds to allow for use with container engines, due to database caching systems with antiSMASH not being compatible with the biocontainers build system.
        The new module antismash/antismash uses a different nf-core hosted container that works around this issue, thus providing a much better developer and user experience.

    """

    assert false: deprecation_message
    def args = task.ext.args ?: ''
    cp_cmd = workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1 ?
        "cp -r \$(python -c 'import antismash;print(antismash.__file__.split(\"/__\")[0])') antismash_dir;" :
        "cp -r /usr/local/lib/python3.10/site-packages/antismash antismash_dir;"
    """
    echo "download-antismash-databases --database-dir antismash_db ${args}"

    echo "${cp_cmd}"

    mkdir antismash_dir
    mkdir antismash_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        antismash-lite: \$(echo \$(antismash --version) | sed 's/antiSMASH //;s/-.*//g')
    END_VERSIONS
    """
}
