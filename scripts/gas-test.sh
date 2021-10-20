#!/usr/bin/env bash

set -eo pipefail

# Deploy.
# MarketFactory=$(jq ".MarketFactory" out/addresses.json)
# MarketRouter=$(jq ".MarketRouter" out/addresses.json)
# OracleMultiSig=$(jq ".OracleMultiSig" out/addresses.json)
# MemeToken=$(jq ".MemeToken" out/addresses.json)
# ContractHelper=$(jq ".ContractHelper" out/addresses.json)
MarketFactory=0x4e7bb8F7b77f4a9b46C2De0b5bC57305De7479E8
MarketRouter=0x6e18F870bd33762294a27b286Fd14370E95cD948
OracleMultiSig=0x921dE3337037f22927C325c1b3f9eaE34F35C558
MemeToken=0xc9CA30098b21979a3eD630979365F1665d42980e
ContractHelper=0x558F5BC7f7A15850Be5b08ea20DfbA5Ac26a8847

echo "MarketFactory at:" $MarketFactory
echo  "MarketRouter at:" $MarketRouter
echo  "OracleMultiSig at:" $OracleMultiSig
echo  "MemeToken at:" $MemeToken
echo  "ContractHelper at:" $ContractHelper

marketInitCodehash=$(seth call $ContractHelper "getMarketContractInitBytecodeHash()")
echo "Market.sol init code hash" $marketInitCodehash

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

estimate=$(seth estimate $MarketRouter "buyExactTokensForMaxCTokens(uint256,uint256,uint256,address,address,bytes32)" $Funding $Funding $(seth --to-wei 2 eth) $ETH_FROM $OracleMultiSig $Identifier)
echo "MarketRouter:buyExactTokensForMaxCTokens " $estimate
