#!/usr/bin/env bash
set -euo pipefail

# Retrying wrapper around coscmd: `utils/cos-retry.sh <coscmd args...>`.
#
# coscmd gives every transfer exactly one attempt. Files below its multipart floor
# (20MB, clamped in coscmd itself) take the single_upload path, which issues one
# request and gives up on any error, and the underlying SDK deliberately skips
# retries for 4xx. COS answers a stalled cross-border transfer with 400
# UserNetworkTooSlow, so a single network hiccup is enough to fail a publish job.
#
# coscmd's own --timeout bounds waiting for a response, not the sending of a slow
# request body, so a stalled attempt can hang for many minutes before COS cuts it
# off — hence the external per-attempt timeout.
#
# This is a standalone script rather than a shell function because some call sites
# run coscmd from `find -exec sh -c`, where the caller's functions do not exist.
#
# The COS steps of these publish jobs finish in tens of seconds, so a 300s window
# is ample per attempt and keeps the whole budget -- 3 * (300s + 30s kill grace)
# plus 45s of backoff, under 18 minutes -- inside the shortest publish job, which
# has 60 minutes and spends around 10 of them building.
#
# Tunables (env): COS_RETRY_ATTEMPTS, COS_RETRY_TIMEOUT (seconds, per attempt),
# COS_RETRY_BACKOFF (seconds, multiplied by the attempt number).

COS_RETRY_ATTEMPTS=${COS_RETRY_ATTEMPTS:-3}
COS_RETRY_TIMEOUT=${COS_RETRY_TIMEOUT:-300}
COS_RETRY_BACKOFF=${COS_RETRY_BACKOFF:-15}

# A non-positive attempt count would run the loop zero times and exit 0, reporting
# a successful transfer that never happened.
case ${COS_RETRY_ATTEMPTS} in
'' | *[!0-9]* | 0)
    echo "cos-retry: COS_RETRY_ATTEMPTS must be a positive integer, got '${COS_RETRY_ATTEMPTS}'" >&2
    exit 1
    ;;
esac

if [ "$#" -eq 0 ]; then
    echo "usage: $0 <coscmd args...>" >&2
    exit 1
fi

for attempt in $(seq 1 "${COS_RETRY_ATTEMPTS}"); do
    status=0
    timeout --kill-after=30s "${COS_RETRY_TIMEOUT}" coscmd "$@" || status=$?

    if [ "${status}" -eq 0 ]; then
        exit 0
    fi

    if [ "${attempt}" -eq "${COS_RETRY_ATTEMPTS}" ]; then
        echo "cos-retry: coscmd $* failed after ${COS_RETRY_ATTEMPTS} attempts (last exit ${status})" >&2
        exit "${status}"
    fi

    delay=$((COS_RETRY_BACKOFF * attempt))
    echo "cos-retry: attempt ${attempt}/${COS_RETRY_ATTEMPTS} failed (exit ${status}), retrying in ${delay}s" >&2
    sleep "${delay}"
done
