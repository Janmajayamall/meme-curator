#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
MarketFactory=$(deploy MarketFactory "")
MarketRouter=$(deploy MarketRouter "" "$MarketFactory")
OracleMultiSig=$(deploy OracleMultiSig "" "[$ETH_FROM]" 1 10)
MemeToken=$(deploy MemeToken "")
ContractHelper=$(deploy ContractHelper helpers/)
export MarketFactory=$MarketFactory
export MarketRouter=$MarketRouter
export OracleMultiSig=$OracleMultiSig
export MemeToken=$MemeToken
export ETH_FROM=$ETH_FROM
export ContractHelper=$ContractHelper

log "MarketFactory deployed at:" $MarketFactory
log "MarketRouter deployed at:" $MarketRouter
log "OracleMultiSig deployed at:" $OracleMultiSig
log "MemeToken deployed at:" $MemeToken
log "ContractHelper deployed at:" $ContractHelper

marketInitCodehash=$(seth call $ContractHelper "getMarketContractInitBytecodeHash()")
log "Market.sol init code hash" $marketInitCodehash


seth send $OracleMultiSig "addTxSetupOracle(bool,uint256,uint256,address,uint256,uint256,uint256,uint256)" true 10 10 $MemeToken 10 10 10 10 --gas 550000

# mint max meme tokens to user
seth send $MemeToken "mint(address,uint256)" $ETH_FROM $(seth --max-uint 256)
# give mmax allowance to market router
seth send $MemeToken "approve(address,uint256)" $MarketRouter $(seth --max-uint 256)

Identifier=$(seth --to-bytes32 0x0401030400040101040403020201030003000000010202020104010201000103)
Funding=$(seth --to-wei 1 eth)

estimate=$(seth estimate $MarketRouter "createMarket(address,address,bytes32,uint256)" $ETH_FROM $OracleMultiSig $Identifier $Funding)
seth send $MarketRouter "createMarket(address,address,bytes32,uint256)" $ETH_FROM $OracleMultiSig $Identifier $Funding --gas $estimate
log "MarketRouter:createMarket " $estimate

estimate=$(seth estimate $MarketRouter "buyExactTokensForMaxCTokens(uint256,uint256,uint256,address,address,bytes32)" $Funding $Funding $Funding $ETH_FROM $OracleMultiSig $Identifier)
log "MarketRouter:buyExactTokensForMaxCTokens " $estimate