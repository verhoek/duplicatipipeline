#!/bin/bash
. "$( cd "$(dirname "$0")" ; pwd -P )/../shared/error_handling.sh"

export DUPLICATI_ROOT="/application/"
declare -a FORWARD_OPTS

function get_keyfile_password () {
	if [ "z${KEYFILE_PASSWORD}" == "z" ]; then
		echo -n "Enter keyfile password: "
		read -s KEYFILE_PASSWORD
		echo

        if [ "z${KEYFILE_PASSWORD}" == "z" ]; then
            echo "No password entered, quitting"
            exit 0
        fi

        export KEYFILE_PASSWORD
	fi
}

install_oem_files () {
    SOURCE_DIR=$1
    TARGET_DIR=$2
    for n in "../oem" "../../oem" "../../../oem"
    do
        if [ -d "${SOURCE_DIR}/$n" ]; then
            echo "Installing OEM files"
            cp -R "${SOURCE_DIR}/$n" "${TARGET_DIR}/webroot/"
        fi
    done

    for n in "oem-app-name.txt" "oem-update-url.txt" "oem-update-key.txt" "oem-update-readme.txt" "oem-update-installid.txt"
    do
        for p in "../$n" "../../$n" "../../../$n"
        do
            if [ -f "${SOURCE_DIR}/$p" ]; then
                echo "Installing OEM override file"
                cp "${SOURCE_DIR}/$p" "${TARGET_DIR}"
            fi
        done
    done
}

function parse_duplicati_options () {
  RELEASE_VERSION="2.0.4.$(cat "$DUPLICATI_ROOT"/Updates/build_version.txt)"
  RELEASE_TYPE="nightly"

  while true ; do
      case "$1" in
      --version)
        RELEASE_VERSION="$2"
        ;;
      --releasetype)
        RELEASE_TYPE="$2"
        ;;
      --signingkeyfilepassword)
        SIGNING_KEYFILE_PASSWORD="$2"
        ;;
      --gittag)
        GIT_TAG="$2"
        ;;
      --workingdir)
        WORKING_DIR="$2"
        ;;
      --dockerrepo)
        DOCKER_REPO="$2"
        ;;
      --*)
        if [[ $2 =~ ^--.* || -z $2 ]]; then
          FORWARD_OPTS[${#FORWARD_OPTS[@]}]="$1"
        else
          FORWARD_OPTS[${#FORWARD_OPTS[@]}]="$1"
          FORWARD_OPTS[${#FORWARD_OPTS[@]}]="$2"
        fi
        ;;
      * )
        break
        ;;
      esac
      if [[ $2 =~ ^--.* || -z $2 ]]; then
        shift
      else
        shift
        shift
      fi
  done

  export WORKING_DIR
  export RELEASE_VERSION
  export DOCKER_REPO
  export RELEASE_TYPE="$RELEASE_TYPE"
  export RELEASE_CHANGELOG_FILE="${DUPLICATI_ROOT}/changelog.txt"
  export RELEASE_CHANGELOG_NEWS_FILE="${DUPLICATI_ROOT}/changelog-news.txt" # never in repo due to .gitignore
  export RELEASE_TIMESTAMP=$(date +%Y-%m-%d)
  export RELEASE_NAME="${RELEASE_VERSION}_${RELEASE_TYPE}_${RELEASE_TIMESTAMP}"
  export RELEASE_FILE_NAME="duplicati-${RELEASE_NAME}"
  export RELEASE_NAME_SIMPLE="duplicati-${RELEASE_VERSION}"
  export UPDATE_SOURCE="${DUPLICATI_ROOT}/Updates/build/${RELEASE_TYPE}_source-${RELEASE_VERSION}"
  export UPDATE_TARGET="${DUPLICATI_ROOT}/Updates/build/${RELEASE_TYPE}_target-${RELEASE_VERSION}"
  export ZIPFILE="${UPDATE_TARGET}/${RELEASE_FILE_NAME}.zip"
#  BUILDTAG_RAW=$(echo "${RELEASE_FILE_NAME}" | cut -d "." -f 1-4 | cut -d "-" -f 2-4)
  export AUTHENTICODE_PFXFILE="${HOME}/.config/signkeys/Duplicati/authenticode.pfx"
  export AUTHENTICODE_PASSWORD="${HOME}/.config/signkeys/Duplicati/authenticode.key"
  export BUILDTAG="${RELEASE_TYPE}_${RELEASE_TIMESTAMP}_${GIT_TAG}"
  export BUILDTAG=${BUILDTAG//-}
}
