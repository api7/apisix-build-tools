#!/usr/bin/env bash
set -euo pipefail
set -x


import_gpg_key() {
    gpg --import --pinentry-mode loopback --batch --passphrase-file \
    /tmp/rpm-gpg-publish.passphrase /tmp/rpm-gpg-publish.private

    gpg --list-keys --fingerprint | grep "${GPG_MAIL}" -B 1 \
    | tr -d ' ' | head -1 | awk 'BEGIN { FS = "\n" } ; { print $1":6:" }' \
    | gpg --import-ownertrust
}



rpm_checksig() {
    rpm --import https://repos.apiseven.com/KEYS

    out=$(rpm --checksig ./${TARGET_APP}-${TAG_VERSION}-0.el7.x86_64.rpm)
    if ! echo "$out" | grep "digests signatures OK"; then
        echo "failed: check rpm digests signatures"
        exit 1
    fi
}


init_rpmmacros() {
    cat > ~/.rpmmacros <<EOF
# Macros for signing RPMs.
%_signature gpg
%_gpg_path ${HOME}/.gnupg
%_gpg_name ${GPG_NAME} ${GPG_MAIL}
%_gpgbin /usr/bin/gpg
%__gpg_sign_cmd %{__gpg} gpg --batch --verbose --no-armor --pinentry-mode loopback --passphrase-file /tmp/rpm-gpg-publish.passphrase --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}
EOF
}


sign_target_app_rpm() {
    import_gpg_key

    init_rpmmacros

    rpmsign --addsign ./${TARGET_APP}-${TAG_VERSION}-0.el7.x86_64.rpm

    rpm_checksig
}


download_ossutil64() {
    echo "[Credentials]" >> /tmp/ossutilconfig
    echo "language=EN" >> /tmp/ossutilconfig
    echo "endpoint=oss-cn-shenzhen.aliyuncs.com" >> /tmp/ossutilconfig
    echo "accessKeyID=${ACCESS_KEY_ID}" >> /tmp/ossutilconfig
    echo "accessKeySecret=${ACCESS_KEY_SECRET}" >> /tmp/ossutilconfig
    wget http://gosspublic.alicdn.com/ossutil/1.7.3/ossutil64
    chmod 755 ossutil64
}


backup_and_rebuild_repo() {
    download_ossutil64

    # backup origin repo
    ./ossutil64 cp -r oss://apisix-repo/packages/centos/7/x86_64 oss://apisix-repo/packages/backup/centos/7/x86_64_${DATE_TAG} --config-file=/tmp/ossutilconfig

    # download origin repo
    ./ossutil64 cp -r oss://apisix-repo/packages/centos/7/x86_64 ./ --config-file=/tmp/ossutilconfig

    # rebuild repo
    cp ./${TARGET_APP}-${TAG_VERSION}-0.el7.x86_64.rpm ./x86_64
    cd ./x86_64

    sudo apt-get update
    sudo apt install createrepo -y
    createrepo .
    cd ../
}


sign_repo_metadata() {
    rm ./x86_64/repodata/repomd.xml.asc
    gpg --batch --pinentry-mode loopback --passphrase-file /tmp/rpm-gpg-publish.passphrase --detach-sign --armor ./x86_64/repodata/repomd.xml

    out=$(gpg --verify x86_64/repodata/repomd.xml.asc 2>&1)
    if ! echo "$out" | grep -iq 'Good signature'; then
        echo "failed: check rpm metadata signatures"
        exit 1
    fi
}


upload_new_repo() {
    # rm origin repo and upload new repo
    ./ossutil64 rm -r -f oss://apisix-repo/packages/centos/7/x86_64 --config-file=/tmp/ossutilconfig
    ./ossutil64 cp -r ./x86_64 oss://apisix-repo/packages/centos/7/x86_64 --config-file=/tmp/ossutilconfig
}


check_down_load_rpm() {
    mkdir temp && cd temp
    wget https://apisix-repo.oss-cn-shenzhen.aliyuncs.com/packages/centos/7/x86_64/${TARGET_APP}-${TAG_VERSION}-0.el7.x86_64.rpm
    if [ ! -f ${TARGET_APP}-${TAG_VERSION}-0.el7.x86_64.rpm ]; then
        echo "failed: download new ${TARGET_APP} rpm package"
        exit 1
    fi
    cd ../
}


rm_backup_repo() {
    ./ossutil64 rm -r -f oss://apisix-repo/packages/backup/centos/7/x86_64_${DATE_TAG} --config-file=/tmp/ossutilconfig
}


case_opt=$1

case ${case_opt} in
sign_target_app_rpm)
    sign_target_app_rpm
    ;;
backup_and_rebuild_repo)
    backup_and_rebuild_repo
    ;;
sign_repo_metadata)
    sign_repo_metadata
    ;;
upload_new_repo)
    upload_new_repo
    ;;
check_down_load_rpm)
    check_down_load_rpm
    ;;
rm_backup_repo)
    rm_backup_repo
    ;;
esac
