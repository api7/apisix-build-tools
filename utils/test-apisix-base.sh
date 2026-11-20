#!/usr/bin/env bash
# Smoke test a built apisix-base: start it with an HTTP/2 TLS listener and send
# requests from the host.
#
# Usage:
#   test-apisix-base.sh rpm <path to el7 rpm>   # installed into a clean centos:7
#   test-apisix-base.sh image <image ref>       # the apk based image
set -euo pipefail

mode=$1
target=$2
name=apisix-base-smoke-test
port=19443
workdir=$(mktemp -d)
trap 'docker rm -f "$name" >/dev/null 2>&1 || true; rm -rf "$workdir"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=test \
    -keyout "$workdir/key.pem" -out "$workdir/cert.pem" 2>/dev/null
chmod 644 "$workdir/key.pem"
mkdir -p "$workdir/conf"
cat > "$workdir/conf/nginx.conf" <<'EOF'
daemon off;
error_log logs/error.log info;
events {}
http {
    server {
        listen 9443 ssl http2;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_certificate /t/cert.pem;
        ssl_certificate_key /t/key.pem;

        location / {
            content_by_lua_block {
                ngx.print(string.rep("a", 2 * 1024 * 1024))
            }
        }

        location /echo {
            client_max_body_size 4m;
            client_body_buffer_size 4m;
            content_by_lua_block {
                ngx.req.read_body()
                ngx.print(#(ngx.req.get_body_data() or ""))
            }
        }
    }
}
EOF

start='openresty -V; cp -r /t/conf /srv/ && mkdir -p /srv/logs && exec openresty -p /srv'
case "$mode" in
rpm)
    docker run -d --name "$name" -p "127.0.0.1:$port:9443" \
        -v "$(realpath "$target"):/pkg/apisix-base.rpm:ro" \
        -v "$workdir:/t:ro" \
        -v "$(dirname "$(realpath "$0")")/build-common.sh:/build-common.sh:ro" \
        centos:7 bash -c "set -e
            bash /build-common.sh use_centos7_vault
            yum install -y yum-utils
            yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
            yum install -y /pkg/apisix-base.rpm
            export PATH=\$PATH:/usr/local/openresty/bin
            $start" >/dev/null
    ;;
image)
    docker run -d --name "$name" -p "127.0.0.1:$port:9443" \
        -v "$workdir:/t:ro" "$target" sh -c "$start" >/dev/null
    ;;
*)
    echo "unknown mode: $mode" >&2
    exit 1
    ;;
esac

for _ in $(seq 1 300); do
    if curl -sk -o /dev/null "https://127.0.0.1:$port/"; then
        break
    fi
    if [ -z "$(docker ps -q --filter "name=^$name$")" ]; then
        break
    fi
    sleep 2
done
docker logs "$name" 2>&1 | grep -E "^(nginx version|built |configure arguments)" || true

body=$(mktemp)
head -c 1500000 /dev/zero > "$body"
failed=0
check() {
    local desc=$1 expect=$2 got=$3
    if [ "$got" = "$expect" ]; then
        echo "ok: $desc"
    else
        echo "FAILED: $desc: expected '$expect', got '$got'"
        failed=1
    fi
}

for v in 1.2 1.3; do
    tls=(--tlsv"$v" --tls-max "$v")
    check "TLSv$v HTTP/2 GET 2 MB" "2 2097152" \
        "$(curl -sk --http2 "${tls[@]}" -o /dev/null -w '%{http_version} %{size_download}' "https://127.0.0.1:$port/" || true)"
    check "TLSv$v HTTP/2 POST 1.5 MB" "1500000" \
        "$(curl -sk --http2 "${tls[@]}" --data-binary @"$body" "https://127.0.0.1:$port/echo" || true)"
    check "TLSv$v HTTP/1.1 chunked POST 1.5 MB" "1500000" \
        "$(curl -sk --http1.1 "${tls[@]}" -H 'Transfer-Encoding: chunked' --data-binary @"$body" "https://127.0.0.1:$port/echo" || true)"
done
rm -f "$body"

errors=$(docker exec "$name" grep -E '\[(alert|crit|emerg|error)\]' /srv/logs/error.log || true)
check "no error in error.log" "" "$errors"

if [ "$failed" != 0 ]; then
    docker logs "$name" 2>&1 | tail -50
    exit 1
fi
