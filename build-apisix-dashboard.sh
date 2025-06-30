#!/usr/bin/env bash
set -euo pipefail
set -x

cd $1
source .requirements
if [ -z "${APISIX_DASHBOARD_COMMIT:-}" ]; then
    echo "Error: APISIX_DASHBOARD_COMMIT is not set or empty"
    exit 1
fi
git clone --revision=${APISIX_DASHBOARD_COMMIT} --depth 1 https://github.com/apache/apisix-dashboard.git
pushd apisix-dashboard
# compile
pnpm install --frozen-lockfile
pnpm run build
popd
# copy the dist files to the ui directory
mkdir ui
cp -r apisix-dashboard/dist/* ui/
rm -rf apisix-dashboard
