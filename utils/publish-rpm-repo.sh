#!/usr/bin/env bash

# pre-set
set -euo pipefail
set -x

# =======================================
# OSS default config
# =======================================
VAR_ALIYUN_OSS_UTILS_VERSION=${VAR_ALIYUN_OSS_UTILS_VERSION:-1.7.10}

# =======================================
# GPG extension
# =======================================
func_gpg_config_init() {
    cat > ~/.rpmmacros <<_EOC_
# Macros for signing RPMs.
%_signature gpg
%_gpg_path ${HOME}/.gnupg
%_gpg_name ${GPG_NAME} ${GPG_MAIL}
%_gpgbin /usr/bin/gpg
%__gpg_sign_cmd %{__gpg} gpg --batch --verbose --no-armor --pinentry-mode loopback --passphrase-file /tmp/rpm-gpg-publish.passphrase --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}
_EOC_
}

# =======================================
# OSS extension
# =======================================
func_oss_utils_install() {
    # ${1} - oss util version
    curl -o /usr/bin/ossutil64 "http://gosspublic.alicdn.com/ossutil/${1}/ossutil64"
    chmod 755 /usr/bin/ossutil64
}

func_oss_utils_credential_init() {
    # ${1} - oss util config path
    # ${2} - oss endpoint
    # ${3} - ACCESS_KEY_ID
    # ${4} - ACCESS_KEY_SECRET
    cat <<_EOC_ > "${1}"
[Credentials]
language=EN
endpoint=${2}
accessKeyID=${3}
accessKeySecret=${4}
_EOC_
}

# =======================================
# OSS repo extension
# =======================================
func_repo_clone() {
    # ${1} - bucket name
    # ${2} - oss path
    # ${3} - target path
    ossutil64 cp -r "oss://${1}/packages/${2}" "${3}"
}

func_repo_backup() {
    # ${1} - bucket name
    # ${2} - oss path
    # ${3} - backup tag
    ossutil64 cp -r "oss://${1}/packages/${2}" "oss://${1}/packages/backup/${2}_${3}"
}

func_repo_backup_remove() {
    # ${1} - bucket name
    # ${2} - oss path
    # ${3} - backup tag
    ossutil64 rm -r -f "oss://${1}/packages/backup/${2}_${3}"
}

func_repo_metadata_sign() {
    rm ./x86_64/repodata/repomd.xml.asc
    gpg --batch --pinentry-mode loopback --passphrase-file /tmp/rpm-gpg-publish.passphrase --detach-sign --armor ./x86_64/repodata/repomd.xml

    out=$(gpg --verify x86_64/repodata/repomd.xml.asc 2>&1)
    if ! echo "$out" | grep -iq 'Good signature'; then
        echo "failed: check rpm metadata signatures"
        exit 1
    fi
}

func_repo_metadata_rebuild() {
    createrepo .
}

func_repo_upload() {
    # ${1} - local path
    # ${2} - bucket name
    # ${3} - oss path
    ossutil64 rm -r -f "oss://${2}/packages/${3}"
    ossutil64 cp -r ${1} "oss://${2}/packages/${3}"
}

case_opt=$1

case ${case_opt} in
init_oss_utils)
    func_oss_utils_install ${VAR_ALIYUN_OSS_UTILS_VERSION}
    func_oss_utils_credential_init ~/.ossutilconfig "endpoint=oss-cn-shenzhen.aliyuncs.com" "${ACCESS_KEY_ID}" "${ACCESS_KEY_SECRET}"
    ;;
esac
