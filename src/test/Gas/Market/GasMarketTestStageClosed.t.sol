pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../../libraries/Math.sol";
import "./../../../OutcomeToken.sol";
import "./../../../MemeToken.sol";
import "./../../../OracleMultiSig.sol";
import "./../../../Market.sol";
import "./GasMarketTestShared.t.sol";

contract GasMarketTestStageClosed is GasMarketTestShared {

    address token0;
    address token1;

    
    function setUp() override public {
        commonSetup();

        (, token0, token1) = Market(marketAddress).getTokenAddresses(); 

        // fund market & transition to stage MarketFunded 
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).fund();

        // buy outcome
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).buy(10*10**18, 10*10**18, address(this));

        // expire market
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.expireBufferBlocks));

        // stake outcome
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).stakeOutcome(0, address(this));

        // expire buffer period 
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.donBufferBlocks));


        // give max approval for outcome tokens to market router
        OutcomeToken(token0).approve(marketRouter, type(uint256).max);
        OutcomeToken(token1).approve(marketRouter, type(uint256).max);
    }

    /* 
    All tests below produce gas cost estimation in worst case, that is
    when outcome is set by expiry not by oracle. In other situations, such as
    outcome is set by oracle or user isn't the first caller gas consumption will
    be less.
    */

    function test_redeemStake() external {
        Market(marketAddress).redeemStake(0);
    }

    function test_redeemWinning() external {
        OutcomeToken(token0).transfer(marketAddress, 10*10**18);
        Market(marketAddress).redeemWinning(0, address(this));
    }

    function test_claimReserve() external {
        Market(marketAddress).claimReserve();
    }

    function test_marketRouterRedeemWinning() external {
        MarketRouter(marketRouter).redeemWinning(0, 10*10**18, marketAddress);
    }
}    
