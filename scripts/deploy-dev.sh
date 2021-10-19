#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
MarketFactoryAddr=$(deploy MarketFactory)
MarketRouterAddr=$(deploy MarketRouter "$MarketFactoryAddr")
OracleMultiSig=$(deploy OracleMultiSig "[$ETH_FROM]" 1 10)

log "MarketFactory deployed at:" $MarketFactoryAddr
log "MarketRouterAddr deployed at:" $MarketRouterAddr
log "OracleMultiSig deployed at:" $OracleMultiSig

seth send $OracleMultiSig "addTxSetupOracle(bool,uint256,uint256,address,uint256,uint256,uint256,uint256)" true 10 10 $MarketRouterAddr 10 10 10 10 --gas 550000

# check gas prices for txs now