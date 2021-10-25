pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../../libraries/Math.sol";
import "./../../../OutcomeToken.sol";
import "./../../../MemeToken.sol";
import "./../../../OracleMultiSig.sol";
import "./../../../Market.sol";
import "./GasMarketTestShared.t.sol";

contract GasMarketTestStageBuffer is GasMarketTestShared {
    
    function setUp() override public {
        commonSetup();

        // fund market & transition to stage MarketFunded 
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).fund();

        // expire market
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.expireBufferBlocks));
    }

    function test_stakeOutcome() external {
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).stakeOutcome(0, address(this));
    }

    function test_marketRouterStakeForOutcome() external {
        MarketRouter(marketRouter).stakeForOutcome(0, 10*10**18, marketAddress);
    }
}    
