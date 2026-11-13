#!/usr/bin/env bash

# pre-set
set -euo pipefail
set -x

env

# =======================================
# Runtime default config
# =======================================
VAR_RPM_WORKBENCH_DIR=${VAR_RPM_WORKBENCH_DIR:-/tmp/output}
VAR_GPG_PRIV_KET=${VAR_GPG_PRIV_KET:-/tmp/rpm-gpg-publish.private}
VAR_GPG_PASSPHRASE=${VAR_GPG_PASSPHRASE:-/tmp/rpm-gpg-publish.passphrase}
ARCH=${ARCH:-`(uname -m | tr '[:upper:]' '[:lower:]')`}

COS_REGION=${COS_REGION:-"ap-guangzhou"}
COS_GLOBAL_REGION=${COS_GLOBAL_REGION:-"accelerate"}
COS_PART_SIZE=${COS_PART_SIZE:-"10"}
VAR_COS_REGION_DNS="cos.${COS_REGION}.myqcloud.com"
VAR_COS_GLOBAL_REGION_DNS="cos.${COS_GLOBAL_REGION}.myqcloud.com"
# Every coscmd transfer goes through this wrapper so a transient COS failure is
# retried instead of failing the publish; see utils/cos-retry.sh.
COS_RETRY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cos-retry.sh"
export COS_RETRY

# =======================================
# GPG extension
# =======================================
func_rpmsign_macros_init() {
    cat > ~/.rpmmacros <<_EOC_
# Macros for signing RPMs.
%_signature gpg
%_gpg_path ${HOME}/.gnupg
%_gpg_name ${GPG_MAIL}
%__gpg /usr/bin/gpg
%_gpg_digest_algo sha256
%_gpg_sign_cmd_extra_args --batch --pinentry-mode loopback --passphrase-file ${VAR_GPG_PASSPHRASE}
_EOC_
}

func_rpm_sign() {
    # ${1} - rpm directory
    gpg --armor --export "${GPG_MAIL}" > /tmp/rpm-gpg-publish.public
    rpm --import /tmp/rpm-gpg-publish.public

    while IFS= read -r -d '' rpm_file; do
        echo "rpmsign for: ${rpm_file}"
        rpmsign --addsign "${rpm_file}"
        # rpmsign can exit 0 without signing, so check the signature
        rpm -Kv "${rpm_file}" | grep -iE 'signature, key (ID|fingerprint):? [0-9a-f]+: OK'
    done < <(find "${1}" -type f -name "*.rpm" -print0)
}

func_gpg_key_load() {
    # ${1} gpg private key
    # ${2} gpg key passphrase
    gpg --import --pinentry-mode loopback --batch --passphrase-file "${2}" "${1}"

    gpg --list-keys --fingerprint | grep "${GPG_MAIL}" -B 1 \
    | tr -d ' ' | head -1 | awk 'BEGIN { FS = "\n" } ; { print $1":6:" }' \
    | gpg --import-ownertrust
}

# =======================================
# COS extension
# =======================================
func_cos_utils_credential_init() {
    # ${1} - COS SECRET_ID
    # ${2} - COS SECRET_KEY
    # ${3} - COS bucket name
    coscmd config -a "${1}" -s "${2}" -b "${3}" -r ${COS_REGION} -p ${COS_PART_SIZE}
}

# =======================================
# COS repo extension
# =======================================
func_repo_init() {
    # ${1} - repo workbench path
    mkdir -p "${1}"/redhat/9/${ARCH}
}

func_repo_clone() {
    # ${1} - bucket name
    # ${2} - COS path
    # ${3} - target path

    # --part-size indicates the file chunk size.
    # when the file is larger than --part-size, coscmd will chunk the file by --part-size.
    # when uploading/downloading the file in chunks, it will enable breakpoint transfer by default,
    # which will generate cosresumabletask file and interfere with the file integrity.
    # ref: https://cloud.tencent.com/document/product/436/63669
    "${COS_RETRY}" -b "${1}"  -r "${COS_GLOBAL_REGION}" download -r "/packages/${2}" "${3}"
}

func_repo_backup() {
    # ${1} - bucket name
    # ${2} - COS path
    # ${3} - backup tag
    "${COS_RETRY}" copy -r "${1}.${VAR_COS_REGION_DNS}/packages/${2}" "/packages/backup/${2}_${3}"
}

func_repo_backup_remove() {
    # ${1} - bucket name
    # ${2} - COS path
    # ${3} - backup tag
    coscmd -b "${1}" delete -r -f "/packages/backup/${2}_${3}"
}

func_repo_repodata_rebuild() {
    # ${1} - repo parent path
    find "${1}" -type d -name "${ARCH}" \
        -exec echo "createrepo_c for: {}" \; \
        -exec rm -rf {}/repodata \; \
        -exec createrepo_c {} \;
}

func_repo_repodata_sign() {
    # ${1} - repo parent path
    # only this arch's repodata is rebuilt, the others keep their signature
    while IFS= read -r -d '' repomd; do
        echo "sign repodata for: ${repomd}"
        gpg --batch --pinentry-mode loopback --passphrase-file "${VAR_GPG_PASSPHRASE}" --detach-sign --armor "${repomd}"
    done < <(find "${1}" -type f -path "*/${ARCH}/repodata/repomd.xml" -print0)
}

func_repo_upload() {
    # ${1} - local path
    # ${2} - bucket name
    # ${3} - COS path
    coscmd -b "${2}"  delete -r -f "/packages/${3}" || true
    "${COS_RETRY}" -b "${2}" -r ${COS_GLOBAL_REGION} upload -r "${1}" "/packages/${3}"
}

func_repo_publish() {
    # ${1} - CI bucket
    # ${2} - repo publish bucket
    # ${3} - COS path
    coscmd delete -r -f "/packages/${3}" || true
    "${COS_RETRY}" -b "${2}" copy -r "${1}.${VAR_COS_REGION_DNS}/packages/${3}" "packages/${3}"
}

# =======================================
# publish utils entry
# =======================================
case_opt=$1
case ${case_opt} in
init_cos_utils)
    func_cos_utils_credential_init "${TENCENT_COS_SECRETID}" "${TENCENT_COS_SECRETKEY}" "${VAR_COS_BUCKET_REPO}"
    ;;
repo_init)
    # create basic repo directory structure
    # useful when a new repo added
    func_repo_init /tmp
    ;;
repo_backup)
    func_repo_backup "${VAR_COS_BUCKET_REPO}" "redhat" "${TAG_DATE}"
    ;;
repo_clone)
    func_repo_clone "${VAR_COS_BUCKET_REPO}" "redhat" /tmp/redhat
    ;;
repo_package_sync)
    find "${VAR_RPM_WORKBENCH_DIR}" -type f -name "*ubi9.6.${ARCH}.rpm" \
        -exec echo "repo sync for: {}" \; \
        -exec cp -a {} /tmp/redhat/9/${ARCH} \;
    ;;
repo_repodata_rebuild)
    func_repo_repodata_rebuild /tmp/redhat
    func_repo_repodata_sign /tmp/redhat
    ;;
repo_upload)
    func_repo_upload /tmp/redhat "${VAR_COS_BUCKET_CI}" "redhat"
    ;;
repo_publish)
    func_repo_publish "${VAR_COS_BUCKET_CI}" "${VAR_COS_BUCKET_REPO}" "redhat"
    ;;
repo_backup_remove)
    func_repo_backup_remove "${VAR_COS_BUCKET_REPO}" "redhat" "${TAG_DATE}"
    ;;
rpm_gpg_sign)
    func_rpmsign_macros_init
    func_gpg_key_load "${VAR_GPG_PRIV_KET}" "${VAR_GPG_PASSPHRASE}"
    func_rpm_sign "${VAR_RPM_WORKBENCH_DIR}"
    ;;
*)
    echo "Unknown method!"
esac
