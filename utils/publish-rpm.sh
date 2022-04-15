#!/usr/bin/env bash

# pre-set
set -euo pipefail
set -x

# =======================================
# Runtime default config
# =======================================
VAR_ALIYUN_OSS_UTILS_VERSION=${VAR_ALIYUN_OSS_UTILS_VERSION:-1.7.10}
VAR_RPM_WORKBENCH_DIR=${VAR_RPM_WORKBENCH_DIR:-/tmp/output}
VAR_GPG_PRIV_KET=${VAR_GPG_PRIV_KET:-/tmp/rpm-gpg-publish.private}
VAR_GPG_PASSPHRASE=${VAR_GPG_PASSPHRASE:-/tmp/rpm-gpg-publish.passphrase}

# =======================================
# GPG extension
# =======================================
func_rpmsign_macros_init() {
    cat > ~/.rpmmacros <<_EOC_
# Macros for signing RPMs.
%_signature gpg
%_gpg_path ${HOME}/.gnupg
%_gpg_name ${GPG_NAME} ${GPG_MAIL}
%_gpgbin /usr/bin/gpg
%__gpg_sign_cmd %{__gpg} gpg --batch --verbose --no-armor --pinentry-mode loopback --passphrase-file ${VAR_GPG_PASSPHRASE} --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}
_EOC_
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
# OSS extension
# =======================================
func_oss_utils_install() {
    # ${1} - OSS util version
    curl -o /usr/bin/ossutil64 "http://gosspublic.alicdn.com/ossutil/${1}/ossutil64"
    chmod 755 /usr/bin/ossutil64
}

func_oss_utils_credential_init() {
    # ${1} - OSS endpoint
    # ${2} - ACCESS_KEY_ID
    # ${3} - ACCESS_KEY_SECRET
    cat > "$(eval echo ~${USER})/.ossutilconfig" <<_EOC_
[Credentials]
language=EN
endpoint=${1}
accessKeyID=${2}
accessKeySecret=${3}
_EOC_
}

# =======================================
# OSS repo extension
# =======================================
func_repo_init() {
    # ${1} - repo workbench path
    mkdir -p "${1}"/centos/{7,8}/x86_64
}

func_repo_clone() {
    # ${1} - bucket name
    # ${2} - OSS path
    # ${3} - target path
    ossutil64 cp -r -f "oss://${1}/packages/${2}" "${3}"
}

func_repo_backup() {
    # ${1} - bucket name
    # ${2} - OSS path
    # ${3} - backup tag
    ossutil64 cp -r "oss://${1}/packages/${2}" "oss://${1}/packages/backup/${2}_${3}"
}

func_repo_backup_remove() {
    # ${1} - bucket name
    # ${2} - OSS path
    # ${3} - backup tag
    ossutil64 rm -r -f "oss://${1}/packages/backup/${2}_${3}"
}

func_repo_repodata_rebuild() {
    # ${1} - repo parent path
    find "${1}" -type d -name "x86_64" \
        -exec echo "createrepo for: {}" \; \
        -exec rm -rf {}/repodata \; \
        -exec createrepo {} \;
}

func_repo_repodata_sign() {
    # ${1} - repo parent path
    find "${1}" -type f -name "*repomd.xml" \
        -exec echo "sign repodata for: {}" \; \
        -exec gpg --batch --pinentry-mode loopback --passphrase-file "${VAR_GPG_PASSPHRASE}" --detach-sign --armor {} \;
}

func_repo_upload() {
    # ${1} - local path
    # ${2} - bucket name
    # ${3} - OSS path
    ossutil64 rm -r -f "oss://${2}/packages/${3}"
    ossutil64 cp -r "${1}" "oss://${2}/packages/${3}"
}

func_repo_publish() {
    # ${1} - CI bucket
    # ${2} - repo publish bucket
    # ${3} - OSS path
    ossutil64 rm -r -f "oss://${2}/packages/${3}"
    ossutil64 cp -r "oss://${1}/packages/${3}" "oss://${2}/packages/${3}"
}

# =======================================
# publish utils entry
# =======================================
case_opt=$1

case ${case_opt} in
init_oss_utils)
    func_oss_utils_install "${VAR_ALIYUN_OSS_UTILS_VERSION}"
    func_oss_utils_credential_init "${VAR_OSS_ENDPOINT}" "${ACCESS_KEY_ID}" "${ACCESS_KEY_SECRET}"
    ;;
repo_init)
    # create basic repo directory structure
    # useful when a new repo added
    func_repo_init /tmp
    ;;
repo_backup)
    func_repo_backup "${VAR_OSS_BUCKET_REPO}" "centos" "${TAG_DATE}"
    ;;
repo_clone)
    func_repo_clone "${VAR_OSS_BUCKET_REPO}" "centos" /tmp
    ;;
repo_package_sync)
    VAR_REPO_MAJOR_VER=(7 8)
    for i in "${VAR_REPO_MAJOR_VER[@]}"; do
        find "${VAR_RPM_WORKBENCH_DIR}" -type f -name "*el${i}.x86_64.rpm" \
            -exec echo "repo sync for: {}" \; \
            -exec cp -a {} /tmp/centos/"${i}"/x86_64 \;
    done
    ;;
repo_repodata_rebuild)
    func_repo_repodata_rebuild /tmp/centos
    func_repo_repodata_sign /tmp/centos
    ;;
repo_upload)
    func_repo_upload /tmp/centos "${VAR_OSS_BUCKET_CI}" "centos"
    ;;
repo_publish)
    func_repo_publish "${VAR_OSS_BUCKET_CI}" "${VAR_OSS_BUCKET_REPO}" "centos"
    ;;
repo_backup_remove)
    func_repo_backup_remove "${VAR_OSS_BUCKET_REPO}" "centos" "${TAG_DATE}"
    ;;
rpm_gpg_sign)
    func_rpmsign_macros_init
    func_gpg_key_load "${VAR_GPG_PRIV_KET}" "${VAR_GPG_PASSPHRASE}"

    find "${VAR_RPM_WORKBENCH_DIR}" -type f -name "*.rpm" \
        -exec echo "rpmsign for: {}" \; \
        -exec rpmsign --addsign {} \;
    ;;
*)
    echo "Unknown method!"
esac
