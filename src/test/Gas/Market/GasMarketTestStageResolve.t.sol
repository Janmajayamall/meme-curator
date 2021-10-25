pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../../libraries/Math.sol";
import "./../../../OutcomeToken.sol";
import "./../../../MemeToken.sol";
import "./../../../OracleMultiSig.sol";
import "./../../../Market.sol";
import "./GasMarketTestShared.t.sol";

contract GasMarketTestStageResolve is GasMarketTestShared {
    
    function setUp() override public {
        commonSetup();

        // fund market & transition to stage MarketFunded 
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).fund();

        // expire market
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.expireBufferBlocks));

        // transition to Market Resolve
        for (uint256 index = 0; index < sharedOracleConfig.donEscalationLimit; index++) {
            MemeToken(memeToken).transfer(marketAddress, 2*10**18*(2**index));
            Market(marketAddress).stakeOutcome(0, address(this));
        }
    }

    function test_setOutcome() external {
        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
    }
}    
