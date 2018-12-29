#!/bin/bash
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
. "${SCRIPT_DIR}/../shared/error_handling.sh"

PACKAGES="zip rsync awscli coreutils perl docker.io mono-complete gpg"
#PACKAGES="rsync"
"${SCRIPT_DIR}/../shared/start_docker.sh" "$@" \
--dockerimage ubuntu \
--dockerpackages "$PACKAGES" \
--gpgpath "/usr/bin/gpg" \
--dockermountkeys \
--dockercommand "/pipeline/stage_deploy/job.sh"