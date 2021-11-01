#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

NAME=MarketRouter
# Deploy.
Contract=$(deploy $NAME "" 0xD4D664D419A6A845C98Cc366ae1c4b24592BD5CE)
log "$NAME deployed at:" $Contract