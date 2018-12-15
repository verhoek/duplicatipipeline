#!/bin/bash
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
. "${SCRIPT_DIR}/../shared.sh"

function setup () {
    apt-get update && apt-get install -y wget unzip
    nuget install NUnit.Runners -Version 3.5.0 -OutputDirectory testrunner
}

parse_options "$@"
travis_mark_begin "SETUP DOCKER IMAGE"
setup
travis_mark_end "SETUP DOCKER IMAGE"
