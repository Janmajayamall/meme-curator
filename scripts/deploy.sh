#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

NAME=OutcomeToken
# Deploy.
Contract=$(deploy $NAME)
log "$NAME deployed at:" $Contract