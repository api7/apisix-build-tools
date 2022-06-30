#!/usr/bin/env bash

# pre-set
set -euo pipefail
set -x

env

# =======================================
# Runtime default config
# =======================================
VAR_TENCENT_COS_UTILS_VERSION=${VAR_TENCENT_COS_UTILS_VERSION:-v0.11.0-beta}
VAR_DEB_WORKBENCH_DIR=${VAR_DEB_WORKBENCH_DIR:-/tmp/output}

# =======================================
# COS extension
# =======================================
func_cos_utils_install() {
    # ${1} - COS util version
    curl -o /usr/bin/coscli -L "https://github.com/tencentyun/coscli/releases/download/${1}/coscli-linux"
    chmod 755 /usr/bin/coscli
}

func_cos_utils_credential_init() {
    # ${1} - COS endpoint
    # ${2} - COS SECRET_ID
    # ${3} - COS SECRET_KEY
    cat > "${HOME}/.cos.yaml" <<_EOC_
cos:
  base:
    secretid: ${2}
    secretkey: ${3}
    sessiontoken: ""
    protocol: https
_EOC_
}


func_repo_upload() {
    # ${1} - local path
    # ${2} - bucket name
    # ${3} - COS path
    find "${1}" -type f -name "*.deb" \
        -exec echo "upload : {}" \; \
        -exec coscli -e "${VAR_COS_ENDPOINT}" cp -r {} "cos://${2}/packages/${3}/pool/main/a" \;
}

func_repo_publish() {
    # ${1} - CI bucket
    # ${2} - repo publish bucket
    # ${3} - COS path
    coscli -e "${VAR_COS_ENDPOINT}" rm -r -f "cos://${2}/packages/${3}" || true
    coscli -e "${VAR_COS_ENDPOINT}" cp -r "cos://${1}/packages/${3}" "cos://${2}/packages/${3}"
}

# =======================================
# publish utils entry
# =======================================
case_opt=$1

case ${case_opt} in
init_cos_utils)
    func_cos_utils_install "${VAR_TENCENT_COS_UTILS_VERSION}"
    func_cos_utils_credential_init "${VAR_COS_ENDPOINT}" "${TENCENT_COS_SECRETID}" "${TENCENT_COS_SECRETKEY}"
    ;;
repo_upload)
    func_repo_upload "${VAR_DEB_WORKBENCH_DIR}" "${VAR_COS_BUCKET_CI}" "debian"
    ;;
repo_publish)
    func_repo_publish "${VAR_COS_BUCKET_CI}" "${VAR_COS_BUCKET_REPO}" "debian"
    ;;
*)
    echo "Unknown method!"
esac
