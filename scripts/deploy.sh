#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

NAME=OracleMultiSig
# Deploy.
Contract=$(deploy $NAME "" "[0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6]" 1 10 0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6)
log "$NAME deployed at:" $Contract