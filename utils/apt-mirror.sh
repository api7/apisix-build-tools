#!/usr/bin/env sh
# Make apt in the Debian/Ubuntu build images survive a mirror outage: retry
# every download and, on Ubuntu, try the Azure mirror next to the GitHub
# runners before the official archive and security servers. ports.ubuntu.com
# (arm64) has no Azure mirror and is left as is.
set -eu

[ -d /etc/apt ] || exit 0

echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries

. /etc/os-release
[ "${ID:-}" = ubuntu ] || exit 0

printf '%s\tpriority:%s\n' \
    http://azure.archive.ubuntu.com/ubuntu/ 1 \
    http://archive.ubuntu.com/ubuntu/ 2 \
    http://security.ubuntu.com/ubuntu/ 3 \
    > /etc/apt/apt-mirrors.txt

# focal and jammy use sources.list, noble uses deb822 ubuntu.sources
for f in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
    [ -f "$f" ] || continue
    sed -i -E 's#http://(archive|security)\.ubuntu\.com/ubuntu/?#mirror+file:/etc/apt/apt-mirrors.txt#g' "$f"
done
