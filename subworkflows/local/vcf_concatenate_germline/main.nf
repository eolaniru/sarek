//
// CONCATENATE Germline VCFs
//

// Concatenation of germline vcf-files
include { ADD_INFO_TO_VCF                                     } from '../../../modules/local/add_info_to_vcf/main'
include { TABIX_BGZIPTABIX as TABIX_EXT_VCF                   } from '../../../modules/nf-core/tabix/bgziptabix/main'
include { BCFTOOLS_NORM    as GERMLINE_VCFS_NORM              } from '../../../modules/nf-core/bcftools/norm/main'
include { TABIX_TABIX      as TABIX_NORMALISE                 } from '../../../modules/nf-core/tabix/tabix/main'
include { BCFTOOLS_CONCAT  as GERMLINE_VCFS_CONCAT            } from '../../../modules/nf-core/bcftools/concat/main'
include { BCFTOOLS_SORT    as GERMLINE_VCFS_CONCAT_SORT       } from '../../../modules/nf-core/bcftools/sort/main'
include { TABIX_TABIX      as TABIX_GERMLINE_VCFS_CONCAT_SORT } from '../../../modules/nf-core/tabix/tabix/main'

workflow CONCATENATE_GERMLINE_VCFS {

    take:
    vcfs
    fasta

    main:
    versions = Channel.empty()

    // Concatenate vcf-files
    ADD_INFO_TO_VCF(vcfs)
    TABIX_EXT_VCF(ADD_INFO_TO_VCF.out.vcf)

    // Normalize the VCF files with BCFTOOLS_NORM
    GERMLINE_VCFS_NORM(TABIX_EXT_VCF.out.gz_tbi, fasta)

    // index normalised vcf
    TABIX_NORMALISE(GERMLINE_VCFS_NORM.out.vcf)

    // Gather vcfs and vcf-tbis for concatenating germline-vcfs
    germline_vcfs_with_tbis = GERMLINE_VCFS_NORM.out.vcf
                                    .join(TABIX_NORMALISE.out.tbi)
                                    .map{ meta, vcf, tbi -> [ meta.subMap('id'), vcf, tbi ] }.groupTuple()

    GERMLINE_VCFS_CONCAT(germline_vcfs_with_tbis)
    GERMLINE_VCFS_CONCAT_SORT(GERMLINE_VCFS_CONCAT.out.vcf)
    TABIX_GERMLINE_VCFS_CONCAT_SORT(GERMLINE_VCFS_CONCAT_SORT.out.vcf)

    //all_germline_vcfs_with_tbis = GERMLINE_VCFS_CONCAT_SORT.out.vcf //this is not used elsewhere
                                        //.join(TABIX_GERMLINE_VCFS_CONCAT_SORT.out.tbi, failOnDuplicate: true, failOnMismatch: true)

    // Gather versions of all tools used
    versions = versions.mix(ADD_INFO_TO_VCF.out.versions)
    versions = versions.mix(TABIX_EXT_VCF.out.versions)
    versions = versions.mix(GERMLINE_VCFS_NORM.out.versions)
    versions = versions.mix(GERMLINE_VCFS_NORM.out.versions)
    versions = versions.mix(GERMLINE_VCFS_CONCAT.out.versions)
    versions = versions.mix(GERMLINE_VCFS_CONCAT_SORT.out.versions)
    versions = versions.mix(TABIX_GERMLINE_VCFS_CONCAT_SORT.out.versions)

    emit:
   // vcfs = all_germline_vcfs_with_tbis // commenting out as not used elsewhere //post processed vcfs 

    versions // channel: [ versions.yml ]
}
