#!/usr/bin/env bash

set -eo pipefail

# Deploy.
# MarketFactory=$(jq ".MarketFactory" out/addresses.json)
# MarketRouter=$(jq ".MarketRouter" out/addresses.json)
# OracleMultiSig=$(jq ".OracleMultiSig" out/addresses.json)
# MemeToken=$(jq ".MemeToken" out/addresses.json)
# ContractHelper=$(jq ".ContractHelper" out/addresses.json)
MarketFactory=0x36beE43e0548cfAa63e8094895b2Ede098e36B46
MarketRouter=0x8EfE5a96eaE05D72492d9A0296794adB0EF76d78
OracleMultiSig=0x2d102ED735c39F2060D9057056eC68e1430744de
MemeToken=0xB255efe9889D45277D3421e289E2E8A37Fe5b180
ContractHelper=0x8B4571514AB4d420Af057929654D89A4AFd70E7c
DEPLOYER=0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6


# # mint max meme tokens to user
estimate=$(seth estimate $MemeToken "mint(address,uint256)" $DEPLOYER $(seth --max-uint 256) )
seth send $MemeToken "mint(address,uint256)" $DEPLOYER $(seth --max-uint 256) --gas $estimate
# # give mmax allowance to market router & market factory
estimate=$(seth estimate $MemeToken "approve(address,uint256)" $MarketRouter $(seth --max-uint 256))
seth send $MemeToken "approve(address,uint256)" $MarketRouter $(seth --max-uint 256) --gas $estimate
# seth send $MemeToken "approve(address,uint256)" $MarketFactory $(seth --max-uint 256) --gas $estimate

# setup orcle configs
estimate=$(seth estimate $OracleMultiSig "addTxSetupOracle(address,bool,uint8,uint8,uint16,uint32,uint32,uint32)" $MemeToken true 1 10 5 500 100 100)
seth send $OracleMultiSig "addTxSetupOracle(address,bool,uint8,uint8,uint16,uint32,uint32,uint32)" $MemeToken true 1 10 5 500 100 100 --gas $estimate

# create new market
estimate=$(seth estimate $MarketRouter "createAndPlaceBetOnMarket(address,address,bytes32,uint256,uint256,uint256)" $DEPLOYER $OracleMultiSig $(seth --to-bytes32 $(seth --to-hex 11413)) $(seth --to-wei 1 eth) $(seth --to-wei 1 eth) 1)
seth send $MarketRouter "createAndPlaceBetOnMarket(address,address,bytes32,uint256,uint256,uint256)" $DEPLOYER $OracleMultiSig $(seth --to-bytes32 $(seth --to-hex 11413)) $(seth --to-wei 1 eth) $(seth --to-wei 1 eth) 1 --gas $estimate



# marketInitCodehash=$(seth call $ContractHelper "getMarketContractInitBytecodeHash()")
# echo "Market.sol init code hash" $marketInitCodehash

# seth send 0x08C7Eb16ACdc59D14A1eB11ed8Aa30992a66a44f "addTxSetupOracle(address,bool,uint8,uint8,uint16,uint32,uint32,uint32)" 0x0843E401ef6BD2ba14cE34f496b71c1168A61Ee3 true 1 10 5 100 100 100 --gas 5000000



# Identifier=$(seth --to-bytes32 0x0401030400040101040403020201030003000000010202020104010201000103)
# Funding=$(seth --to-wei 1 eth)

# estimate=$(seth estimate $MarketRouter "createMarket(address,address,bytes32,uint256)" $ETH_FROM $OracleMultiSig $Identifier $Funding)
# seth send $MarketRouter "createMarket(address,address,bytes32,uint256)" $ETH_FROM $OracleMultiSig $Identifier $Funding --gas $estimate
# log "MarketRouter:createMarket " $estimate

# estimate=$(seth estimate $MarketRouter "buyExactTokensForMaxCTokens(uint256,uint256,uint256,address,address,bytes32)" $Funding $Funding $(seth --to-wei 2 eth) $ETH_FROM $OracleMultiSig $Identifier)
# seth estimate 0x4789008BBa817d16904Dc4c9273e319c1625c331 "buyExactTokensForMaxCTokens(uint256,uint256,uint256,address)" $(seth --to-wei 1 eth) $(seth --to-wei 1 eth) $(seth --to-wei 2 eth) 0x931cff8b28356b29aa1f62f1df54d1c4879a7678           

# echo "MarketRouter:buyExactTokensForMaxCTokens " $estimate

# seth estimate 0xC774e1eD406307DC7F38A6b3FEdB0341FC9b124b "createMarket(address,address,bytes32,uint256)" 0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6 0x08C7Eb16ACdc59D14A1eB11ed8Aa30992a66a44f $(seth --to-bytes32 $(seth --to-hex 1213)) $(seth --to-wei 1 eth)
# seth call 0xC774e1eD406307DC7F38A6b3FEdB0341FC9b124b "getMarketAddress(address,address,bytes32)" 0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6 0x08C7Eb16ACdc59D14A1eB11ed8Aa30992a66a44f $(seth --to-bytes32 $(seth --to-hex 1213))
# seth send 0x5F2E80E35F64157e769F38392953b60461e5BbAb "createMarket(address,address,bytes32)" 0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6 0x08C7Eb16ACdc59D14A1eB11ed8Aa30992a66a44f $(seth --to-bytes32 $(seth --to-hex 1213))


# seth send 0xD4D664D419A6A845C98Cc366ae1c4b24592BD5CE "createMarket(address,address,bytes32,uint256)" 0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6 0x62862436A93B538b7820E0F24E0b6F9e3f9C027d $(seth --to-bytes32 $(seth --to-hex 13121311300)) $(seth --to-wei 1 eth) --gas 4369223

# seth estimate 0xFB626449A112C95FECF7829deeA9445C9ECC7e56 "transfer(address,uint256)" 0x931cff8b28356b29aa1f62f1df54d1c4879a7678 $(seth --to-wei 1 eth)

# seth send 0x4789008BBa817d16904Dc4c9273e319c1625c331 "buyExactTokensForMaxCTokens(uint256,uint256,uint256,address)" $(seth --to-wei 1 eth) $(seth --to-wei 1 eth) $(seth --to-wei 1.1 eth) 0x95affa24b28122797b83a411fdc0fcff75a66f19


# seth send 0xFB626449A112C95FECF7829deeA9445C9ECC7e56 "approve(address,uint256)" 0xD2Ac5854F87e2aF6c0c2dEc8f31B4588A5093131 $(seth --max-uint 256) --gas 124841

# 1. Start working on backend for posting memes & retreiving memes
# APIs that are needed 
# a. Post meme (should not allow posting meme, if the request does not contains valid values relating to creation of prediction tx)
# b. Get feed of memes -
#     ~ Will return a list of memes in a category (probably Meme data & prediction market id)
#     ~ Probably on the front end - retrieve the list of memes from back end & superimpose them with data of perdiction markets
# c. Handle normal updates to meme data (for ex. likes & dislikes)
